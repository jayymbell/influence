# Spec: 1.2 Issue Management

## 1. Objective
Give lobbyists and public affairs staff a structured way to track the specific policy matters and engagements they are working on for each client. Issues replace casual email threads and shared spreadsheets, and become the anchor for legislative tracking, activity logging, and AI drafting in later layers.

## 2. Success Criteria
1. Staff can create, view, update, and close issues in under 2 minutes per issue.
2. Every issue is owned by exactly one primary client and can be shared with additional clients.
3. People can be added to or removed from an issue to reflect who is assigned.
4. Status transitions (active → inactive → closed) are enforced and audited.
5. Only admins and managers can share or unshare issues across clients.
6. Issues are searchable and filterable by status from the list view.
7. Baseline tests pass for backend and frontend.

## 3. In Scope (1.2 only)
1. Issue data model and CRUD API.
2. Issue list and issue detail UI.
3. Status workflow: active, inactive, closed (with close timestamp and user audit).
4. People assignment: add/remove people from an issue.
5. Client sharing: link additional clients to an issue; unshare non-primary clients.
6. Tags: free-form labels on each issue.
7. Notes field: internal note separate from the description.
8. Baseline tests (model, policy, request, store/component).

## 4. Out of Scope (for 1.2)
1. Bill/legislation linking (1.2.1 or layer 2).
2. Activity logging against an issue.
3. AI drafting from issue context.
4. Legislative session scoping.
5. Email or notification workflows.
6. Multi-state architecture.

---

## Functional Requirements

## 5. Roles and Permissions
1. Admin:
- Full CRUD on all issues regardless of client.
- Can share and unshare any issue.
- Can add/remove any person on any issue.

2. Staff:
- Full CRUD on all issues regardless of client.
- Cannot share or unshare issues (share is manager/admin only).
- Can add/remove any person on any issue.

3. Manager:
- Can create, view, update, and close issues for clients they are assigned to.
- Can view issues shared with their clients.
- Can share and unshare issues for their clients.
- Can add/remove people on issues in their client scope.

4. All other authenticated roles:
- No issue access unless explicitly granted by policy.

5. Unauthorized user:
- Cannot access any issue endpoints.

## 6. Issue Fields (MVP)
1. Required:
- Title (min length 2)
- Status (active, inactive, closed)
- Primary client (set at creation, immutable)

2. Optional:
- Description (long-form text)
- Notes (internal note, separate from description)
- Tags (array of free-form strings)

3. System / audit fields:
- created_at / updated_at
- created_by / updated_by (User FK)
- closed_at / closed_by (User FK, stamped on close action)

## 7. Validation Rules
1. Title required, minimum 2 characters.
2. Status must be one of: active, inactive, closed.
3. Primary client (client_id) required and immutable after creation.
4. Tags must be an array; individual tag values trimmed of whitespace.
5. Closing an issue stamps closed_at and closed_by; reactivating clears both.
6. A client cannot be linked to the same issue more than once.
7. A person cannot be added to the same issue more than once.

## 8. Core Workflows
1. Create issue:
- User selects a primary client and enters required fields.
- Issue created with status active.
- Success navigates to issue detail.

2. Edit issue:
- Update title, description, notes, tags.
- Primary client cannot be changed after creation.

3. Deactivate issue:
- Sets status to inactive.
- No confirmation dialog required; reversible.

4. Close issue:
- Confirmation dialog required.
- Stamps closed_at and closed_by.
- Reversible via Reactivate.

5. Reactivate issue:
- Available from inactive or closed issue detail.
- Clears closed_at and closed_by.
- Sets status back to active.

6. Assign people:
- From issue detail People tab.
- Autocomplete picker shows all people not already assigned.
- Remove button per row.

7. Share with client:
- From issue detail Shared Clients tab; visible only to admins and managers.
- Autocomplete picker shows all clients not already linked.
- Primary client marker shown but cannot be unshared.
- Non-primary clients can be unshared by admins and managers.

8. Search/filter issues:
- Search by title (debounced, case-insensitive).
- Filter by status (active / inactive / closed).

---

## API Spec (MVP)

## 9. Endpoints

### Issues (CRUD + status transitions)
1. GET /issues
- Filters: status, client_id, query (title search)
- Pagination: page, per_page
- Default: all active issues in caller's scope

2. POST /issues
- Creates issue with required fields plus optional fields
- Returns normalized issue payload

3. GET /issues/:id
- Returns full issue detail if authorized

4. PATCH /issues/:id
- Partial update (title, description, notes, tags)
- Primary client cannot be changed

5. DELETE /issues/:id
- Sets status to inactive (soft delete semantics, not hard destroy)

6. POST /issues/:id/close
- Stamps closed_at and closed_by; sets status to closed

7. POST /issues/:id/deactivate
- Sets status to inactive

8. POST /issues/:id/reactivate
- Clears closed_at / closed_by; sets status to active

### People (nested under issue)
9. GET /issues/:id/people
- Returns list of people assigned to the issue

10. POST /issues/:id/people
- Body: { person_id }
- Adds a person to the issue

11. DELETE /issues/:id/people/:person_id
- Removes a person from the issue

### Clients / Sharing (nested under issue)
12. GET /issues/:id/clients
- Returns all clients linked to the issue (primary + shared)

13. POST /issues/:id/clients
- Body: { client_id }
- Shares the issue with an additional client
- Restricted to admin and manager roles

14. DELETE /issues/:id/clients/:client_id
- Unshares a non-primary client from the issue
- Cannot remove the primary client (returns 422)
- Restricted to admin and manager roles

## 10. Response Shape
1. Use existing standard success/error envelope: { status, message, data, errors }.
2. Return serialized issue attributes (not raw model internals).
3. Issue payload includes:
- id, title, description, notes, tags, status
- client: { id, display_name }
- shared_clients: [{ id, display_name, is_primary, shared_at, shared_by }]
- people: [{ id, display_name, title, organization, email }]
- people_count
- created_by, updated_by, closed_by (id + email)
- closed_at, created_at, updated_at

---

## Data Model Spec

## 11. Entities

### issues table
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| title | string | NOT NULL |
| description | text | optional |
| notes | text | optional |
| tags | string[] | GIN index, default [] |
| status | integer | NOT NULL, default 0 (active) |
| client_id | bigint FK | primary client, NOT NULL |
| closed_at | datetime | stamped on close |
| closed_by_id | bigint FK | user, optional |
| created_by_id | bigint FK | user, optional |
| updated_by_id | bigint FK | user, optional |
| created_at / updated_at | datetime | |

### client_issues table (join — primary + shared clients)
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| client_id | bigint FK | NOT NULL |
| issue_id | bigint FK | NOT NULL |
| is_primary | boolean | default false |
| shared_by_id | bigint FK | user who shared, optional |
| shared_at | datetime | optional |

Unique index on [client_id, issue_id].

### issue_people table (join)
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| issue_id | bigint FK | NOT NULL |
| person_id | bigint FK | NOT NULL |
| added_by_id | bigint FK | user, optional |

Unique index on [issue_id, person_id].

## 12. Indexing
1. issues: client_id, status, [client_id, status], tags (GIN).
2. client_issues: [client_id, issue_id] unique.
3. issue_people: [issue_id, person_id] unique.

---

## Frontend Spec

## 13. Screens

### Issue List (/issues)
- Card-per-issue layout with title, client name, status chip, and tags.
- Search bar (debounced) and status filter dropdown.
- "New Issue" button opens create dialog.
- Create dialog: title, description, notes, tags (combobox), client select.
- Edit dialog available inline (same form, client field hidden).
- Empty state with message when no issues match filters.

### Issue Detail (/issues/:id)
- Header: title, status chip, client name, tags.
- Status action buttons (Deactivate / Close / Reactivate) contextual on status.
- Edit button opens edit dialog.
- Description and Notes sections if present.
- Two tabs: People and Shared Clients.

#### People tab
- Autocomplete picker showing people not yet assigned (displays name, title, organization).
- Table with columns: Name, Title, Organization, Email, (Remove button).
- Remove button per row.
- Skeleton loaders during add/remove operations.

#### Shared Clients tab
- Autocomplete picker visible only to admins and managers.
- Table with columns: Client, Shared Date, (Unshare button).
- Primary client marked with chip; cannot be unshared.
- Unshare button visible only to admins and managers.

## 14. State Management
1. Issue store (Pinia) with:
- issues, currentIssue, isLoading, error
- fetchIssues(params), fetchIssue(id)
- createIssue, updateIssue
- closeIssue, deactivateIssue, reactivateIssue
- shareWithClient, unshareFromClient
- addPerson, removePerson

2. Filter state (search query, status) managed locally in component; not persisted across navigation.

## 15. UX Requirements
1. Status chip colors: active = green, inactive = amber, closed = grey.
2. Confirmation dialog before closing an issue; not required for deactivate.
3. Snackbar feedback on all create/update/status-change/error operations.
4. Empty state messages on People tab and Shared Clients tab when lists are empty.
5. Auto-refresh people picker and client picker after add/remove.

---

## Testing Spec

## 16. Backend Tests
1. Model tests:
- Title validations, status enum transitions, association integrity.
- Tags array default and acceptance.

2. Policy tests:
- Full role matrix (admin / staff / manager-own / manager-shared / unauthorized) for index, show, create, update, destroy, close, share, unshare.
- Scope test: managers see only their client's issues and shared issues.

3. Request tests:
- CRUD happy paths for all nine resource endpoints.
- Status transition paths: close, deactivate, reactivate.
- Share/unshare paths (including staff-denied and primary-remove 422).
- People add/remove paths.
- Unauthorized and forbidden paths.

## 17. Frontend Tests
1. Store tests:
- API success and error handling for each action.
- List mutation: prepend on create, in-place update, shared_clients sync, people sync.

2. Component tests (Issues.vue):
- Fetch on mount, skeleton loaders, card rendering.
- Search and status filter params passed to API.
- Create dialog success and error paths.
- Edit dialog sets form values and calls update.

3. E2E smoke (future):
- Create issue → assign person → share with client → close → reactivate flow.

---

## Non-Functional Requirements

## 18. Performance
1. Issue list first page renders under 500ms on typical dev dataset.
2. Pagination required once list exceeds threshold (25 per page default).
3. GIN index on tags supports array containment queries.

## 19. Security
1. Authentication required for all issue endpoints.
2. Pundit authorization checked on every action.
3. Share/unshare restricted to admin and manager at policy layer (not just UI).
4. Audit metadata (created_by, updated_by, closed_by) recorded on every mutating action.

## 20. Observability
1. Track events: issue created, updated, closed, deactivated, reactivated.
2. Track sharing events: client shared, client unshared.
3. Surface actionable error messages from API to UI snackbar.

---

## Definition of Done (1.2)
1. All issue CRUD and status-transition endpoints implemented with auth and policy.
2. People assignment endpoints implemented and tested.
3. Client sharing endpoints implemented and tested with role restrictions enforced.
4. Issue list and detail UI working end-to-end including People and Shared Clients tabs.
5. All backend specs passing (model, policy, request).
6. All frontend store and component tests passing.
7. Team can demo: create issue, assign people, share with a second client, close, and reactivate without errors.
