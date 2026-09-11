from __future__ import annotations

from dataclasses import dataclass

from app.core.paths import CSOUND_CSD_PATH
from app.schemas.live import EffectCodeSnippet


@dataclass(frozen=True)
class EffectCodeRegion:
    effect_id: str
    title: str
    start_line: int
    end_line: int


# These line ranges point at the actual effect modules inside on_live.csd.
EFFECT_CODE_REGIONS = (
    EffectCodeRegion("pitch", "Pitch Shifter", 1072, 1107),
    EffectCodeRegion("ring", "Ring Mod", 1109, 1133),
    EffectCodeRegion("blur", "Blur", 1136, 1188),
    EffectCodeRegion("flanger", "Flanger", 1190, 1227),
    EffectCodeRegion("ats", "ATS Cross", 1229, 1269),
)


def list_effect_code_snippets() -> list[EffectCodeSnippet]:
    """Read current Csound effect regions so the UI teaches from the live DSP file."""

    lines = CSOUND_CSD_PATH.read_text(encoding="utf-8").splitlines()
    snippets: list[EffectCodeSnippet] = []
    for region in EFFECT_CODE_REGIONS:
        start_index = max(0, region.start_line - 1)
        end_index = min(len(lines), region.end_line)
        numbered_lines = [
            f"{line_number:>4}  {line}"
            for line_number, line in enumerate(lines[start_index:end_index], start=region.start_line)
        ]
        snippets.append(
            EffectCodeSnippet(
                effect_id=region.effect_id,
                title=region.title,
                source_path=str(CSOUND_CSD_PATH),
                start_line=region.start_line,
                end_line=region.end_line,
                code="\n".join(numbered_lines),
            )
        )
    return snippets
