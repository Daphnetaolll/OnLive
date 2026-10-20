from __future__ import annotations

from dataclasses import dataclass

from app.core.paths import CSOUND_CSD_PATH
from app.schemas.live import EffectCodeSnippet


@dataclass(frozen=True)
class EffectCodeRegion:
    effect_id: str
    title: str
    start_marker: str
    end_marker: str


# Regions are found by marker text, not line numbers, so edits elsewhere in on_live.csd never
# shift a snippet. The start marker is the effect's title comment at column 0 of the Live
# instrument; the end marker is the line that writes the effect back onto aSigR.
EFFECT_CODE_REGIONS = (
    EffectCodeRegion("pitch", "Pitch Shifter", ";Pitch Shift Effect", "aSigR = (aPitchMixR"),
    EffectCodeRegion("ring", "Ring Mod", ";Ringmod", "aSigR = (aRingMixR"),
    EffectCodeRegion("blur", "Blur", "; 3) Blur", "aSigR = (aBlurMixR"),
    EffectCodeRegion("flanger", "Flanger", ";Flanger", "aSigR = (aFlMixR"),
    EffectCodeRegion("ats", "ATS Cross", ";ATS Cross spectral layer", "aSigR = (aAtsMixR"),
)


def list_effect_code_snippets() -> list[EffectCodeSnippet]:
    """Read current Csound effect regions so the UI teaches from the live DSP file."""

    lines = CSOUND_CSD_PATH.read_text(encoding="utf-8").splitlines()
    snippets: list[EffectCodeSnippet] = []
    for region in EFFECT_CODE_REGIONS:
        start_line, end_line = _region_lines(lines, region)
        numbered_lines = [
            f"{line_number:>4}  {line}"
            for line_number, line in enumerate(lines[start_line - 1 : end_line], start=start_line)
        ]
        snippets.append(
            EffectCodeSnippet(
                effect_id=region.effect_id,
                title=region.title,
                source_path=str(CSOUND_CSD_PATH),
                start_line=start_line,
                end_line=end_line,
                code="\n".join(numbered_lines),
            )
        )
    return snippets


def _region_lines(lines: list[str], region: EffectCodeRegion) -> tuple[int, int]:
    """Return the 1-based, inclusive line range of one effect module."""

    start_index = next((index for index, line in enumerate(lines) if line.rstrip() == region.start_marker), None)
    if start_index is None:
        raise ValueError(f"Could not find the {region.title} block ({region.start_marker!r}) in {CSOUND_CSD_PATH.name}.")
    end_index = next((index for index in range(start_index, len(lines)) if region.end_marker in lines[index]), None)
    if end_index is None:
        raise ValueError(f"Could not find the end of the {region.title} block in {CSOUND_CSD_PATH.name}.")
    # Keep the "; ____" divider drawn above each module title in the .csd.
    if start_index > 0 and lines[start_index - 1].startswith("; ___"):
        start_index -= 1
    return start_index + 1, end_index + 1
