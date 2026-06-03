require 'rails_helper'

RSpec.describe BillImportService do
  # Stub the API key so tests never need a real key
  before do
    stub_const("BillImportService::API_KEY", "test-api-key")
  end

  let(:base_url)     { "https://v3.openstates.org" }
  let(:revisor_base) { "https://www.revisor.mn.gov" }

  REVISOR_HTML_WITH_DESC = <<~HTML
    <html><body>
      <h2>Description</h2>
      <p>This is the Revisor description.</p>
    </body></html>
  HTML

  REVISOR_HTML_NO_DESC = <<~HTML
    <html><body><h2>Actions</h2><p>Referred to committee.</p></body></html>
  HTML

  def stub_revisor(identifier: "HF 100", session: "2025-2026", body: REVISOR_HTML_WITH_DESC, status: 200)
    stub_request(:get, /revisor\.mn\.gov\/bills/)
      .to_return(status: status, body: body, headers: { "Content-Type" => "text/html" })
  end

  def stub_open_states_search(query:, status: 200, body: nil)
    body ||= {
      "results" => [
        {
          "id"            => "ocd-bill/1",
          "identifier"    => "HF 100",
          "title"         => "A test bill",
          "openstates_url" => "https://openstates.org/mn/bills/2026/HF100/",
          "session"    => "2026",
          "from_organization" => { "classification" => "lower" }
        },
        {
          "id"            => "ocd-bill/2",
          "identifier"    => "SF 200",
          "title"         => "Another bill",
          "openstates_url" => "https://openstates.org/mn/bills/2026/SF200/",
          "session"    => "2025-2026",
          "from_organization" => { "classification" => "upper" }
        }
      ],
      "pagination" => { "total_items" => 2 }
    }
    stub_request(:get, "#{base_url}/bills")
      .with(query: hash_including("jurisdiction" => "mn", "q" => query))
      .to_return(status: status, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  def stub_open_states_fetch(external_id:, status: 200, body: nil)
    body ||= {
      "id"            => external_id,
      "identifier"    => "HF 100",
      "title"         => "A test bill",
      "openstates_url" => "https://openstates.org/mn/bills/2026/HF100/",
      "session"    => "2026",
      "from_organization" => { "classification" => "lower" },
      "subject"    => ["Education", "Finance"],
      "abstracts" => [ { "abstract" => "This bill does something important.", "note" => "summary" } ],
      "actions"   => []
    }
    escaped = CGI.escape(external_id)
    stub_request(:get, Regexp.new("v3\\.openstates\\.org/bills/#{Regexp.escape(escaped)}"))
      .to_return(status: status, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  # -------------------------------------------------------------------------
  describe ".search" do
    it "returns normalized results with already_imported flag" do
      create(:bill, external_id: "ocd-bill/1")
      stub_open_states_search(query: "test")

      result = BillImportService.search(query: "test")

      expect(result[:results].length).to eq 2
      first = result[:results].find { |r| r[:external_id] == "ocd-bill/1" }
      second = result[:results].find { |r| r[:external_id] == "ocd-bill/2" }

      expect(first[:already_imported]).to be true
      expect(second[:already_imported]).to be false
    end

    it "maps chamber lower→house and upper→senate" do
      stub_open_states_search(query: "test")
      results = BillImportService.search(query: "test")[:results]

      house_result  = results.find { |r| r[:external_id] == "ocd-bill/1" }
      senate_result = results.find { |r| r[:external_id] == "ocd-bill/2" }

      expect(house_result[:chamber]).to eq "house"
      expect(senate_result[:chamber]).to eq "senate"
    end

    it "extracts 4-digit session year from session identifier" do
      stub_open_states_search(query: "test")
      results = BillImportService.search(query: "test")[:results]
      expect(results[0][:session_year]).to eq 2026
      expect(results[1][:session_year]).to eq 2025
    end

    it "includes total from pagination" do
      stub_open_states_search(query: "test")
      result = BillImportService.search(query: "test")
      expect(result[:total]).to eq 2
    end

    it "raises ExternalError on non-200 response" do
      stub_open_states_search(query: "bad", status: 500)
      expect {
        BillImportService.search(query: "bad")
      }.to raise_error(BillImportService::ExternalError, /500/)
    end

    it "raises ExternalError on timeout" do
      stub_request(:get, /v3\.openstates\.org\/bills/).to_timeout
      expect {
        BillImportService.search(query: "timeout")
      }.to raise_error(BillImportService::ExternalError, /timed out/i)
    end
  end

  # -------------------------------------------------------------------------
  describe ".fetch" do
    it "returns normalized bill attributes" do
      stub_open_states_fetch(external_id: "ocd-bill/1")
      attrs = BillImportService.fetch(external_id: "ocd-bill/1")

      expect(attrs[:bill_number]).to eq "HF 100"
      expect(attrs[:title]).to eq "A test bill"
      expect(attrs[:description]).to eq "This bill does something important."
      expect(attrs[:chamber]).to eq "house"
      expect(attrs[:session_year]).to eq 2026
      expect(attrs[:source_url]).to include("openstates.org")
    end

    it "falls back to Revisor scraper when abstracts is empty" do
      stub_revisor
      stub_open_states_fetch(
        external_id: "ocd-bill/1",
        body: {
          "id"             => "ocd-bill/1",
          "identifier"     => "HF 100",
          "title"          => "A test bill",
          "openstates_url" => "https://openstates.org/mn/bills/2026/HF100/",
          "from_organization" => { "classification" => "lower" },
          "session"        => "2026",
          "subject"        => ["Environment", "Commerce"],
          "abstracts"      => []
        }
      )
      attrs = BillImportService.fetch(external_id: "ocd-bill/1")
      expect(attrs[:description]).to eq "This is the Revisor description."
    end

    it "sets description to nil when abstracts is empty and Revisor scrape also fails" do
      stub_revisor(status: 500)
      stub_open_states_fetch(
        external_id: "ocd-bill/1",
        body: {
          "id"             => "ocd-bill/1",
          "identifier"     => "HF 100",
          "title"          => "A test bill",
          "openstates_url" => "https://openstates.org/mn/bills/2026/HF100/",
          "from_organization" => { "classification" => "lower" },
          "session"        => "2026",
          "subject"        => [],
          "abstracts"      => []
        }
      )
      attrs = BillImportService.fetch(external_id: "ocd-bill/1")
      expect(attrs[:description]).to be_nil
    end

    it "raises ExternalError on 404" do
      stub_open_states_fetch(external_id: "ocd-bill/missing", status: 404)
      expect {
        BillImportService.fetch(external_id: "ocd-bill/missing")
      }.to raise_error(BillImportService::ExternalError, /404/)
    end
  end

  # -------------------------------------------------------------------------
  describe ".import" do
    let(:user) { create(:user, :admin) }

    it "creates a new local Bill from Open States data" do
      stub_open_states_fetch(external_id: "ocd-bill/1")

      bill, status_sym = BillImportService.import(external_id: "ocd-bill/1", created_by: user)

      expect(status_sym).to eq :created
      expect(bill).to be_persisted
      expect(bill.external_id).to eq "ocd-bill/1"
      expect(bill.bill_number).to eq "HF 100"
      expect(bill.title).to eq "A test bill"
      expect(bill.description).to eq "This bill does something important."
      expect(bill.chamber).to eq "house"
      expect(bill.session_year).to eq 2026
      expect(bill.status).to eq "introduced"
      expect(bill.last_synced_at).not_to be_nil
      expect(bill.created_by).to eq user
    end

    it "returns existing bill without calling Open States if external_id already exists" do
      existing = create(:bill, external_id: "ocd-bill/1")

      bill, status_sym = BillImportService.import(external_id: "ocd-bill/1", created_by: user)

      expect(status_sym).to eq :existing
      expect(bill.id).to eq existing.id
      expect(WebMock).not_to have_requested(:get, /openstates/)
    end

    it "does not overwrite notes or tags on import" do
      stub_open_states_fetch(external_id: "ocd-bill/new")

      bill, _ = BillImportService.import(external_id: "ocd-bill/new", created_by: user)

      expect(bill.notes).to be_nil
      expect(bill.tags).to eq []
    end

    it "syncs actions on import" do
      stub_open_states_fetch(
        external_id: "ocd-bill/1",
        body: {
          "id"            => "ocd-bill/1",
          "identifier"    => "HF 100",
          "title"         => "A test bill",
          "openstates_url" => "https://openstates.org/mn/bills/2026/HF100/",
          "session"    => "2026",
          "from_organization" => { "classification" => "lower" },
          "abstracts" => [ { "abstract" => "Summary.", "note" => "summary" } ],
          "actions"   => [
            { "date" => "2026-01-10", "description" => "Introduced in House", "classification" => ["introduced"] }
          ]
        }
      )

      bill, _ = BillImportService.import(external_id: "ocd-bill/1", created_by: user)
      expect(bill.bill_actions.count).to eq 1
      expect(bill.bill_actions.first.description).to eq "Introduced in House"
    end
  end

  # -------------------------------------------------------------------------
  describe ".refresh" do
    let(:bill) { create(:bill, external_id: "ocd-bill/1", description: "old description", notes: "kept", tags: ["kept"], status: :signed) }

    it "updates mapped fields from Open States" do
      stub_open_states_fetch(
        external_id: "ocd-bill/1",
        body: {
          "id"            => "ocd-bill/1",
          "identifier"    => "HF 101",
          "title"         => "Updated Title",
          "openstates_url" => "https://openstates.org/mn/bills/2026/HF101/",
          "session"    => "2026",
          "from_organization" => { "classification" => "upper" },
          "subject"    => ["Education"],
          "abstracts" => [ { "abstract" => "Refreshed description.", "note" => "summary" } ],
          "actions"   => []
        }
      )

      refreshed = BillImportService.refresh(bill: bill)

      expect(refreshed.bill_number).to eq "HF 101"
      expect(refreshed.title).to eq "Updated Title"
      expect(refreshed.description).to eq "Refreshed description."
      expect(refreshed.chamber).to eq "senate"
      expect(refreshed.last_synced_at).not_to be_nil
    end

    it "updates status from Open States actions" do
      stub_open_states_fetch(
        external_id: "ocd-bill/1",
        body: {
          "id"            => "ocd-bill/1",
          "identifier"    => "HF 100",
          "title"         => "A test bill",
          "openstates_url" => "https://openstates.org/mn/bills/2026/HF100/",
          "session"    => "2026",
          "from_organization" => { "classification" => "lower" },
          "abstracts" => [],
          "actions"   => [
            { "date" => "2026-01-10", "description" => "Introduced",        "classification" => ["introduced"] },
            { "date" => "2026-01-20", "description" => "Referred",          "classification" => ["referral-committee"] },
            { "date" => "2026-02-01", "description" => "Passed committee",  "classification" => ["committee-passage"] },
            { "date" => "2026-03-01", "description" => "Signed by Governor", "classification" => ["executive-signature"] }
          ]
        }
      )
      stub_revisor(status: 500)

      refreshed = BillImportService.refresh(bill: bill)
      expect(refreshed.status).to eq "signed"
    end

    it "does NOT overwrite notes, tags, or companion_bill_id" do
      stub_open_states_fetch(external_id: "ocd-bill/1")

      refreshed = BillImportService.refresh(bill: bill)

      expect(refreshed.notes).to eq "kept"
      expect(refreshed.tags).to eq ["kept"]
    end

    it "raises ExternalError if bill has no external_id" do
      unlinked_bill = create(:bill)
      expect {
        BillImportService.refresh(bill: unlinked_bill)
      }.to raise_error(BillImportService::ExternalError, /not linked/)
    end
  end

  # -------------------------------------------------------------------------
  describe ".link" do
    let(:bill) { create(:bill) }
    let(:user) { create(:user, :admin) }

    it "sets external_id, source_url, and last_synced_at on the bill" do
      stub_open_states_fetch(external_id: "ocd-bill/1")

      linked = BillImportService.link(bill: bill, external_id: "ocd-bill/1")

      expect(linked.external_id).to eq "ocd-bill/1"
      expect(linked.source_url).to include("openstates.org")
      expect(linked.last_synced_at).not_to be_nil
    end

    it "raises ExternalError if the external_id is already used by another bill" do
      other = create(:bill, external_id: "ocd-bill/1")

      expect {
        BillImportService.link(bill: bill, external_id: "ocd-bill/1")
      }.to raise_error(BillImportService::ExternalError, /already linked/)
    end

    it "allows re-linking a bill to the same external_id it already has" do
      bill.update!(external_id: "ocd-bill/1")
      stub_open_states_fetch(external_id: "ocd-bill/1")

      expect {
        BillImportService.link(bill: bill, external_id: "ocd-bill/1")
      }.not_to raise_error
    end

    it "raises ExternalError when Open States returns non-200" do
      stub_open_states_fetch(external_id: "ocd-bill/bad", status: 404)
      expect {
        BillImportService.link(bill: bill, external_id: "ocd-bill/bad")
      }.to raise_error(BillImportService::ExternalError, /404/)
    end
  end

  # -------------------------------------------------------------------------
  describe ".scrape_revisor_description" do
    it "returns the paragraph text after an h2 Description heading" do
      stub_request(:get, /revisor\.mn\.gov\/bills/)
        .to_return(status: 200, body: REVISOR_HTML_WITH_DESC, headers: { "Content-Type" => "text/html" })
      result = BillImportService.scrape_revisor_description("HF 100", "2025-2026")
      expect(result).to eq "This is the Revisor description."
    end

    it "returns nil when the page has no Description heading" do
      stub_request(:get, /revisor\.mn\.gov\/bills/)
        .to_return(status: 200, body: REVISOR_HTML_NO_DESC, headers: { "Content-Type" => "text/html" })
      result = BillImportService.scrape_revisor_description("SF 200", "2025-2026")
      expect(result).to be_nil
    end

    it "returns nil on non-200 response" do
      stub_request(:get, /revisor\.mn\.gov\/bills/).to_return(status: 404, body: "")
      expect(BillImportService.scrape_revisor_description("HF 100", "2025-2026")).to be_nil
    end

    it "follows a redirect and returns the description" do
      stub_request(:get, /revisor\.mn\.gov\/bills\/94\/2025/)
        .to_return(status: 301, headers: { "Location" => "https://www.revisor.mn.gov/bills/94/2026/0/HF/100/?body=house" })
      stub_request(:get, /revisor\.mn\.gov\/bills\/94\/2026/)
        .to_return(status: 200, body: REVISOR_HTML_WITH_DESC, headers: { "Content-Type" => "text/html" })
      result = BillImportService.scrape_revisor_description("HF 100", "2025")
      expect(result).to eq "This is the Revisor description."
    end

    it "returns nil on network timeout without raising" do
      stub_request(:get, /revisor\.mn\.gov\/bills/).to_timeout
      expect(BillImportService.scrape_revisor_description("HF 100", "2025-2026")).to be_nil
    end

    it "returns nil when identifier is blank" do
      expect(BillImportService.scrape_revisor_description("", "2025-2026")).to be_nil
    end

    it "returns nil when identifier has no recognizable form" do
      expect(BillImportService.scrape_revisor_description("not-a-bill", "2025-2026")).to be_nil
    end

    it "constructs a senate URL for SF bills" do
      stub_request(:get, /revisor\.mn\.gov\/bills\/\d+\/\d+\/0\/SF\/\d+\/\?body=senate/)
        .to_return(status: 200, body: REVISOR_HTML_WITH_DESC, headers: { "Content-Type" => "text/html" })
      result = BillImportService.scrape_revisor_description("SF 5092", "2025-2026")
      expect(result).to eq "This is the Revisor description."
    end

    it "constructs a house URL for HF bills" do
      stub_request(:get, /revisor\.mn\.gov\/bills\/\d+\/\d+\/0\/HF\/\d+\/\?body=house/)
        .to_return(status: 200, body: REVISOR_HTML_WITH_DESC, headers: { "Content-Type" => "text/html" })
      result = BillImportService.scrape_revisor_description("HF 100", "2025-2026")
      expect(result).to eq "This is the Revisor description."
    end
  end

  # -------------------------------------------------------------------------
  describe ".map_status" do
    it "returns :introduced when actions is empty" do
      expect(BillImportService.map_status([])).to eq :introduced
    end

    it "returns the highest-priority status across all actions" do
      actions = [
        { "classification" => ["introduced"] },
        { "classification" => ["referral-committee"] },
        { "classification" => ["committee-passage"] },
        { "classification" => ["passage"] }
      ]
      expect(BillImportService.map_status(actions)).to eq :passed_chamber
    end

    it "maps executive-signature to :signed" do
      actions = [ { "classification" => ["executive-signature"] } ]
      expect(BillImportService.map_status(actions)).to eq :signed
    end

    it "maps executive-veto to :vetoed" do
      actions = [ { "classification" => ["executive-veto"] } ]
      expect(BillImportService.map_status(actions)).to eq :vetoed
    end

    it "maps failure to :failed" do
      actions = [ { "classification" => ["failure"] } ]
      expect(BillImportService.map_status(actions)).to eq :failed
    end

    it "ignores unknown classification strings" do
      actions = [ { "classification" => ["some-unknown-action"] } ]
      expect(BillImportService.map_status(actions)).to eq :introduced
    end

    it "handles actions with no classification key" do
      actions = [ { "description" => "Something happened" } ]
      expect(BillImportService.map_status(actions)).to eq :introduced
    end
  end

  # -------------------------------------------------------------------------
  describe ".sync_actions" do
    let(:bill) { create(:bill) }
    let(:raw_actions) do
      [
        { "date" => "2026-01-10", "description" => "Introduced in House",     "classification" => ["introduced"] },
        { "date" => "2026-01-20", "description" => "Referred to committee",   "classification" => ["referral-committee"] },
        { "date" => "2026-02-01", "description" => "Passed committee",        "classification" => ["committee-passage"] }
      ]
    end

    it "creates BillAction records for each action" do
      BillImportService.sync_actions(bill: bill, raw_actions: raw_actions)
      expect(bill.bill_actions.count).to eq 3
      expect(bill.bill_actions.first.description).to eq "Introduced in House"
      expect(bill.bill_actions.first.classification).to eq ["introduced"]
    end

    it "assigns action_order matching the array index" do
      BillImportService.sync_actions(bill: bill, raw_actions: raw_actions)
      expect(bill.bill_actions.order(:action_order).map(&:action_order)).to eq [0, 1, 2]
    end

    it "replaces existing actions on re-sync" do
      BillImportService.sync_actions(bill: bill, raw_actions: raw_actions)
      new_actions = [{ "date" => "2026-03-01", "description" => "Signed", "classification" => ["executive-signature"] }]
      BillImportService.sync_actions(bill: bill, raw_actions: new_actions)
      expect(bill.bill_actions.reload.count).to eq 1
      expect(bill.bill_actions.first.description).to eq "Signed"
    end

    it "skips actions missing date or description" do
      actions = [
        { "date" => nil,        "description" => "No date",    "classification" => [] },
        { "date" => "2026-01-10", "description" => "",         "classification" => [] },
        { "date" => "2026-01-10", "description" => "Good one", "classification" => ["introduced"] }
      ]
      BillImportService.sync_actions(bill: bill, raw_actions: actions)
      expect(bill.bill_actions.count).to eq 1
    end

    it "does nothing when raw_actions is blank" do
      BillImportService.sync_actions(bill: bill, raw_actions: [])
      expect(bill.bill_actions.count).to eq 0
    end
  end

  # -------------------------------------------------------------------------
  describe "miscellaneous error handling" do
    it "raises ExternalError if API key is blank" do
      stub_const("BillImportService::API_KEY", nil)
      expect {
        BillImportService.search(query: "any")
      }.to raise_error(BillImportService::ExternalError, /not configured/)
    end

    it "raises ExternalError on invalid JSON response" do
      stub_request(:get, /v3\.openstates\.org\/bills/).to_return(status: 200, body: "not json")
      expect {
        BillImportService.search(query: "any")
      }.to raise_error(BillImportService::ExternalError, /Invalid response/)
    end
  end

  # -------------------------------------------------------------------------
  describe ".scrape_legislator_bio" do
    SENATE_BIO_HTML = <<~HTML
      <html><body>
        <h1>Senator Jeff R. Howe (13, R)</h1>
        <p>651-296-2084</p>
        <a href="mailto:jeff.howe@senate.mn">jeff.howe@senate.mn</a>
      </body></html>
    HTML

    HOUSE_BIO_HTML = <<~HTML
      <html><body>
        <h1>Rep. Jim Joy (R) District: 04B</h1>
        <p>651-296-6829</p>
        <a href="mailto:rep.jim.joy@house.mn.gov">rep.jim.joy@house.mn.gov</a>
      </body></html>
    HTML

    it "parses first name, last name, title and display_name from a senate bio page" do
      stub_request(:get, /senate\.mn\/members\/member_bio/)
        .to_return(status: 200, body: SENATE_BIO_HTML, headers: { "Content-Type" => "text/html" })
      bio = BillImportService.scrape_legislator_bio("https://www.senate.mn/members/member_bio.html?leg_id=15401")
      expect(bio[:first_name]).to eq "Jeff"
      expect(bio[:last_name]).to eq  "Howe"
      expect(bio[:display_name]).to  eq "Jeff Howe"
      expect(bio[:title]).to eq "Senator"
    end

    it "parses a house member bio page" do
      stub_request(:get, /house\.mn\.gov\/members\/profile/)
        .to_return(status: 200, body: HOUSE_BIO_HTML, headers: { "Content-Type" => "text/html" })
      bio = BillImportService.scrape_legislator_bio("https://www.house.mn.gov/members/profile/15591")
      expect(bio[:first_name]).to eq "Jim"
      expect(bio[:last_name]).to eq  "Joy"
      expect(bio[:title]).to eq "Rep."
    end

    it "returns nil on network failure" do
      stub_request(:get, /senate\.mn/).to_timeout
      expect(BillImportService.scrape_legislator_bio("https://www.senate.mn/members/member_bio.html?leg_id=1")).to be_nil
    end

    it "returns nil when the page has no h1" do
      stub_request(:get, /senate\.mn/)
        .to_return(status: 200, body: "<html><body><p>nothing</p></body></html>")
      expect(BillImportService.scrape_legislator_bio("https://www.senate.mn/members/member_bio.html?leg_id=1")).to be_nil
    end
  end

  # -------------------------------------------------------------------------
  describe ".scrape_authors" do
    let(:admin)  { create(:user, :admin) }
    let(:bill)   { create(:bill, bill_number: "SF 5092", session_year: 2026, chamber: "senate") }

    REVISOR_WITH_AUTHORS = <<~HTML
      <html><body>
        <h2>Description</h2><p>Some bill.</p>
        <h2>Authors <span>(2)</span></h2>
        <div class="author"><ul>
          <li><a href="https://www.senate.mn/members/member_bio.html?leg_id=11">Howe</a></li>
          <li><a href="https://www.senate.mn/members/member_bio.html?leg_id=22">Smith</a></li>
        </ul></div>
      </body></html>
    HTML

    SENATOR_HOWE_BIO = <<~HTML
      <html><body>
        <h1>Senator Jeff Howe (13, R)</h1>
        <a href="mailto:jeff.howe@senate.mn">jeff.howe@senate.mn</a>
      </body></html>
    HTML

    SENATOR_SMITH_BIO = <<~HTML
      <html><body>
        <h1>Senator Alice Smith (5, D)</h1>
        <a href="mailto:alice.smith@senate.mn">alice.smith@senate.mn</a>
      </body></html>
    HTML

    before do
      stub_request(:get, /revisor\.mn\.gov\/bills/)
        .to_return(status: 200, body: REVISOR_WITH_AUTHORS, headers: { "Content-Type" => "text/html" })
      stub_request(:get, /leg_id=11/)
        .to_return(status: 200, body: SENATOR_HOWE_BIO, headers: { "Content-Type" => "text/html" })
      stub_request(:get, /leg_id=22/)
        .to_return(status: 200, body: SENATOR_SMITH_BIO, headers: { "Content-Type" => "text/html" })
    end

    it "creates Person records and BillPerson links for each author" do
      result = BillImportService.scrape_authors(bill: bill, created_by: admin)
      expect(result[:added].map(&:last_name)).to match_array(%w[Howe Smith])
      expect(result[:skipped]).to be_empty
      expect(result[:errors]).to be_empty
      expect(bill.bill_people.count).to eq 2
    end

    it "skips authors already linked to the bill" do
      existing = create(:person, first_name: "Jeff", last_name: "Howe", display_name: "Jeff Howe")
      BillPerson.create!(bill: bill, person: existing, added_by: admin)

      result = BillImportService.scrape_authors(bill: bill, created_by: admin)
      expect(result[:added].map(&:last_name)).to eq ["Smith"]
      expect(result[:skipped].map(&:last_name)).to eq ["Howe"]
    end

    it "reuses an existing Person record matched by first+last name" do
      create(:person, first_name: "Jeff", last_name: "Howe", display_name: "Jeff Howe")
      expect {
        BillImportService.scrape_authors(bill: bill, created_by: admin)
      }.to change(Person, :count).by(1) # only Smith is new
    end

    it "raises ExternalError when bill has no bill_number" do
      bill.bill_number = nil
      expect {
        BillImportService.scrape_authors(bill: bill, created_by: admin)
      }.to raise_error(BillImportService::ExternalError, /bill_number/)
    end

    it "raises ExternalError when no authors are found on the page" do
      stub_request(:get, /revisor\.mn\.gov\/bills/)
        .to_return(status: 200, body: REVISOR_HTML_NO_DESC, headers: { "Content-Type" => "text/html" })
      expect {
        BillImportService.scrape_authors(bill: bill, created_by: admin)
      }.to raise_error(BillImportService::ExternalError, /No authors found/)
    end

    it "collects bio scrape failures into errors without raising" do
      stub_request(:get, /leg_id=22/).to_timeout
      result = BillImportService.scrape_authors(bill: bill, created_by: admin)
      expect(result[:added].map(&:last_name)).to eq ["Howe"]
      expect(result[:errors].size).to eq 1
    end
  end
end
