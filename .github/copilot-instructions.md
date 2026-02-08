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

## Test suites and running tests

### Backend (Rails + RSpec)
- Framework: RSpec 6.0 with Rails integration (`rspec-rails`)
- Test structure: `backend/spec/` organized by type (controllers, models, policies, requests, services, validators, support, factories)
- Factory setup: FactoryBot (`factory_bot_rails`) with factories in `backend/spec/factories/`
- Coverage: SimpleCov configured to track test coverage
- Run all tests: `docker compose run --rm backend bundle exec rspec` or locally `bundle exec rspec`
- Run specific suite: `bundle exec rspec spec/controllers/` or `bundle exec rspec spec/policies/`
- Run with coverage: `bundle exec rspec --require spec_helper --format progress` (SimpleCov will generate reports in `coverage/`)
- Key test files to maintain:
  - `spec/controllers/*_spec.rb` — verify authorization, response shape, and Pundit integration
  - `spec/policies/*_policy_spec.rb` — test Pundit rules (index, show, create, update, destroy, etc.)
  - `spec/services/*.rb` — test JWT claims, serialization, and business logic
  - `spec/models/*.rb` — test model validations and associations

### Frontend (Jest + Playwright)
- Unit tests: Jest configured with Vue Test Utils and Babel
- E2E tests: Playwright with coverage instrumentation
- Test commands (run from repo root with docker-compose):
  - `docker compose run --rm frontend yarn test` — run Jest unit tests
  - `docker compose run --rm frontend yarn test:coverage` — run Jest with coverage report
  - `docker compose run --rm frontend yarn e2e:coverage` — build coverage-instrumented app and run Playwright tests
  - `docker compose run --rm frontend yarn e2e:coverage-dev` — dev mode for Playwright (serves app and runs tests)
- Coverage reports: `frontend/coverage/` (Jest) and `frontend/coverage/lcov-report/` (merged)
- Playwright config: `frontend/playwright/playwright.config.cjs` 
- Test locations: `frontend/tests/unit/` and `frontend/tests/e2e/`
- Key test areas:
  - Components: store interactions, props, emitted events, API calls (use `vi.mock('axios')`)
  - Stores (Pinia): state mutations, actions, auth token refresh
  - Router: navigation guards, protected routes
  - Services: API call formatting, error handling

### Test database and isolation
- Backend: RSpec uses transaction rollback for test isolation (configured in `spec/spec_helper.rb` and `spec/rails_helper.rb`)
- Database state: tests are isolated per spec file; use `FactoryBot.create()` to set up records in a clean state
- Seeding: `backend/db/seeds.rb` can be run manually but is not part of standard test flow

### When to update tests
- Add a new controller action → add request spec to `spec/requests/`
- Change Pundit authorization → update `spec/policies/*_policy_spec.rb`
- Modify serialization → verify serializer spec or controller response shape in controller specs
- Update frontend state (auth, UI) → add or update Jest test or Playwright scenario
- Soft delete behavior → test `:discard`, `:discarded?`, and `:kept` scopes in model specs

---
If any piece of this guide is unclear or you want me to expand any section (examples for adding a controller, writing a policy, or adding a frontend API client), tell me which area and I'll iterate.
