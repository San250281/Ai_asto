from typing import AsyncGenerator, Optional

from openai import AsyncOpenAI

from app.config import get_settings

settings = get_settings()


class OpenAIClient:
    def __init__(self) -> None:
        self.client = AsyncOpenAI(api_key=settings.openai_api_key)
        self.model = settings.openai_model
        self.max_tokens = settings.openai_max_tokens

    async def chat_completion(
        self,
        messages: list[dict],
        temperature: float = 0.8,
        stream: bool = False,
    ):
        return await self.client.chat.completions.create(
            model=self.model,
            messages=messages,
            max_tokens=self.max_tokens,
            temperature=temperature,
            stream=stream,
        )

    async def stream_chat(
        self, messages: list[dict]
    ) -> AsyncGenerator[str, None]:
        stream = await self.chat_completion(messages, stream=True)
        async for chunk in stream:
            if chunk.choices and chunk.choices[0].delta.content:
                yield chunk.choices[0].delta.content

    async def transcribe_audio(self, audio_bytes: bytes, language: str = "hi") -> str:
        import io

        audio_file = io.BytesIO(audio_bytes)
        audio_file.name = "audio.webm"
        response = await self.client.audio.transcriptions.create(
            model=settings.whisper_model,
            file=audio_file,
            language=language[:2] if language != "hinglish" else "hi",
        )
        return response.text


_openai_client: Optional[OpenAIClient] = None


def get_openai_client() -> OpenAIClient:
    global _openai_client
    if _openai_client is None:
        _openai_client = OpenAIClient()
    return _openai_client
