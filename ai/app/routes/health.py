from fastapi import APIRouter

router = APIRouter()


@router.get("/up")
async def health_check():
    """Health-check endpoint (mirrors the Rails /up convention)."""
    return {"status": "ok"}
