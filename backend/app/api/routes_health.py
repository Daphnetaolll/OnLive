import shutil
import subprocess

from fastapi import APIRouter

from app.core.paths import CSOUND_CSD_PATH
from app.schemas.live import HealthStatus


router = APIRouter(prefix="/health", tags=["health"])


@router.get("", response_model=HealthStatus)
def health() -> HealthStatus:
    """Report whether local Live Mode dependencies are visible to the backend."""

    csound_binary = shutil.which("csound")
    version = None
    if csound_binary:
        result = subprocess.run(
            ["csound", "--version"],
            capture_output=True,
            text=True,
            check=False,
        )
        version = (result.stdout or result.stderr).splitlines()[0] if (result.stdout or result.stderr) else None

    return HealthStatus(
        api="ok",
        csound_binary=csound_binary,
        csound_version=version,
        csd_exists=CSOUND_CSD_PATH.exists(),
        csd_path=str(CSOUND_CSD_PATH),
    )
