# Spec: 0.1 People Management Foundation

## 1. Objective
Establish a People foundation that supports internal users and external contacts, enables clean linkage between `person` and `user`, and prepares client/contact/staff assignment workflows.

## 2. Success Criteria
1. Team can create and manage people records for both users and non-users.
2. A person can be linked to a user account at creation time or later.
3. The system prevents duplicate user-to-person linkage.
4. Data model supports client, coalition, and legislative contact types.
5. Foundation is ready for assignment rules in client management flows.

## 3. In Scope (0.1 only)
1. `Person` model and CRUD API.
2. `Person <-> User` 0..1 to 1 mapping design and linkage rules.
3. Contact classification support (`client`, `coalition`, `legislative`).
4. Invite/claim-account foundation for creating a user from a person.
5. Baseline backend tests (model, request, service/policy as needed).

## 4. Out of Scope (for 0.1)
1. Full client assignment UX.
2. Matter, billing, and reporting integration.
3. Advanced dedupe/merge UI.
4. Bulk import tooling.
5. Notification preference center.

---

## Functional Requirements

## 5. Roles and Permissions
1. Admin:
- Full CRUD on people.
- Can link/unlink person-user mapping (subject to safety checks).
- Can send/resend/revoke account-claim invitations.

2. Staff:
- Full CRUD on people.
- Can send/resend account-claim invitations.
- Cannot perform destructive unlink actions unless policy allows.

3. All other authenticated roles:
- No access unless explicitly granted by policy.

4. Unauthorized user:
- Cannot access people endpoints.

## 6. Person Fields (MVP)
1. Required:
- First name
- Last name
- Display name
- Contact type (`client`, `coalition`, `legislative`, `staff`)
- Active status (`active`, `inactive`)

2. Optional:
- Email
- Phone
- Title
- Organization name
- Notes
- Linked user ID (nullable)

3. System fields:
- Created at / updated at
- Created by / updated by
- Deactivated at / deactivated by

## 7. Validation Rules
1. First and last name required, min length 1.
2. Display name required.
3. Contact type must be in allowed enum values.
4. Active status must be allowed enum value.
5. If linked user exists, `people.user_id` must be unique.
6. Soft-delete only; hard delete blocked in app logic.
7. Email format validation if email is present.

## 8. User Linkage Rules
1. A user can map to at most one person.
2. A person can map to at most one user.
3. New user signup should ensure a linked person record exists.
4. If a person later becomes a user, the existing person is linked to the new user (no duplicate person record).
5. Linking must be idempotent and audit-logged.

## 9. Invite and Claim Workflow
1. Create user from person:
- Staff/admin triggers invite from person detail.
- System creates one-time claim token with expiration.
- Email is sent to person email address.

2. Claim account:
- Recipient opens claim link.
- Sets password and confirms account.
- User record is linked to existing person record.

3. Safety checks:
- If target email already belongs to a user, prompt link/reconcile flow instead of duplicate user creation.
- Invitations can be revoked and resent.

---

## API Spec (MVP)

## 10. Endpoints
1. GET /people
- Supports filters: active status, contact_type, query
- Supports pagination: page, per_page

2. POST /people
- Creates person with required fields

3. GET /people/:id
- Returns full person detail if authorized

4. PATCH /people/:id
- Partial update

5. DELETE /people/:id
- Soft deactivate only

6. POST /people/:id/invite
- Sends claim-account invitation

7. POST /people/:id/link-user
- Links person to existing user (admin/staff policy controlled)

## 11. Response Shape
1. Use standard success/error envelope.
2. Return serialized person attributes.
3. Include useful capability flags (for example: can_invite, can_link_user).

---

## Data Model Spec

## 12. Entities
1. Person
- Identity and contact profile
- Optional `user_id` link
- Contact type classification

2. AccountClaimInvitation
- Person reference
- Email snapshot
- Secure token digest
- Expires at / claimed at / revoked at metadata

## 13. Indexing and Constraints
1. Index on normalized display name.
2. Index on contact type.
3. Index on active status.
4. Unique partial index on `people.user_id` where `user_id IS NOT NULL`.
5. Unique index on invitation token digest.

---

## Assignment Foundation (for 1.x)

## 14. Forward-Compatible Assignment Model
1. Client staff assignments reference `users` (staff always users).
2. Client/coalition/legislative contacts reference `people` (can be user or non-user).
3. Primary constraints planned for 1.x:
- Exactly one primary client staff per client.
- Exactly one primary contact per client per contact type.

---

## Testing Spec

## 15. Backend Tests
1. Model tests:
- Required fields and enums.
- One-to-one user linkage constraint.
- Soft-delete behavior.

2. Request tests:
- CRUD happy path.
- Unauthorized/forbidden paths.
- Filter and pagination behavior.

3. Service/policy tests:
- Invite token generation, expiration, revoke/claim rules.
- Link-user idempotency and duplicate prevention.

## 16. Definition of Done (0.1)
1. `Person` model, migration, and API endpoints are implemented.
2. User-person linkage constraints are enforced at DB and model levels.
3. Invite/claim foundation endpoints are implemented with policy checks.
4. Baseline backend tests are added and passing.
5. Spec and implementation are ready to plug into client assignment workflows in 1.x.
