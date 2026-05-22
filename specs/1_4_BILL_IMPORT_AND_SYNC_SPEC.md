# Spec: 1.4 Bill Import and Sync (Open States Integration)

## 1. Objective
Allow staff and managers to search Minnesota legislative bills from the Open States API v3, import selected bills into the local database, and keep imported bill records synchronized with the latest data from Open States. Manually entered bills can also be linked to an Open States record to enable future syncing.

## 2. Success Criteria
1. Staff can search Minnesota bills by keyword and see results from Open States without leaving the app.
2. A bill from the search results can be imported as a local Bill record in one click.
3. An imported bill shows "Last synced" timestamp and a Refresh button in its detail view.
4. A manually created bill can be linked to an Open States record via a search-and-link flow.
5. A linked bill shows a Refresh button; an unlinked manual bill shows a Link button.
6. Refreshing a bill re-pulls data from Open States and updates editable fields.
7. Baseline tests pass for the import service, new endpoints, and frontend components.

## 3. In Scope (1.4 only)
1. External bill search proxy: backend endpoint that queries Open States API and returns normalized results.
2. Import action: creates a local Bill from an Open States result, setting external_id, source_url, and last_synced_at.
3. Link action: for existing manually created bills, searches Open States and attaches an external_id.
4. Refresh action: re-pulls an already-linked bill from Open States and updates its fields.
5. BillImportService: Rails service object encapsulating Open States API calls and field mapping.
6. UI for search modal (reusable for both import and link flows).
7. Refresh and Link buttons on bill detail header contextual on whether external_id is set.
8. Open States credential configuration via Rails credentials / environment variable.

## 4. Out of Scope (for 1.4)
1. Automated / scheduled background sync (polling or webhooks) — future layer.
2. Multi-state support (only Minnesota in 1.4).
3. Bulk import of multiple bills from a single search action.
4. Amendment or version tracking from Open States.
5. Vote or roll-call data from Open States.
6. Full Open States data model (fiscal notes, hearing schedules, etc.).
7. Activity logging against a bill.
8. AI drafting from bill context.

---

## Functional Requirements

## 5. Roles and Permissions
All roles that can create bills (admin, staff, manager) can search, import, link, and refresh bills.

1. Admin:
- Can search, import, link, and refresh any bill.

2. Staff:
- Can search, import, link, and refresh any bill.

3. Manager:
- Can search and import bills.
- Can link and refresh bills in their client scope only.

4. Unauthorized user:
- Cannot access any external search or sync endpoints.

## 6. External Data Source
- Provider: Open States API v3 (https://v3.openstates.org)
- Authentication: `X-API-KEY` header, key stored in Rails credentials as `open_states_api_key`.
- Primary endpoints used:
  - `GET /bills?jurisdiction=mn&q={query}&page=1&per_page=20` — keyword search
  - `GET /bills/{jurisdiction}/{session}/{bill_id}` — single bill detail
- Response fields of interest:
  - `id` → external_id
  - `identifier` → bill_number (e.g. "HF 1234")
  - `title` → title
  - `chamber` → chamber (mapped: lower → house, upper → senate)
  - `session` → session_year (extract year from session label)
  - `classification` → ignored for now
  - `openstates_url` → source_url
  - `updated_at` → last_synced_at (set at time of import/refresh)

## 7. Field Mapping (Open States → Local Bill)
| Open States field | Local bill field | Notes |
|---|---|---|
| id | external_id | stored as-is |
| identifier | bill_number | e.g. "HF 1234" |
| title | title | truncated to 500 chars if needed |
| from_organization.classification | chamber | lower=house, upper=senate |
| legislative_session.identifier | session_year | parse 4-digit year |
| openstates_url | source_url | |
| (time of sync) | last_synced_at | set to current UTC time |

Fields that are NOT overwritten by import/refresh: description, notes, tags, status (default introduced on import), companion_bill_id.
Fields that ARE overwritten on refresh: bill_number, title, chamber, session_year, source_url, last_synced_at.

## 8. Workflows

### 8.1 Search and Import
1. User clicks "Search Open States" button on Bill List page.
2. Search modal opens with a keyword input.
3. User types query; results load (debounced 400ms) from `GET /bills/search?q=...`.
4. Results table shows: Bill Number, Title, Chamber, Session, and an Import button per row.
5. If a result's external_id already exists in the local DB, row shows "Already Imported" chip instead of Import button.
6. User clicks Import → `POST /bills/import` with the Open States bill identifier.
7. Backend fetches full bill detail from Open States, maps fields, creates local Bill record, returns it.
8. Modal closes; user is navigated to the new bill's detail page.

### 8.2 Link Manual Bill to External Record
1. User views a manually created bill (no external_id) and clicks "Link to Open States".
2. Same search modal opens.
3. User finds the matching bill and clicks "Link".
4. `PATCH /bills/:id/link_external` with { external_id }.
5. Backend verifies external_id exists at Open States, stores it and source_url, sets last_synced_at.
6. Bill detail header updates: Link button replaced by Refresh button and "Last synced" timestamp.

### 8.3 Refresh Linked Bill
1. User views a bill with external_id set and clicks "Refresh".
2. `POST /bills/:id/refresh` (no body required).
3. Backend calls Open States single-bill endpoint, updates mapped fields, sets last_synced_at.
4. Bill detail re-renders with updated data and new last_synced_at timestamp.

## 9. Core Constraints
1. Import is idempotent on external_id: attempting to import a bill whose external_id already exists returns the existing record (200) rather than creating a duplicate.
2. Refresh does not overwrite user-managed fields (description, notes, tags, status, companion_bill_id).
3. All Open States API calls are made server-side (never from the browser); the API key is never exposed to the frontend.
4. If Open States returns a non-200 response, the backend returns a structured error to the frontend (no raw API error exposed).
5. Timeouts: Open States requests should time out after 10 seconds; surface a user-friendly error if exceeded.

---

## API Spec

## 10. Endpoints

### Search (proxy)
1. GET /bills/search
- Query params: q (required), page (optional, default 1), per_page (optional, default 20)
- Proxies to Open States `/bills?jurisdiction=mn`
- Returns normalized list of Open States results (not local Bill records)
- Authentication required; any authenticated role may call this endpoint
- Response: { status, message, data: { results: [...], total, page, per_page } }

### Import
2. POST /bills/import
- Body: { external_id } — the Open States bill id
- Fetches full bill detail from Open States, creates local Bill record
- Idempotent: if external_id already exists locally, returns existing record
- Returns normalized local Bill payload (same shape as GET /bills/:id)

### Link external
3. PATCH /bills/:id/link_external
- Body: { external_id }
- Validates external_id against Open States (single-bill fetch)
- Sets external_id, source_url, last_synced_at on the local bill
- Returns updated Bill payload
- 422 if external_id already linked to a different local bill

### Refresh
4. POST /bills/:id/refresh
- No request body
- Bill must have external_id set (422 if not)
- Fetches latest data from Open States, updates mapped fields, sets last_synced_at
- Returns updated Bill payload

## 11. Response Shape
Reuses the standard { status, message, data, errors } envelope from 1.3.

Search results payload (item shape):
- external_id, bill_number, title, chamber, session_year, source_url
- already_imported (boolean)

Import / link / refresh payload: same full Bill payload as defined in 1.3 spec §11.

---

## Backend Architecture

## 12. BillImportService
A Rails service object at `backend/app/services/bill_import_service.rb`.

Responsibilities:
1. `search(query:, page:, per_page:)` — calls Open States search endpoint, normalizes results.
2. `fetch(external_id:)` — calls Open States single-bill endpoint, normalizes result.
3. `import(external_id:, created_by:)` — calls fetch, maps fields, creates or finds local Bill.
4. `refresh(bill:)` — calls fetch using bill.external_id, updates mapped fields.
5. `link(bill:, external_id:)` — calls fetch to validate external_id, then persists it on the bill.

Error handling:
- Wraps HTTP calls in begin/rescue; raises `BillImportService::ExternalError` on non-200 or timeout.
- Controller rescues `ExternalError` and renders 502 with a structured error message.

HTTP client: use `Net::HTTP` or `Faraday` if already in Gemfile; prefer no new gem unless Faraday is already present.

## 13. New Routes
```
# config/routes.rb additions (under namespace :api or at root, follow existing pattern)
get  'bills/search',        to: 'bills#search'
post 'bills/import',        to: 'bills#import'
patch 'bills/:id/link_external', to: 'bills#link_external'
post 'bills/:id/refresh',   to: 'bills#refresh'
```

These route additions go in BillsController alongside 1.3 CRUD actions.

---

## Data Model Changes (1.4)
No new tables required. The three prep fields added in 1.3 (`external_id`, `source_url`, `last_synced_at`) are populated by the import/link/refresh workflows.

Add unique index on `bills.external_id` (partial: WHERE external_id IS NOT NULL) to enforce idempotency at the DB layer.

---

## Frontend Spec

## 14. Screens and Components

### Bill List additions (/bills)
- "Search Open States" button added to the header bar alongside "New Bill".
- Clicking opens the BillSearchModal component.

### BillSearchModal (new reusable component)
- Props: `mode` (import | link), `billId` (required when mode=link).
- Keyword input with debounced search (400ms).
- Results table: Bill Number, Title, Chamber, Session Year, Action column.
- Import mode: Action = "Import" button (or "Already Imported" chip).
- Link mode: Action = "Link" button.
- Loading skeleton while fetching; empty state if no results.
- Error state if search fails (network or API error).
- On import success: close modal, navigate to new bill's detail page.
- On link success: close modal, emit `linked` event; parent refreshes bill data.

### Bill Detail additions (/bills/:id)
- Header action area shows contextual buttons based on external_id:
  - No external_id: show "Link to Open States" button → opens BillSearchModal in link mode.
  - Has external_id: show "Refresh" button + "Last synced: {last_synced_at}" label.
- Refresh button calls `POST /bills/:id/refresh`; shows loading spinner while in-flight.
- After refresh, bill data re-fetched and detail view updated.

## 15. State Management additions
1. Bill store additions:
- `searchExternalBills(query, page)` — calls GET /bills/search, returns results array
- `importBill(externalId)` — calls POST /bills/import, prepends new bill to list
- `linkExternal(billId, externalId)` — calls PATCH /bills/:id/link_external, updates currentBill
- `refreshBill(billId)` — calls POST /bills/:id/refresh, updates currentBill

2. Search result state managed locally in BillSearchModal (not in global store).

## 16. UX Requirements
1. "Last synced" timestamp shown in relative format (e.g. "2 hours ago") with full ISO timestamp on hover.
2. Refresh button shows inline spinner; bill header fields update in-place on success.
3. "Already Imported" chip links to the existing local bill record.
4. Error snackbar shown if import, link, or refresh fails (use the error message from the API response).
5. Search modal is dismissible by clicking outside or pressing Escape.

---

## Testing Spec

## 17. Backend Tests
1. Service tests (spec/services/bill_import_service_spec.rb):
- Search: normalizes Open States response, marks already_imported correctly.
- Import: creates new bill, maps fields correctly, returns existing bill if external_id present.
- Refresh: updates mapped fields, does not overwrite user-managed fields.
- Link: validates external_id, updates bill, raises error on duplicate external_id.
- Error handling: raises ExternalError on non-200 and on timeout.
- Use WebMock or VCR to stub Open States API calls; do not make live HTTP calls in tests.

2. Request tests (additions to spec/requests/bills_request_spec.rb):
- GET /bills/search: returns results, requires auth, requires q param.
- POST /bills/import: creates bill, idempotent on duplicate external_id.
- PATCH /bills/:id/link_external: links and returns updated bill; 422 on duplicate.
- POST /bills/:id/refresh: updates and returns updated bill; 422 if no external_id.

## 18. Frontend Tests
1. BillSearchModal tests:
- Renders search input and results table.
- Debounced search calls store action after 400ms.
- Import mode: Import button triggers importBill action, navigates on success.
- Link mode: Link button triggers linkExternal action, emits `linked` on success.
- Error state renders snackbar.

2. Store tests (billStore additions):
- searchExternalBills: calls correct endpoint, returns normalized results.
- importBill: calls correct endpoint, prepends to bills list on success.
- linkExternal: calls correct endpoint, updates currentBill on success.
- refreshBill: calls correct endpoint, updates currentBill on success.

---

## Non-Functional Requirements

## 19. Performance
1. Open States search results displayed within 2 seconds of user stopping typing (network dependent; show loading state immediately).
2. Refresh operation completes within 5 seconds; timeout after 10 seconds with error shown.
3. Search results are not cached locally (always fresh from Open States).

## 20. Security
1. Open States API key stored in Rails credentials (never in source code or frontend).
2. All Open States HTTP calls made server-side only.
3. external_id values validated against Open States before being persisted (no blind storage of arbitrary strings).
4. Standard Pundit authorization applied to all four new endpoints.
5. Input: `q` parameter sanitized before inclusion in Open States request URL (no SSRF vectors).

## 21. Observability
1. Log each Open States API call: endpoint, duration, status code.
2. Track events: bill imported, bill linked to external, bill refreshed.
3. Surface structured error messages from BillImportService to UI snackbar.

---

## Definition of Done (1.4)
1. BillImportService implemented with search, import, refresh, and link methods; all HTTP calls stubbed in tests.
2. GET /bills/search, POST /bills/import, PATCH /bills/:id/link_external, POST /bills/:id/refresh endpoints implemented with auth and policy.
3. BillSearchModal component implemented for both import and link modes.
4. Refresh and Link buttons shown contextually on bill detail based on external_id presence.
5. All backend service and request specs passing.
6. All frontend store and component tests passing (with mocked API responses).
7. API key never appears in frontend bundle or logs.
8. Team can demo: search Open States, import a bill, view synced fields, click Refresh to re-sync, link a manual bill to an external record.
