from pythonosc.udp_client import SimpleUDPClient


class OscClient:
    """Small wrapper around python-osc so the engine has one sending surface."""

    def __init__(self, host: str, port: int) -> None:
        self._client = SimpleUDPClient(host, port)

    def send(self, path: str, value: float | int | bool) -> None:
        payload = int(value) if isinstance(value, bool) else value
        self._client.send_message(path, payload)

    def send_many(self, path: str, values: list[float | int | bool]) -> None:
        payload = [int(value) if isinstance(value, bool) else value for value in values]
        self._client.send_message(path, payload)
