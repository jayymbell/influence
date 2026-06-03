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
#   BillImportService.scrape_authors(bill: bill, created_by: user)
class BillImportService
  OPEN_STATES_BASE_URL = "https://v3.openstates.org"
  REVISOR_BASE_URL     = "https://www.revisor.mn.gov"
  JURISDICTION         = "mn"

  API_KEY = (Rails.application.credentials.dig(:open_states_api_key) ||
             ENV["OPEN_STATES_API_KEY"]).freeze

  # Maps Open States action classification strings to a priority and local status.
  # Higher priority wins when multiple actions are present.
  ACTION_CLASSIFICATION_PRIORITY = {
    "became-law"          => 11,
    "executive-signature" => 10,
    "executive-veto"      =>  9,
    "failure"             =>  8,
    "committee-failure"   =>  8,
    "passage"             =>  7,
    "reading-3"           =>  6,
    "reading-2"           =>  5,
    "committee-passage"   =>  4,
    "referral-committee"  =>  2,
    "introduced"          =>  1
  }.freeze

  ACTION_CLASSIFICATION_STATUS = {
    "became-law"          => :signed,
    "executive-signature" => :signed,
    "executive-veto"      => :vetoed,
    "failure"             => :failed,
    "committee-failure"   => :failed,
    "passage"             => :passed_chamber,
    "reading-3"           => :floor_vote,
    "reading-2"           => :floor_vote,
    "committee-passage"   => :passed_committee,
    "referral-committee"  => :in_committee,
    "introduced"          => :introduced
  }.freeze

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
    data = http_get("/bills/#{CGI.escape(external_id)}", { include: %w[abstracts actions] })
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
      status:         attrs[:status],
      created_by:     created_by,
      updated_by:     created_by
    )

    unless bill.save
      raise ExternalError, "Could not save imported bill: #{bill.errors.full_messages.join(', ')}"
    end

    sync_actions(bill: bill, raw_actions: attrs[:raw_actions])
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
      status:         attrs[:status],
      last_synced_at: Time.current
    )

    unless bill.save
      raise ExternalError, "Could not save refreshed bill: #{bill.errors.full_messages.join(', ')}"
    end

    sync_actions(bill: bill, raw_actions: attrs[:raw_actions])
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

  # Sync bill actions from an Open States raw actions array.
  # Replaces all existing BillAction records for the bill with the current set.
  #
  # @param bill [Bill]
  # @param raw_actions [Array<Hash>]
  def self.sync_actions(bill:, raw_actions:)
    return if raw_actions.blank?

    rows = raw_actions.each_with_index.map do |action, idx|
      next if action["date"].blank? || action["description"].blank?

      {
        bill_id:       bill.id,
        action_date:   Date.parse(action["date"]),
        description:   action["description"].strip,
        classification: Array(action["classification"]).reject(&:blank?),
        action_order:  idx,
        created_at:    Time.current,
        updated_at:    Time.current
      }
    end.compact

    return if rows.empty?

    BillAction.transaction do
      BillAction.where(bill_id: bill.id).delete_all
      BillAction.insert_all(rows)
    end
  end

  # Scrape the MN Revisor bill page for authors, follow each author bio link,
  # find-or-create a Person record, and link them to the bill.
  # Never removes existing BillPerson records.
  #
  # @param bill [Bill]
  # @param created_by [User]
  # @return [Hash] { added: Array<Person>, skipped: Array<Person>, errors: Array<String> }
  def self.scrape_authors(bill:, created_by:)
    raise ExternalError, "Bill has no bill_number or session_year to build Revisor URL" \
      if bill.bill_number.blank? || bill.session_year.blank?

    revisor_url = build_revisor_url(bill.bill_number, bill.session_year.to_s, bill.chamber)
    raise ExternalError, "Cannot build Revisor URL for this bill" unless revisor_url

    html = http_get_html(revisor_url)
    doc  = Nokogiri::HTML(html)

    # Find the Authors h2, then collect all <a> links in the following .author div
    author_links = []
    h = doc.css("h2").find { |n| n.text.strip.start_with?("Authors") }
    if h
      sib = h.next_sibling
      sib = sib.next_sibling while sib && sib.text.strip.empty?
      author_links = sib&.css("a")&.map { |a| a["href"] } || []
    end

    raise ExternalError, "No authors found on Revisor page" if author_links.empty?

    added   = []
    skipped = []
    errors  = []

    author_links.each do |bio_url|
      bio_info = scrape_legislator_bio(bio_url)
      next errors << "Could not scrape bio at #{bio_url}" unless bio_info

      person = find_or_create_person(bio_info, created_by)
      if BillPerson.exists?(bill_id: bill.id, person_id: person.id)
        skipped << person
      else
        BillPerson.create!(bill: bill, person: person, added_by: created_by)
        added << person
      end
    rescue StandardError => e
      errors << "#{bio_url}: #{e.message}"
    end

    { added: added, skipped: skipped, errors: errors }
  end

  # ---------------------------------------------------------------------------
  private
  # ---------------------------------------------------------------------------

  def self.http_get(path, params = {})
    raise ExternalError, "Open States API key is not configured" if API_KEY.blank?

    uri = URI("#{OPEN_STATES_BASE_URL}#{path}")
    pairs = params.reject { |_, v| v.nil? }.flat_map { |k, v| Array(v).map { |val| [k, val] } }
    uri.query = URI.encode_www_form(pairs)

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
      source_url:   raw["openstates_url"],
      status:       map_status(raw["actions"] || []),
      raw_actions:  raw["actions"] || []
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

  # Derive the most advanced local status from an Open States actions array.
  def self.map_status(actions)
    return :introduced if actions.blank?

    best_priority = 0
    best_status   = :introduced

    actions.each do |action|
      (action["classification"] || []).each do |cls|
        priority = ACTION_CLASSIFICATION_PRIORITY[cls]
        next unless priority && priority > best_priority
        best_priority = priority
        best_status   = ACTION_CLASSIFICATION_STATUS[cls]
      end
    end

    best_status
  end

  # Build the MN Revisor bill URL. Returns nil if the identifier can't be parsed.
  def self.build_revisor_url(identifier, session, chamber = nil)
    match = identifier.to_s.strip.match(/\A([A-Z]+)\s*(\d+)\z/i)
    return nil unless match

    bill_type   = match[1].upcase
    bill_number = match[2]
    parts      = session.to_s.split("-")
    url_year   = parts.last.to_i
    return nil if url_year.zero?

    odd_year    = url_year.odd? ? url_year : url_year - 1
    legislature = 94 - ((2025 - odd_year) / 2)
    body = (chamber.to_s == "senate" || bill_type.start_with?("SF")) ? "senate" : "house"
    "#{REVISOR_BASE_URL}/bills/#{legislature}/#{url_year}/0/#{bill_type}/#{bill_number}/?body=#{body}"
  end

  # Scrape a MN legislator bio page (senate.mn or house.mn.gov) and return
  # { first_name:, last_name:, display_name:, title:, phone:, email: } or nil on failure.
  def self.scrape_legislator_bio(url)
    return nil if url.blank?

    html = http_get_html(url)
    doc  = Nokogiri::HTML(html)

    # Both senate and house pages put the full name in an <h1> tag,
    # e.g. "Rep. Jim Joy" or "Senator Jeff R. Howe (13, R)".
    # The senate page has an empty <h1> for the logo area — skip blank ones.
    raw_name = doc.css("h1").map { |n| n.text.strip }.find(&:present?)
    return nil if raw_name.blank?

    # Extract district number before stripping parentheticals
    # Senate: "Senator Jeff R. Howe (13, R)"  → "13" (district in h1)
    # House:  "Rep. Jim Joy" + span "(R) District: 04B" → "04B" (district in span)
    district = raw_name.match(/District:\s*([\w]+)/i)&.captures&.first ||
               raw_name.match(/\((\d+[A-Z]?),/i)&.captures&.first ||
               doc.css("span").map { |n| n.text.strip }
                  .find { |t| t.match?(/District:/i) }
                  &.then { |t| t.match(/District:\s*([\w]+)/i)&.captures&.first }

    # Strip trailing district/party "(13, R)" or "(R) District: 04B" fragments
    clean = raw_name.gsub(/\s*\(.*\z/, "").gsub(/\s*District:.*\z/i, "").strip

    # Strip honorific prefix: Rep., Senator, Representative, Sen.
    honorific = clean.match(/\A(Rep\.|Senator|Representative|Sen\.)\s+/i)
    title     = honorific ? honorific[1] : nil
    name_part = honorific ? clean.sub(honorific[0], "").strip : clean

    # Parse "First [Middle] Last" — use first & last word
    parts      = name_part.split
    first_name = parts.first
    last_name  = parts.last
    return nil if first_name.blank? || last_name.blank?

    display_name = "#{first_name} #{last_name}"

    # Build organization_name from chamber + district
    chamber_label = case title&.downcase
                    when "senator"                  then "MN Senate"
                    when "rep.", "representative"    then "MN House"
                    end
    organization_name = district.present? ? "#{chamber_label} District #{district}" : chamber_label

    # Phone: first 10-digit number on the page
    phone = doc.text.scan(/\(?\d{3}\)?[-.\s]\d{3}[-.\s]\d{4}/).first&.strip

    # Email: a mailto: link that isn't a general office address
    email_link = doc.css("a[href^='mailto:']")
                    .map { |a| a["href"].sub("mailto:", "").strip }
                    .reject { |e| e =~ /webmaster|information@|comments/i }
                    .first

    { first_name: first_name, last_name: last_name, display_name: display_name,
      title: title, organization_name: organization_name, phone: phone, email: email_link }
  rescue StandardError => e
    Rails.logger.warn "[BillImportService] Bio scrape failed for #{url}: #{e.message}"
    nil
  end

  # Find an existing Person by first+last name (case-insensitive) or create one.
  def self.find_or_create_person(bio, created_by)
    person = Person.kept
                   .where("lower(first_name) = ? AND lower(last_name) = ?",
                          bio[:first_name].downcase, bio[:last_name].downcase)
                   .first

    return person if person

    Person.create!(
      first_name:        bio[:first_name],
      last_name:         bio[:last_name],
      display_name:      bio[:display_name],
      title:             bio[:title],
      organization_name: bio[:organization_name],
      phone:             bio[:phone],
      email:             bio[:email],
      created_by:        created_by,
      updated_by:        created_by
    )
  end

  # Perform an HTTP GET and return the response body as a string.
  # Follows up to 5 redirects. Raises ExternalError on non-2xx or network failure.
  def self.http_get_html(url, redirect_limit = 5)
    raise ExternalError, "Too many redirects fetching #{url}" if redirect_limit.zero?

    uri  = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl      = (uri.scheme == "https")
    http.open_timeout = 8
    http.read_timeout = 8

    request = Net::HTTP::Get.new(uri)
    request["User-Agent"] = "Mozilla/5.0 (compatible; Rails)"
    request["Accept"]     = "text/html"

    Rails.logger.info "[BillImportService] HTML GET #{uri}"
    response = http.request(request)

    case response
    when Net::HTTPSuccess
      response.body
    when Net::HTTPRedirection
      location = response["Location"]
      raise ExternalError, "Redirect with no Location from #{uri}" if location.blank?
      new_uri = URI.join(uri, location)
      Rails.logger.info "[BillImportService] Redirect → #{new_uri}"
      http_get_html(new_uri.to_s, redirect_limit - 1)
    else
      raise ExternalError, "Unexpected response #{response.code} from #{uri}"
    end
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    raise ExternalError, "Request timed out: #{e.message}"
  rescue Errno::ECONNREFUSED, SocketError => e
    raise ExternalError, "Could not connect: #{e.message}"
  end

  # Scrape the MN Revisor of Statutes bill page to get the Description text.
  # Returns nil silently on any failure so a scrape error never breaks import.
  def self.scrape_revisor_description(identifier, session)
    return nil if identifier.blank? || session.blank?

    url = build_revisor_url(identifier, session)
    return nil unless url

    html = http_get_html(url)
    doc  = Nokogiri::HTML(html)
    h    = doc.css("h2, h3").find { |node| node.text.strip == "Description" }
    return nil unless h

    sib = h.next_sibling
    sib = sib.next_sibling while sib && sib.text.strip.empty?
    sib&.text&.strip.presence
  rescue StandardError => e
    Rails.logger.warn "[BillImportService] Revisor scrape failed for #{identifier}: #{e.message}"
    nil
  end
end
