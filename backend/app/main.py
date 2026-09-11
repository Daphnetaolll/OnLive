from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes_health import router as health_router
from app.api.routes_live import router as live_router
from app.core.config import settings
from app.services.csound_engine import engine
from app.services.telemetry import telemetry


@asynccontextmanager
async def lifespan(_: FastAPI):
    """Own the realtime Csound helpers for the FastAPI process lifetime."""

    telemetry.start()
    try:
        yield
    finally:
        engine.shutdown()
        telemetry.stop()


app = FastAPI(title=settings.app_name, lifespan=lifespan)

# Allow the Vite dev server and Docker frontend to call the local API.
app.add_middleware(
    CORSMiddleware,
    allow_origins=list(settings.cors_origins),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health_router, prefix="/api")
app.include_router(live_router, prefix="/api")
