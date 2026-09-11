from pathlib import Path


# Resolve important project paths from the backend package location.
APP_DIR = Path(__file__).resolve().parents[1]
BACKEND_DIR = APP_DIR.parent
PROJECT_ROOT = BACKEND_DIR.parent
DSP_DIR = APP_DIR / "dsp"
CSOUND_CSD_PATH = DSP_DIR / "on_live.csd"
ATS_CROSS_DIR = DSP_DIR / "ats_cross"
STORAGE_DIR = BACKEND_DIR / "storage"
SAMPLE_STORAGE_DIR = STORAGE_DIR / "live_samples"
