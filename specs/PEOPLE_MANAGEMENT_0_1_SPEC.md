# Spec: 0.1 People Management Foundation

## Status: Implemented

## 1. Objective
Establish a People foundation that supports internal users and external contacts, enables clean linkage between `person` and `user`, and prepares client/contact/staff assignment workflows.

## 2. Success Criteria
1. Team can create and manage people records.
2. Regular users are prompted to create their own person record on first login (account setup flow).
3. A person can be linked to a user account at creation time.
4. The system prevents duplicate user-to-person linkage.
5. Foundation is ready for assignment rules in client management flows.

## 3. In Scope (0.1 only)
1. `Person` model and CRUD API.
2. `Person <-> User` 0..1 to 1 mapping and linkage rules.
3. Self-service account setup flow: regular users prompted to create their linked person on first login.
4. Frontend People management view (list, create, edit, deactivate).
5. Baseline backend and frontend tests (model, policy, request, store, component, router).

## 4. Out of Scope (for 0.1)
1. Contact classification (`client`, `coalition`, `legislative`) — deferred to 1.x.
2. Invite/claim-account workflow (creating a user from a person record) — deferred.
3. Manual admin link/unlink of existing person-to-user — deferred.
4. Full client assignment UX.
5. Matter, billing, and reporting integration.
6. Advanced dedupe/merge UI.
7. Bulk import tooling.
8. Notification preference center.

---

## Functional Requirements

## 5. Roles and Permissions
1. Admin:
- Full CRUD on all people.
- Can deactivate/reactivate any person.
- Bypasses account setup redirect.
- `User#admin?` returns true when user has the `admin` role.

2. Staff:
- Full CRUD on all people.
- Can deactivate/reactivate any person.
- Bypasses account setup redirect.
- `User#staff?` returns true when user has the `staff` role.

3. Regular authenticated user:
- Cannot view or manage other people's records.
- Can create exactly one person linked to their own account (self-service account setup).
- Email and user association are auto-assigned by the server on create; client-supplied values are ignored.
- Redirected to `/account-setup` on every navigation until a linked person exists.

4. System user (`system_user: true`):
- Bypasses account setup redirect.
- Not subject to the person requirement.

5. Unauthorized user:
- Cannot access people endpoints.

## 6. Person Fields (MVP)
1. Required:
- First name
- Last name
- Display name

2. Optional:
- Email
- Phone
- Title
- Organization name
- Notes

3. User linkage:
- `user_id` (nullable, unique when present)
- One person maps to at most one user; one user maps to at most one person.
- Set automatically when a regular user completes account setup.
- Email is also auto-assigned from the linked user's email on create (regular users).

4. System fields:
- Created at / updated at
- Created by / updated by
- Discarded at (`discarded_at`) — used for soft deactivation.

## 7. Validation Rules
1. First and last name required, min length 1.
2. Display name required.
3. `user_id` must be unique across all people when present.
4. Soft-delete only via `discard`; hard delete blocked in app logic.
5. Email format validation when email is present.

## 8. User Linkage and Account Setup Rules
1. A user can be linked to at most one person; a person can be linked to at most one user.
2. Regular users who have no linked person are redirected to `/account-setup` by the global router guard on every navigation, until they complete setup.
3. The following are exempt from the account setup redirect: admin users, staff users, system users, unauthenticated users, and routes listed in `SETUP_EXEMPT_ROUTES` (login, signup, account-setup, password flows, confirmation).
4. On POST /people, the server sets `person.user` and `person.email` automatically for regular users — client-supplied values for those fields are ignored.
5. After successful account setup, the frontend calls `userStore.setPersonId(id)`, which persists `person_id` to the user object in localStorage and updates `hasPerson`.
6. `UserStore` exposes: `hasPerson` (computed), `isSystemUser` (computed), `setPersonId(id)` action.

---

## API Spec (MVP)

## 9. Endpoints
1. GET /people
- Admin/staff only.
- Supports filters: `discarded` (true/false), `query` (name search).
- Supports pagination: `page`, `per_page`.
- Default: active (kept) people only.

2. POST /people
- Admin/staff create freely.
- Regular users can create exactly one person linked to themselves (account setup).

3. GET /people/:id
- Admin/staff see any; regular users see their own linked person only.

4. PATCH /people/:id
- Admin/staff update any; regular users update their own linked person only.

5. DELETE /people/:id
- Soft deactivate (sets `discarded_at`). Admin/staff only.

## 10. Response Shape
1. Use standard `render_success` / `render_error` envelope.
2. Return serialized person attributes (not raw model).
3. `UserSerializer` includes `person_id` and `system_user` fields so the frontend can bootstrap account setup state.

---

## Data Model Spec

## 11. Entities
1. Person
- Identity and contact profile fields.
- Optional `user_id` foreign key (unique, nullable).
- Soft-delete via `discarded_at` (`Discard::Model`).
- `created_by` / `updated_by` user references.

## 12. Indexing and Constraints
1. Index on display name.
2. Index on `discarded_at` for active/inactive filtering.
3. Unique partial index on `people.user_id` where `user_id IS NOT NULL`.

---

## Frontend Spec

## 13. Screens
1. People List (admin/staff):
- Card list with search and active/inactive toggle.
- Deactivate action with confirmation dialog.
- Deactivated label shown inline on inactive people.

2. Account Setup (`/account-setup`):
- Shown to regular users on first login if `hasPerson` is false.
- Uses shared `PersonForm` component.
- On success, calls `userStore.setPersonId()` and navigates to Dashboard.

## 14. State Management
1. `UserStore` (Pinia):
- `user` — persisted to localStorage.
- `hasPerson` — computed from `user.person_id`.
- `isSystemUser` — computed from `user.system_user`.
- `setPersonId(id)` — patches `user.person_id` in store and localStorage.

## 15. Routing
1. Global `beforeEach` guard redirects authenticated regular users without a person to `/account-setup`.
2. Exempt routes: Login, Signup, AccountSetup, Confirmation, PasswordReset, PasswordEdit.
3. Admin, staff, and system users pass through without redirect regardless of `person_id`.

---

## Assignment Foundation (for 1.x)

## 16. Forward-Compatible Assignment Model
1. Client staff assignments reference `users` (staff always users).
2. Client/coalition/legislative contacts will reference `people` (can be user or non-user).
3. Primary constraints planned for 1.x:
- Exactly one primary client staff per client.
- Exactly one primary contact per client per contact type.

---

## Testing Spec

## 17. Backend Tests
1. Model tests:
- `User#admin?` and `User#staff?` based on assigned roles.
- Soft-delete and `active_for_authentication?` behavior.

2. Policy tests:
- Admin can index, show, create, update, destroy people.
- Staff can index, show, create, update, destroy people.
- Regular user denied index; can create own person (policy `create?` allows when `record.user == user`).
- `PersonPolicy::Scope` returns all for admin/staff, none otherwise.

3. Request tests:
- CRUD happy paths for admin.
- Unauthorized (no token) and forbidden (wrong role) paths.
- Filter by `discarded`, pagination.
- `GET /users` response includes `system_user` and `person_id` fields.
- System users appear in the users list.
- `POST /people` by a regular user auto-assigns email from current user.

## 18. Frontend Tests
1. `UserStore`: `hasPerson`, `isSystemUser`, `setPersonId`.
2. `AccountSetup.vue`: renders form; POSTs to `/people`; calls `setPersonId`; navigates to Dashboard; shows snackbar on error.
3. `AddUserRole.vue`: fetches users on mount; filters out existing/discarded; no-op guard; PATCHes; success snackbar + emit; error snackbar.
4. Router global guard: all 6 exemption cases (admin, staff, system, has-person, unauthenticated, exempt-route).

## 19. Definition of Done (0.1)
1. ✅ `Person` model, migration, and API endpoints implemented.
2. ✅ User-person linkage constraints enforced at DB and model levels.
3. ✅ Self-service account setup flow implemented (frontend redirect + backend auto-assign).
4. ✅ `User#staff?` method added alongside `User#admin?`.
5. ✅ `UserSerializer` exposes `person_id` and `system_user`.
6. ✅ `PersonPolicy` and `UserPolicy::Scope` enforce access rules.
7. ✅ Backend: 222 examples, 0 failures.
8. ✅ Frontend: 177 tests, 0 failures.
9. ✅ Foundation ready to plug into client assignment workflows in 1.x.
