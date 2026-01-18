## Quick orientation (why this repo is laid out this way)
- This is a Rails API backend with a Vue 3 + Vite frontend in the same repo (backend/ and frontend/).
- The app uses Devise for auth, Pundit for authorization, JSONAPI::Serializer for payload shaping, and a refresh-token flow implemented under `backend/app/models` and `backend/app/controllers/users/refresh_tokens_controller.rb` (see `config/routes.rb`).
- Docker Compose is the primary convenience for local development: it brings up Postgres, the Rails backend (port 3000) and the Vite frontend (port 5173).

## Key patterns and files for code completion and edits
- Auth and claims: `backend/app/services/jwt_claims_service.rb` builds JWT claims; Devise controllers are customized under `backend/app/controllers/users/`.
- Authorization: controllers call `authorize` and `policy_scope` (Pundit). See `backend/app/controllers/application_controller.rb` for the standardized `render_success` / `render_error` helpers.
- Serializers: `backend/app/serializers/*_serializer.rb` use `JSONAPI::Serializer`. Controllers commonly extract the attributes via `serializer.serializable_hash[:data][:attributes]` before returning JSON (see `users_controller.rb`, `roles_controller.rb`).
- Params convention: controllers use `params.expect(...)` for nested shapes instead of the more common `params.require(...).permit(...)` pattern. Follow existing usages when generating parameter handling.
- Soft deletes: models use `discard`/`discarded_at` semantics (e.g., Users), so prefer deactivation flows over hard deletes when adding features.

## Run / dev workflows (concrete commands found in the repo)
- Fastest (recommended): use Docker Compose from repo root
  - docker-compose build
  - docker-compose up
  - Backend: http://localhost:3000
  - Frontend: http://localhost:5173
- Frontend direct (Vite):
  - cd frontend
  - yarn install
  - yarn dev    # starts Vite on 5173 (package.json has `dev`, `build`, `preview`)

## API & integration notes an agent should follow
- Consistent response shape: controllers use `render_success` and `render_error` to return {status, message, data, errors}. Keep that shape when adding endpoints or editing responses.
- Serialization: return serializer attributes (not entire model). Example: `UserSerializer.new(@user).serializable_hash[:data][:attributes]`.
- Authorization hooks: always call `authorize` or `policy_scope` when adding or querying protected resources. Missing Pundit calls will break tests and cause 403s.
- JWT / Refresh tokens: refresh endpoint exists at `POST /users/refresh-token` (see `config/routes.rb`); look for `refresh_token` model and controller when altering auth flows.

## Files to inspect when changing behavior
- Authentication and session flows: `backend/app/controllers/users/*` and `backend/app/services/jwt_claims_service.rb`
- Permissions and policies: `backend/app/policies/*_policy.rb`
- Serialization and API surface: `backend/app/serializers/*.rb` and controllers in `backend/app/controllers`
- DB migrations: `db/migrate/*` and `db/schema.rb` — check for columns like `jti`, `discarded_at`, and Devise fields before changing user model behavior.
- Frontend API clients: `frontend/src/services` (search for `axios` usage) and `frontend/src/stores` for how auth state is stored and refreshed.

## Small concrete examples an agent can use
- To add an authenticated JSON endpoint:
  1. Add route in `config/routes.rb` under appropriate resource/namespace.
  2. Implement controller action in `backend/app/controllers` using `before_action :authenticate_user!`.
  3. Use `authorize` and `policy_scope` from Pundit.
  4. Return payload with `render_success(data: { foo: FooSerializer.new(obj).serializable_hash[:data][:attributes] })`.

## Conventions and gotchas
- Param parsing: controllers typically use `params.expect(...)` — match that when producing parameter handling code.
- JSONAPI::Serializer is used but controllers intentionally unwrap the `:attributes` for simpler payloads.
- Use `discard` for deactivation rather than `destroy` for User records.
- Health endpoint: GET /up is present — useful for monitoring and smoke tests.

## Where to run tests & what to expect
- Rails tests live in `test/` (standard Minitest layout). Use the project's test helper at `test/test_helper.rb` to run tests.
- If you change authorization or serialization behavior, update tests for controllers and serializers.

---
If any piece of this guide is unclear or you want me to expand any section (examples for adding a controller, writing a policy, or adding a frontend API client), tell me which area and I'll iterate.
