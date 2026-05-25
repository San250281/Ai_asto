from datetime import datetime
from typing import Any, Optional
from uuid import UUID

from pydantic import BaseModel, Field


class ChatMessageRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=4000)
    language: str = "hindi"
    session_id: Optional[UUID] = None


class ChatMessageResponse(BaseModel):
    id: UUID
    session_id: UUID
    role: str
    message: str
    language: str
    created_at: datetime

    model_config = {"from_attributes": True}


class VoiceChatResponse(BaseModel):
    transcript: str
    ai_response: str
    audio_url: Optional[str] = None
    session_id: UUID
    greeting: Optional[str] = None


class ChatHistoryResponse(BaseModel):
    messages: list[ChatMessageResponse]
    session_id: UUID
    kundli_context: Optional[dict[str, Any]] = None
