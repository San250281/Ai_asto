from uuid import UUID
from typing import Optional

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.redis_client import rate_limit_check
from app.models.user import User
from app.schemas.chat import VoiceChatResponse
from app.services.voice_service import VoiceService

router = APIRouter(prefix="/voice", tags=["Voice AI"])
settings = get_settings()


@router.post("/chat", response_model=VoiceChatResponse)
async def voice_chat(
    audio: UploadFile = File(...),
    language: str = Form(default="hindi"),
    session_id: Optional[str] = Form(default=None),
    include_greeting: bool = Form(default=False),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    allowed = await rate_limit_check(
        f"voice:{user.id}", settings.voice_rate_limit_per_minute
    )
    if not allowed:
        raise HTTPException(status_code=429, detail="Voice rate limit exceeded")

    audio_bytes = await audio.read()
    if len(audio_bytes) > 10 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="Audio file too large (max 10MB)")

    sid = UUID(session_id) if session_id else None
    result = await VoiceService().process_voice_chat(
        db, user, audio_bytes, language, sid, include_greeting
    )

    return VoiceChatResponse(
        transcript=result["transcript"],
        ai_response=result["ai_response"],
        audio_url=f"data:audio/mpeg;base64,{result['audio_base64']}",
        session_id=UUID(result["session_id"]),
        greeting=result.get("greeting"),
    )


@router.post("/tts/stream")
async def stream_tts(
    text: str = Form(...),
    user: User = Depends(get_current_user),
):
    service = VoiceService()

    async def audio_stream():
        async for chunk in service.stream_voice_response(text):
            yield chunk

    return StreamingResponse(audio_stream(), media_type="audio/mpeg")
