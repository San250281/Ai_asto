import base64
import uuid
from typing import Optional

from sqlalchemy.ext.asyncio import AsyncSession

from app.integrations.elevenlabs_client import get_elevenlabs_client
from app.integrations.openai_client import get_openai_client
from app.models.user import User
from app.models.voice import VoiceLog
from app.services.ai_astrologer import AIAstrologerService


class VoiceService:
    def __init__(self) -> None:
        self.openai = get_openai_client()
        self.elevenlabs = get_elevenlabs_client()
        self.astrologer = AIAstrologerService()

    async def process_voice_chat(
        self,
        db: AsyncSession,
        user: User,
        audio_bytes: bytes,
        language: str = "hindi",
        session_id: Optional[uuid.UUID] = None,
        include_greeting: bool = False,
    ) -> dict:
        lang_code = "hi" if language in ("hindi", "hinglish") else "en"
        transcript = await self.openai.transcribe_audio(audio_bytes, lang_code)

        ai_response, session_id = await self.astrologer.chat(
            db, user, transcript, language, session_id
        )

        if include_greeting:
            greeting = self.astrologer.get_greeting(language)
            ai_response = f"{greeting}\n\n{ai_response}"

        audio_output = await self.elevenlabs.text_to_speech(ai_response)
        audio_b64 = base64.b64encode(audio_output).decode()

        voice_log = VoiceLog(
            user_id=user.id,
            session_id=session_id,
            transcript=transcript,
            ai_response=ai_response,
            language=language,
            duration_ms=len(audio_bytes) // 32,
        )
        db.add(voice_log)
        await db.flush()

        return {
            "transcript": transcript,
            "ai_response": ai_response,
            "audio_base64": audio_b64,
            "audio_content_type": "audio/mpeg",
            "session_id": str(session_id),
            "greeting": self.astrologer.get_greeting(language) if include_greeting else None,
        }

    async def stream_voice_response(self, text: str):
        async for chunk in self.elevenlabs.stream_text_to_speech(text):
            yield chunk
