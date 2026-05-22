# Spec: 1.3 Bill Management

## 1. Objective
Give lobbyists and public affairs staff a structured way to track Minnesota legislative bills alongside their issues, clients, and contacts. Bills become the legislative anchor of the platform, linking to issues for context, to clients for scope, and to people for authorship and sponsorship tracking.

## 2. Success Criteria
1. Staff can create, view, update, and change the status of a bill in under 2 minutes.
2. Bills can be linked to and unlinked from issues from both the bill and issue detail pages.
3. Bills can be linked to clients to track which clients care about a given bill.
4. People can be added to or removed from a bill to reflect authors, sponsors, and key contacts.
5. Managers see only bills linked to their clients.
6. Bills are searchable and filterable by status, chamber, and session year from the list view.
7. Baseline tests pass for backend and frontend.

## 3. In Scope (1.3 only)
1. Bill data model and CRUD API.
2. Bill list and bill detail UI.
3. Status workflow: 10 statuses covering the full legislative lifecycle.
4. Chamber tracking: house or senate.
5. Session year tracking.
6. Companion bill self-reference (optional foreign key to another bill).
7. Issue linking: add/remove issues from a bill (and bills from an issue from IssueShow).
8. Client linking: add/remove clients from a bill.
9. People linking: add/remove people from a bill (authors, sponsors, contacts).
10. Tags: free-form labels on each bill.
11. Notes field: internal note separate from description.
12. Audit fields: created_by, updated_by.
13. Prep fields for future external sync: external_id, source_url, last_synced_at (nullable, unused in 1.3).
14. Baseline tests (model, policy, request, store/component).

## 4. Out of Scope (for 1.3)
1. External API integration (Open States or any other data source) — deferred to 1.4.
2. Import, search-import, link-to-external, and refresh workflows — deferred to 1.4.
3. Activity logging against a bill.
4. AI drafting from bill context.
5. Multi-state architecture.
6. Email or notification workflows.
7. Amendment tracking.

---

## Functional Requirements

## 5. Roles and Permissions
1. Admin:
- Full CRUD on all bills regardless of client.
- Can link and unlink issues, clients, and people on any bill.

2. Staff:
- Full CRUD on all bills regardless of client.
- Can link and unlink issues, clients, and people on any bill.

3. Manager:
- Can create, view, update, and change the status of bills linked to their clients.
- Can view bills linked to any of their clients.
- Can link and unlink issues, clients, and people on bills in their client scope.
- Cannot see bills not linked to any of their clients.

4. All other authenticated roles:
- No bill access unless explicitly granted by policy.

5. Unauthorized user:
- Cannot access any bill endpoints.

## 6. Bill Fields (MVP)
1. Required:
- Title (min length 2)
- Status (default: introduced)

2. Optional:
- Bill number (string, e.g. "HF 1234" or "SF 5678")
- Chamber (house or senate)
- Session year (integer, e.g. 2025)
- Description (long-form text)
- Notes (internal note, separate from description)
- Tags (array of free-form strings)
- Companion bill (self-reference to another Bill record)

3. External sync prep fields (nullable, unused in 1.3):
- external_id (string) — identifier from an external data source
- source_url (string) — canonical URL at the external source
- last_synced_at (datetime) — timestamp of last external sync

4. System / audit fields:
- created_at / updated_at
- created_by / updated_by (User FK)

## 7. Bill Statuses
| Value | Label |
|---|---|
| introduced | Introduced |
| in_committee | In Committee |
| passed_committee | Passed Committee |
| floor_vote | Floor Vote |
| passed_chamber | Passed Chamber |
| passed_both_chambers | Passed Both Chambers |
| signed | Signed |
| vetoed | Vetoed |
| failed | Failed |
| carried_over | Carried Over |

Default status on creation: `introduced`.

## 8. Validation Rules
1. Title required, minimum 2 characters.
2. Status must be one of the 10 defined values.
3. Chamber, if provided, must be `house` or `senate`.
4. Session year, if provided, must be a 4-digit integer (1900–2100).
5. Tags must be an array; individual tag values trimmed of whitespace.
6. companion_bill_id, if provided, must reference an existing bill and cannot be self-referential.
7. A client cannot be linked to the same bill more than once.
8. An issue cannot be linked to the same bill more than once.
9. A person cannot be added to the same bill more than once.

## 9. Core Workflows
1. Create bill:
- User enters required title; optionally sets bill_number, chamber, session_year, status, description, notes, tags.
- Bill created with status `introduced` if not specified.
- Success navigates to bill detail.

2. Edit bill:
- Update any field except id and audit timestamps.

3. Change status:
- Inline status selector on bill detail; no confirmation required.
- Staff and admin can update to any status.

4. Link issue to bill:
- From bill detail Issues tab.
- Autocomplete picker shows all issues not already linked.
- Remove button per row.
- Also available from IssueShow Bills tab (links in the other direction via IssueBillsController).

5. Link client to bill:
- From bill detail Clients tab.
- Autocomplete picker shows all clients not already linked.
- Remove button per row.

6. Link person to bill:
- From bill detail People tab.
- Autocomplete picker shows all people not already linked.
- Remove button per row.

7. Set companion bill:
- From edit dialog, optional field shows autocomplete of other bills.

8. Search/filter bills:
- Search by title or bill_number (debounced, case-insensitive).
- Filter by status, chamber, session_year.

---

## API Spec (MVP)

## 10. Endpoints

### Bills (CRUD)
1. GET /bills
- Filters: status, chamber, session_year, client_id, query (title/bill_number search)
- Pagination: page, per_page
- Default: all bills in caller's scope

2. POST /bills
- Creates bill with required title plus optional fields
- Returns normalized bill payload

3. GET /bills/:id
- Returns full bill detail if authorized

4. PATCH /bills/:id
- Partial update (any editable field)

5. DELETE /bills/:id
- Soft-deactivates the bill (sets status to failed or a deactivated state; see implementation notes)

### Issues (nested under bill)
6. GET /bills/:bill_id/issues
- Returns list of issues linked to the bill

7. POST /bills/:bill_id/issues
- Body: { issue_id }
- Links an issue to the bill

8. DELETE /bills/:bill_id/issues/:issue_id
- Unlinks an issue from the bill

### Bills (nested under issue — mirror endpoint)
9. GET /issues/:issue_id/bills
- Returns list of bills linked to the issue

10. POST /issues/:issue_id/bills
- Body: { bill_id }
- Links a bill to the issue

11. DELETE /issues/:issue_id/bills/:bill_id
- Unlinks a bill from the issue

### Clients (nested under bill)
12. GET /bills/:bill_id/clients
- Returns list of clients linked to the bill

13. POST /bills/:bill_id/clients
- Body: { client_id }
- Links a client to the bill

14. DELETE /bills/:bill_id/clients/:client_id
- Unlinks a client from the bill

### People (nested under bill)
15. GET /bills/:bill_id/people
- Returns list of people linked to the bill

16. POST /bills/:bill_id/people
- Body: { person_id }
- Adds a person to the bill

17. DELETE /bills/:bill_id/people/:person_id
- Removes a person from the bill

## 11. Response Shape
1. Use existing standard success/error envelope: { status, message, data, errors }.
2. Return serialized bill attributes (not raw model internals).
3. Bill payload includes:
- id, bill_number, chamber, session_year, title, description, notes, tags, status
- companion_bill: { id, bill_number, title } (nullable)
- issues: [{ id, title, status }]
- clients: [{ id, display_name, linked_at }]
- people: [{ id, display_name, title, organization, email }]
- issues_count, clients_count, people_count
- external_id, source_url, last_synced_at (present but null in 1.3)
- created_by, updated_by (id + email)
- created_at, updated_at

---

## Data Model Spec

## 12. Entities

### bills table
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| bill_number | string | optional (e.g. "HF 1234") |
| chamber | integer | enum: house=0, senate=1; optional |
| session_year | integer | optional (e.g. 2025) |
| title | string | NOT NULL |
| description | text | optional |
| notes | text | optional |
| tags | string[] | GIN index, default [] |
| status | integer | NOT NULL, default 0 (introduced) |
| companion_bill_id | bigint FK→bills | self-reference, optional |
| external_id | string | nullable, unused in 1.3 |
| source_url | string | nullable, unused in 1.3 |
| last_synced_at | datetime | nullable, unused in 1.3 |
| created_by_id | bigint FK→users | optional |
| updated_by_id | bigint FK→users | optional |
| created_at / updated_at | datetime | |

### bill_issues table (join)
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| bill_id | bigint FK | NOT NULL |
| issue_id | bigint FK | NOT NULL |
| added_by_id | bigint FK→users | optional |
| added_at | datetime | optional |

Unique index on [bill_id, issue_id].

### bill_clients table (join)
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| bill_id | bigint FK | NOT NULL |
| client_id | bigint FK | NOT NULL |
| shared_by_id | bigint FK→users | optional |
| shared_at | datetime | optional |

Unique index on [bill_id, client_id].

### bill_people table (join)
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| bill_id | bigint FK | NOT NULL |
| person_id | bigint FK | NOT NULL |
| added_by_id | bigint FK→users | optional |

Unique index on [bill_id, person_id].

## 13. Indexing
1. bills: status, chamber, session_year, companion_bill_id, external_id, tags (GIN).
2. bill_issues: [bill_id, issue_id] unique.
3. bill_clients: [bill_id, client_id] unique.
4. bill_people: [bill_id, person_id] unique.

---

## Frontend Spec

## 14. Screens

### Bill List (/bills)
- Card-per-bill layout with bill_number, title, chamber chip, status chip, and tags.
- Search bar (debounced) and filters: status dropdown, chamber dropdown, session year input.
- "New Bill" button opens create dialog.
- Create dialog: title (required), bill_number, chamber, session_year, status, description, notes, tags (combobox).
- Edit dialog available inline (same form fields).
- Empty state with message when no bills match filters.

### Bill Detail (/bills/:id)
- Header: bill_number (if present), title, chamber chip, status chip, session year, tags.
- Status picker (inline select or action menu) — all valid statuses available.
- Edit button opens edit dialog.
- Description and Notes sections if present.
- Companion bill link if set.
- Three tabs: Issues, Clients, People.

#### Issues tab
- Autocomplete picker showing issues not yet linked (displays title, status, client).
- Table with columns: Title, Status, Client, (Unlink button).
- Unlink button per row.
- Skeleton loaders during add/remove operations.

#### Clients tab
- Autocomplete picker showing clients not yet linked.
- Table with columns: Client, Linked Date, (Unlink button).
- Unlink button per row.

#### People tab
- Autocomplete picker showing people not yet linked (displays name, title, organization).
- Table with columns: Name, Title, Organization, Email, (Remove button).
- Remove button per row.

### IssueShow Bills Tab (added to existing /issues/:id)
- New "Bills" tab added after People and Shared Clients tabs.
- Autocomplete picker showing bills not yet linked to this issue.
- Table with columns: Bill Number, Title, Chamber, Status, (Unlink button).
- Unlink button per row.

## 15. State Management
1. Bill store (Pinia) with:
- bills, currentBill, isLoading, error
- fetchBills(params), fetchBill(id)
- createBill, updateBill, deleteBill
- linkIssue, unlinkIssue
- linkClient, unlinkClient
- addPerson, removePerson

2. Issue store additions:
- fetchIssueBills(issueId), linkBillToIssue(issueId, billId), unlinkBillFromIssue(issueId, billId)

3. Filter state (search query, status, chamber, session_year) managed locally in component; not persisted across navigation.

## 16. UX Requirements
1. Status chip colors:
- introduced = blue, in_committee = indigo, passed_committee = cyan,
- floor_vote = orange, passed_chamber = teal, passed_both_chambers = green,
- signed = deep green, vetoed = red, failed = grey, carried_over = amber.
2. Chamber chip: house = blue-grey, senate = purple.
3. Snackbar feedback on all create/update/link/unlink/error operations.
4. Empty state messages on Issues, Clients, and People tabs when lists are empty.
5. Auto-refresh pickers after add/remove operations.

---

## Testing Spec

## 17. Backend Tests
1. Model tests:
- Title validations, status enum, chamber enum.
- Tags array default and acceptance.
- companion_bill_id self-reference validation.
- Association integrity: bill_issues, bill_clients, bill_people.

2. Policy tests:
- Full role matrix (admin / staff / manager-in-scope / manager-out-of-scope / unauthorized) for index, show, create, update, destroy.
- Scope test: managers see only bills linked to their clients.

3. Request tests:
- CRUD happy paths for all 17 endpoints.
- Link/unlink paths for issues, clients, people.
- Duplicate-link 422 paths.
- Unauthorized and forbidden paths.

## 18. Frontend Tests
1. Store tests:
- API success and error handling for each action.
- List mutation: prepend on create, in-place update, issues/clients/people sync.

2. Component tests (Bills.vue):
- Fetch on mount, skeleton loaders, card rendering.
- Search and filter params passed to API.
- Create dialog success and error paths.

---

## Non-Functional Requirements

## 19. Performance
1. Bill list first page renders under 500ms on typical dev dataset.
2. Pagination required once list exceeds threshold (25 per page default).
3. GIN index on tags supports array containment queries.

## 20. Security
1. Authentication required for all bill endpoints.
2. Pundit authorization checked on every action.
3. Manager scope enforced at policy layer via BillClient join (not just UI).
4. Audit metadata (created_by, updated_by) recorded on every mutating action.

## 21. Observability
1. Track events: bill created, updated, status changed.
2. Track link events: issue linked/unlinked, client linked/unlinked, person linked/unlinked.
3. Surface actionable error messages from API to UI snackbar.

---

## Definition of Done (1.3)
1. All bill CRUD endpoints implemented with auth and policy.
2. Issue, client, and people linking endpoints implemented and tested with role restrictions enforced.
3. Manager scope working: managers see only bills linked to their clients.
4. Bill list and detail UI working end-to-end including Issues, Clients, and People tabs.
5. IssueShow Bills tab working: link and unlink bills from an issue.
6. All backend specs passing (model, policy, request).
7. All frontend store and component tests passing.
8. Team can demo: create bill, link to an issue, link to a client, add a person, change status, and view from IssueShow Bills tab.
