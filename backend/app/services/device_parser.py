import re

from app.schemas.live import DeviceInfo, DeviceList


ANSI_RE = re.compile(r"\x1b\[[0-9;]*m")
DEVICE_RE = re.compile(r"^\s*(?P<id>\d+):\s*(?P<tag>adc|dac)\d*\s*(?P<rest>.*)$")
CHANNEL_RE = re.compile(r"\[ch:(?P<channels>\d+)\]")
IO_RE = re.compile(r"\[(?:[^,\]]+),\s*(?P<inputs>\d+)\s+in,\s*(?P<outputs>\d+)\s+out\]")


def parse_csound_devices(text: str) -> DeviceList:
    """Convert Csound's stderr device listing into stable API objects."""

    inputs: list[DeviceInfo] = []
    outputs: list[DeviceInfo] = []

    for raw_line in text.splitlines():
        clean_line = ANSI_RE.sub("", raw_line)
        match = DEVICE_RE.match(clean_line)
        if not match:
            continue

        device_id = int(match.group("id"))
        tag = match.group("tag")
        name = _human_name(match.group("rest"))
        kind = "input" if tag == "adc" else "output"
        channels = _channel_count(match.group("rest"), kind)
        device = DeviceInfo(
            id=device_id,
            label=f"{device_id}: {name}",
            name=name,
            channels=channels,
            kind=kind,
            raw=clean_line.strip(),
        )

        if kind == "input":
            inputs.append(device)
        else:
            outputs.append(device)

    return DeviceList(inputs=inputs, outputs=outputs)


def _human_name(raw: str) -> str:
    """Prefer the readable device name inside Csound's parenthesized metadata."""

    text = raw.strip()
    if "(" in text:
        text = text.split("(", 1)[1]
    if "[" in text:
        text = text.split("[", 1)[0]
    text = text.strip(" )")
    return text or "Default Device"


def _channel_count(raw: str, kind: str) -> int:
    """Read Csound's channel metadata so launches can match device widths."""

    channel_match = CHANNEL_RE.search(raw)
    if channel_match:
        return int(channel_match.group("channels"))

    io_match = IO_RE.search(raw)
    if io_match:
        key = "inputs" if kind == "input" else "outputs"
        return int(io_match.group(key))

    return 2
