import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routes import health, ai, copilot, crew

BACKEND_URL = os.getenv("BACKEND_URL", "http://backend:3000")

app = FastAPI(title="AI Service", version="0.1.0")

# CORS – allow the Rails backend (and local dev) to call this service
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        BACKEND_URL,
        "http://localhost:3000",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router)
app.include_router(ai.router, prefix="/ai", tags=["ai"])
app.include_router(copilot.router, prefix="/copilot", tags=["copilot"])
app.include_router(crew.router, prefix="/crew", tags=["crew"])
