# Spec: 1.1 Client Management (Minnesota-First)

## 1. Objective
Build a client system that replaces spreadsheets immediately and becomes the anchor for all matter, contact, bill, activity, and reporting workflows.

## 2. Success Criteria
1. Staff can create, view, update, and deactivate clients in under 2 minutes per client.
2. Every downstream record can be scoped to a client (starting now with matters in 1.2).
3. Users can quickly find clients by name/status.
4. Deactivated clients are hidden by default but recoverable.
5. Permissions prevent unauthorized access across accounts.

## 3. In Scope (1.1 only)
1. Client data model and CRUD API.
2. Client list and client detail/edit UI.
3. Soft deactivate/reactivate flow.
4. Search/filter/sort on client list.
5. Audit-friendly timestamps and created/updated by fields.
6. Baseline tests (model, policy, request, store/component).

## 4. Out of Scope (for 1.1)
1. Matter creation and bill linking.
2. Contact records tied to clients.
3. Compliance logic.
4. Reporting and AI drafting from client context.
5. Multi-state architecture.

---

## Functional Requirements

## 5. Roles and Permissions
1. Admin:
- Full CRUD on all clients.
- Can deactivate/reactivate any client.

2. Staff:
- Full CRUD on all clients.
- Can deactivate/reactivate any client.

3. All other authenticated roles:
- No client access unless explicitly granted by policy.

4. Unauthorized user:
- Cannot access client endpoints.

## 6. Client Fields (MVP)
1. Required:
- Legal name
- Display name
- Status (active, inactive)

2. System fields:
- Created at / updated at
- Created by / updated by
- Deactivated at / deactivated by

## 7. Validation Rules
1. Legal name required, min length 2.
2. Display name required.
3. Status must be one of allowed enum values.
4. Soft-delete only; hard delete blocked in app logic.
5. Prevent duplicate active client names (case-insensitive).

## 8. Core Workflows
1. Create client:
- User enters required fields.
- Success returns client summary and navigates to detail.

2. Edit client:
- Inline or form-based update for profile fields.
- Save shows updated timestamp and editor.

3. Deactivate client:
- Confirmation modal required.
- Client removed from default lists.
- Existing associations remain intact.

4. Reactivate client:
- Available from inactive filter/detail page.
- Restores client to active lists.

5. Search/filter:
- Search by legal/display name.
- Filter by status.
- Sort by updated date (default desc), name asc.

---

## API Spec (MVP)

## 9. Endpoints
1. GET /clients
- Supports filters: status, query
- Supports pagination: page, per_page
- Default: active clients only

2. POST /clients
- Creates client with required fields
- Returns normalized client payload

3. GET /clients/:id
- Returns full client detail if authorized

4. PATCH /clients/:id
- Partial update
- Policy-checked by field permissions

5. DELETE /clients/:id
- Soft deactivate only (status change + deactivated metadata)

6. POST /clients/:id/reactivate
- Reactivates inactive client

## 10. Response Shape
1. Use existing standard success/error envelope.
2. Return serialized client attributes (not raw model internals).
3. Include permission flags in payload if useful for UI (can_edit, can_deactivate).

---

## Data Model Spec

## 11. Entities
1. Client
- Core profile fields
- Status enum
- Soft-deactivate metadata

## 12. Indexing
1. Index on normalized legal name.
2. Index on status.
3. Composite index on status + updated_at for list performance.
4. Optional trigram/full-text later if search grows.

---

## Frontend Spec

## 13. Screens
1. Client List:
- Table/list view
- Search bar, status filter
- Quick create button
- Active/inactive toggle

2. Client Create/Edit:
- Single form with validation and clear required markers

3. Client Detail:
- Readable profile card
- Activity placeholder section (future)
- Deactivate/reactivate actions

## 14. State Management
1. Client store with:
- clients, currentClient, isLoading, error
- fetchClients, createClient, updateClient, deactivateClient, reactivateClient

2. Persist filter and sort state in URL query params for shareable views.

## 15. UX Requirements
1. Form errors shown inline and at top summary.
2. Confirmation dialog for deactivation/reactivation.
3. Empty state with CTA for first client creation.
4. Mobile-safe layout for list and detail.

---

## Testing Spec

## 16. Backend Tests
1. Model tests:
- Validations, status transitions, duplicate prevention.

2. Policy tests:
- Admin/staff/other-role access matrix for each action.

3. Request tests:
- CRUD happy path
- Unauthorized/forbidden paths
- Filtering and pagination behavior
- Soft-delete/reactivation behavior

## 17. Frontend Tests
1. Store tests:
- API success/error handling
- List filter state behavior
- Mutation updates

2. Component tests:
- Create/edit form validation
- List filtering
- Deactivate confirmation behavior

3. E2E smoke:
- Create client -> edit -> deactivate -> reactivate flow.

---

## Non-Functional Requirements

## 18. Performance
1. Client list should render first page in under 500ms on typical local/dev dataset.
2. Pagination required once list exceeds threshold (for example, 25 per page default).

## 19. Security
1. Auth required for all client endpoints.
2. Authorization checks on every action.
3. Audit metadata required for updates and status changes.

## 20. Observability
1. Track events: client created, updated, deactivated, reactivated.
2. Capture endpoint errors with actionable messages for support.

---

## Definition of Done (1.1)
1. All client CRUD endpoints implemented with auth + policy.
2. Client list/detail/create/edit UI working end-to-end.
3. Soft deactivate/reactivate complete.
4. Tests added and passing for backend and frontend coverage listed above.
5. Team can demo: create and manage 10+ clients without spreadsheet fallback.