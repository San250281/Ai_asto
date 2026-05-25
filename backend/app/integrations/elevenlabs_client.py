from typing import AsyncGenerator, Optional

import httpx

from app.config import get_settings

settings = get_settings()

ELEVENLABS_BASE = "https://api.elevenlabs.io/v1"


class ElevenLabsClient:
    def __init__(self) -> None:
        self.api_key = settings.elevenlabs_api_key
        self.voice_id = settings.elevenlabs_voice_id
        self.model = settings.elevenlabs_model

    async def text_to_speech(self, text: str) -> bytes:
        url = f"{ELEVENLABS_BASE}/text-to-speech/{self.voice_id}"
        headers = {
            "xi-api-key": self.api_key,
            "Content-Type": "application/json",
        }
        payload = {
            "text": text,
            "model_id": self.model,
            "voice_settings": {
                "stability": 0.65,
                "similarity_boost": 0.85,
                "style": 0.45,
                "use_speaker_boost": True,
            },
        }
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(url, json=payload, headers=headers)
            response.raise_for_status()
            return response.content

    async def stream_text_to_speech(self, text: str) -> AsyncGenerator[bytes, None]:
        url = f"{ELEVENLABS_BASE}/text-to-speech/{self.voice_id}/stream"
        headers = {
            "xi-api-key": self.api_key,
            "Content-Type": "application/json",
        }
        payload = {
            "text": text,
            "model_id": self.model,
            "voice_settings": {
                "stability": 0.65,
                "similarity_boost": 0.85,
                "style": 0.45,
            },
        }
        async with httpx.AsyncClient(timeout=120.0) as client:
            async with client.stream("POST", url, json=payload, headers=headers) as resp:
                resp.raise_for_status()
                async for chunk in resp.aiter_bytes(chunk_size=4096):
                    yield chunk


_elevenlabs: Optional[ElevenLabsClient] = None


def get_elevenlabs_client() -> ElevenLabsClient:
    global _elevenlabs
    if _elevenlabs is None:
        _elevenlabs = ElevenLabsClient()
    return _elevenlabs
