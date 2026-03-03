# Rails Vue Project Template

A full-stack application with a **Rails API** backend, **Vue 3 + Vite** frontend, and a **FastAPI AI service** powered by CrewAI and GitHub Models.

## Services

| Service    | Port | Description                                      |
|------------|------|--------------------------------------------------|
| **backend**  | 3000 | Rails 8 API (Devise auth, Pundit authorization)  |
| **frontend** | 5173 | Vue 3 + Vite SPA                                 |
| **ai**       | 8000 | FastAPI service (CrewAI agents, GitHub Models)    |
| **db**       | 5432 | PostgreSQL                                        |

## Getting Started

### Prerequisites
- Docker & Docker Compose

### Setup
```bash
docker-compose build
docker-compose up
```

The backend is at http://localhost:3000, frontend at http://localhost:5173, and AI service at http://localhost:8000.

### Environment Variables

Copy and configure the AI service env file:
```bash
cp ai/.env.example ai/.env
```

Key variables:
| Variable | Required | Description |
|----------|----------|-------------|
| `GITHUB_TOKEN` | Yes | GitHub PAT for GitHub Models API |
| `GITHUB_MODELS_MODEL` | No | Model name (default: `gpt-4o`) |
| `GITHUB_MODELS_BASE` | No | API base URL (default: `https://models.github.ai/inference`) |

## Development

### Backend (Rails)
```bash
docker-compose run --rm backend bundle exec rails console
docker-compose run --rm backend bundle exec rails db:migrate
```

### Frontend (Vue + Vite)
```bash
docker-compose run --rm frontend yarn install
docker-compose run --rm frontend yarn dev
```

### AI Service (FastAPI)
```bash
docker-compose run --rm ai uvicorn app.main:app --reload --host 0.0.0.0
```

## Testing

### Backend (RSpec)
```bash
docker-compose run --rm backend bundle exec rspec
```

### Frontend (Jest + Playwright)
```bash
docker-compose run --rm frontend yarn test              # Jest unit tests
docker-compose run --rm frontend yarn e2e:coverage      # Playwright E2E
```

### AI Service (pytest)
```bash
docker-compose run --rm ai python -m pytest tests/ -v
```

Or locally:
```bash
cd ai
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
pytest tests/ -v
```

## AI Service Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET`  | `/up` | Health check |
| `POST` | `/ai/prompt` | Send a prompt to the general assistant crew |
| `GET`  | `/ai/ping-backend` | Verify connectivity to the Rails backend |
| `POST` | `/copilot/chat` | Chat completion via GitHub Models API |
| `POST` | `/crew/run` | Run the general assistant crew |
| `POST` | `/crew/research` | Run the research crew |

## Project Structure

```
├── backend/          # Rails API
├── frontend/         # Vue 3 + Vite SPA
├── ai/               # FastAPI AI service
│   ├── app/
│   │   ├── agents/   # CrewAI agent definitions
│   │   ├── crews/    # Crew assembly & orchestration
│   │   ├── routes/   # FastAPI route handlers
│   │   ├── services/ # LLM client, Copilot client
│   │   ├── tasks/    # CrewAI task factories
│   │   └── tools/    # CrewAI tools (backend integration)
│   └── tests/        # pytest test suite
└── docker-compose.yml
```