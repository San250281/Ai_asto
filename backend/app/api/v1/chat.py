from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.core.redis_client import rate_limit_check
from app.models.chat import ChatHistory
from app.models.user import User
from app.schemas.chat import ChatHistoryResponse, ChatMessageRequest, ChatMessageResponse
from app.services.ai_astrologer import AIAstrologerService

router = APIRouter(prefix="/chat", tags=["AI Chat"])
settings = get_settings()


@router.post("/message", response_model=ChatMessageResponse)
async def send_message(
    request: ChatMessageRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    allowed = await rate_limit_check(
        f"chat:{user.id}", settings.rate_limit_per_minute
    )
    if not allowed:
        raise HTTPException(status_code=429, detail="Rate limit exceeded")

    if not user.is_premium:
        daily_key = f"chat_daily:{user.id}"
        allowed_daily = await rate_limit_check(
            daily_key, settings.free_daily_chat_limit, window=86400
        )
        if not allowed_daily:
            raise HTTPException(
                status_code=403,
                detail="Daily chat limit reached. Upgrade to Premium.",
            )

    ai_text, session_id = await AIAstrologerService().chat(
        db, user, request.message, request.language, request.session_id
    )

    result = await db.execute(
        select(ChatHistory)
        .where(ChatHistory.user_id == user.id, ChatHistory.session_id == session_id)
        .order_by(ChatHistory.created_at.desc())
        .limit(1)
    )
    msg = result.scalar_one()
    return ChatMessageResponse.model_validate(msg)


@router.get("/history/{session_id}", response_model=ChatHistoryResponse)
async def get_chat_history(
    session_id: UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(ChatHistory)
        .where(ChatHistory.user_id == user.id, ChatHistory.session_id == session_id)
        .order_by(ChatHistory.created_at)
    )
    messages = result.scalars().all()
    return ChatHistoryResponse(
        messages=[ChatMessageResponse.model_validate(m) for m in messages],
        session_id=session_id,
    )


@router.get("/greeting")
async def get_greeting(
    language: str = "hindi",
    user: User = Depends(get_current_user),
):
    return {"greeting": AIAstrologerService().get_greeting(language)}


@router.post("/stream")
async def stream_chat(
    request: ChatMessageRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from app.integrations.openai_client import get_openai_client
    from app.services.ai_astrologer import AIAstrologerService

    service = AIAstrologerService()
    ai_text, session_id = await service.chat(
        db, user, request.message, request.language, request.session_id
    )

    async def generate():
        client = get_openai_client()
        async for chunk in client.stream_chat(
            [{"role": "user", "content": request.message}]
        ):
            yield chunk

    return StreamingResponse(generate(), media_type="text/event-stream")
