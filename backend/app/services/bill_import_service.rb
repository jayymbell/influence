# Service for proxying calls to the Open States API v3 and the MN Revisor website.
#
# All HTTP calls are made server-side so the API key is never
# exposed to the frontend.
#
# Usage:
#   BillImportService.search(query: "HF 100")
#   BillImportService.import(external_id: "ocd-bill/...", created_by: user)
#   BillImportService.refresh(bill: bill)
#   BillImportService.link(bill: bill, external_id: "ocd-bill/...")
class BillImportService
  OPEN_STATES_BASE_URL = "https://v3.openstates.org"
  REVISOR_BASE_URL     = "https://www.revisor.mn.gov"
  JURISDICTION         = "mn"

  API_KEY = (Rails.application.credentials.dig(:open_states_api_key) ||
             ENV["OPEN_STATES_API_KEY"]).freeze

  class ExternalError < StandardError; end

  # Search Minnesota bills on Open States.
  #
  # @param query [String] keyword search string
  # @param page [Integer]
  # @param per_page [Integer]
  # @return [Hash] { results: Array<Hash>, total:, page:, per_page: }
  def self.search(query:, page: 1, per_page: 20)
    data = http_get("/bills", {
      jurisdiction: JURISDICTION,
      q:            query,
      page:         page,
      per_page:     per_page
    })

    raw_results = data["results"] || []
    external_ids = raw_results.map { |r| r["id"] }.compact
    already_imported_ids = Bill.where(external_id: external_ids).pluck(:external_id).to_set

    results = raw_results.map { |r| normalize_search_result(r, already_imported_ids) }

    {
      results:   results,
      total:     data["pagination"]&.dig("total_items") || results.size,
      page:      page,
      per_page:  per_page
    }
  end

  # Fetch a single bill from Open States by its id.
  #
  # @param external_id [String] Open States bill id (e.g. "ocd-bill/...")
  # @return [Hash] normalized bill attributes
  def self.fetch(external_id:)
    # Open States single-bill detail endpoint accepts the id directly
    data = http_get("/bills/#{CGI.escape(external_id)}", { include: "abstracts" })
    normalize_bill(data)
  end

  # Import a bill from Open States, creating a local Bill record.
  # Idempotent: returns the existing record if external_id is already present.
  #
  # @param external_id [String]
  # @param created_by [User]
  # @return [Array<Bill, Symbol>] [bill, :created | :existing]
  def self.import(external_id:, created_by:)
    existing = Bill.find_by(external_id: external_id)
    return [ existing, :existing ] if existing

    attrs = fetch(external_id: external_id)
    bill  = Bill.new(
      external_id:    external_id,
      bill_number:    attrs[:bill_number],
      title:          attrs[:title],
      description:    attrs[:description],
      chamber:        attrs[:chamber],
      session_year:   attrs[:session_year],
      source_url:     attrs[:source_url],
      last_synced_at: Time.current,
      status:         :introduced,
      created_by:     created_by,
      updated_by:     created_by
    )

    unless bill.save
      raise ExternalError, "Could not save imported bill: #{bill.errors.full_messages.join(', ')}"
    end

    [ bill, :created ]
  end

  # Refresh a locally imported bill from Open States.
  # Only mapped fields are overwritten; user-managed fields are preserved.
  #
  # @param bill [Bill] must have external_id set
  # @raise [ExternalError] if bill has no external_id
  def self.refresh(bill:)
    raise ExternalError, "Bill is not linked to an external record" if bill.external_id.blank?

    attrs = fetch(external_id: bill.external_id)
    bill.assign_attributes(
      bill_number:    attrs[:bill_number],
      title:          attrs[:title],
      description:    attrs[:description],
      chamber:        attrs[:chamber],
      session_year:   attrs[:session_year],
      source_url:     attrs[:source_url],
      last_synced_at: Time.current
    )

    unless bill.save
      raise ExternalError, "Could not save refreshed bill: #{bill.errors.full_messages.join(', ')}"
    end

    bill
  end

  # Link a manually created bill to an Open States record.
  #
  # @param bill [Bill]
  # @param external_id [String]
  # @raise [ExternalError] if external_id is already used by another local bill
  def self.link(bill:, external_id:)
    conflict = Bill.where(external_id: external_id).where.not(id: bill.id).first
    if conflict
      raise ExternalError, "This Open States record is already linked to another bill"
    end

    attrs = fetch(external_id: external_id)
    bill.assign_attributes(
      external_id:    external_id,
      source_url:     attrs[:source_url],
      last_synced_at: Time.current
    )

    unless bill.save
      raise ExternalError, "Could not link bill: #{bill.errors.full_messages.join(', ')}"
    end

    bill
  end

  # ---------------------------------------------------------------------------
  private
  # ---------------------------------------------------------------------------

  def self.http_get(path, params = {})
    raise ExternalError, "Open States API key is not configured" if API_KEY.blank?

    uri = URI("#{OPEN_STATES_BASE_URL}#{path}")
    uri.query = URI.encode_www_form(params.reject { |_, v| v.nil? })

    http           = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl   = uri.scheme == "https"
    http.open_timeout = 10
    http.read_timeout = 10

    request = Net::HTTP::Get.new(uri)
    request["X-API-KEY"]    = API_KEY
    request["Accept"]       = "application/json"

    Rails.logger.info "[BillImportService] GET #{uri}"
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    response = http.request(request)
    elapsed  = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start).round(3)
    Rails.logger.info "[BillImportService] #{response.code} (#{elapsed}s)"

    unless response.is_a?(Net::HTTPSuccess)
      raise ExternalError, "Open States returned #{response.code}"
    end

    JSON.parse(response.body)
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    raise ExternalError, "Open States request timed out: #{e.message}"
  rescue Errno::ECONNREFUSED, SocketError => e
    raise ExternalError, "Could not reach Open States: #{e.message}"
  rescue JSON::ParserError => e
    raise ExternalError, "Invalid response from Open States: #{e.message}"
  end

  def self.normalize_search_result(raw, already_imported_ids)
    {
      external_id:      raw["id"],
      bill_number:      raw["identifier"],
      title:            raw["title"]&.slice(0, 500),
      chamber:          map_chamber(raw.dig("from_organization", "classification")),
      session_year:     extract_year(raw["session"]),
      source_url:       raw["openstates_url"],
      already_imported: already_imported_ids.include?(raw["id"])
    }
  end

  def self.normalize_bill(raw)
    description = raw["abstracts"]&.first&.dig("abstract").presence ||
                  scrape_revisor_description(raw["identifier"], raw["session"])

    {
      external_id:  raw["id"],
      bill_number:  raw["identifier"],
      title:        raw["title"]&.slice(0, 500),
      description:  description,
      chamber:      map_chamber(raw.dig("from_organization", "classification")),
      session_year: extract_year(raw["session"]),
      source_url:   raw["openstates_url"]
    }
  end

  def self.map_chamber(classification)
    case classification&.downcase
    when "lower" then "house"
    when "upper" then "senate"
    end
  end

  def self.extract_year(session_identifier)
    return nil if session_identifier.blank?
    match = session_identifier.match(/(\d{4})/)
    match ? match[1].to_i : nil
  end

  # Scrape the MN Revisor of Statutes bill page to get the Description text.
  # Returns nil silently on any failure so a scrape error never breaks import.
  #
  # URL format: /bills/{legislature}/{start_year}/0/{CHAMBER}/{number}/?body={body}
  # e.g. /bills/94/2025/0/SF/5092/?body=senate
  def self.scrape_revisor_description(identifier, session)
    return nil if identifier.blank? || session.blank?

    # Parse identifier: "SF 5092" -> type="SF", number="5092"
    match = identifier.strip.match(/\A([A-Z]+)\s*(\d+)\z/i)
    return nil unless match

    bill_type   = match[1].upcase   # "SF" or "HF"
    bill_number = match[2]          # "5092"

    # Derive the URL year and legislature from the session string.
    # Open States may return "2026" (single end-year) or "2025-2026" (range).
    # The Revisor URL uses the year the bill was introduced; using the last
    # year of the session works for both halves of the session.
    # The legislature formula requires the ODD start year, so even years get -1.
    parts      = session.split("-")
    url_year   = parts.last.to_i
    return nil if url_year.zero?
    odd_year   = url_year.odd? ? url_year : url_year - 1
    legislature = 94 - ((2025 - odd_year) / 2)

    body = bill_type.start_with?("SF") ? "senate" : "house"
    path = "/bills/#{legislature}/#{url_year}/0/#{bill_type}/#{bill_number}/?body=#{body}"

    uri = URI("#{REVISOR_BASE_URL}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl   = true
    http.open_timeout = 8
    http.read_timeout = 8

    request = Net::HTTP::Get.new(uri)
    request["User-Agent"] = "Mozilla/5.0 (compatible; Rails)"
    request["Accept"]     = "text/html"

    Rails.logger.info "[BillImportService] Revisor scrape GET #{uri}"
    response = http.request(request)
    return nil unless response.is_a?(Net::HTTPSuccess)

    doc  = Nokogiri::HTML(response.body)
    h    = doc.css("h2, h3").find { |node| node.text.strip == "Description" }
    return nil unless h

    sib = h.next_sibling
    sib = sib.next_sibling while sib && sib.text.strip.empty?
    text = sib&.text&.strip.presence
    text
  rescue StandardError => e
    Rails.logger.warn "[BillImportService] Revisor scrape failed for #{identifier}: #{e.message}"
    nil
  end
end
