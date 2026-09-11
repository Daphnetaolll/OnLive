from pydantic import BaseModel


class Settings(BaseModel):
    """Runtime settings that keep local dev and Docker deployment predictable."""

    app_name: str = "OnLive 音 API"
    osc_host: str = "127.0.0.1"
    osc_port: int = 7777
    telemetry_port: int = 7778
    cors_origins: tuple[str, ...] = (
        "http://localhost:5173",
        "http://127.0.0.1:5173",
        "http://localhost:8080",
        "http://127.0.0.1:8080",
    )


settings = Settings()
