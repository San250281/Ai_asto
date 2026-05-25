import uuid
from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.integrations.openai_client import get_openai_client
from app.models.admin import AIPrompt
from app.models.chat import ChatHistory
from app.models.kundli import KundliReport
from app.models.user import User

DEFAULT_SYSTEM_PROMPT = """You are an experienced Indian astrologer with 20+ years of experience in Vedic astrology.

You speak naturally in Hindi and English.

You analyze:
- Kundli
- Planet positions
- Dasha
- Transit
- Zodiac signs

You provide:
- Career guidance
- Marriage guidance
- Financial guidance
- Health guidance
- Spiritual guidance

Your tone should be:
- Calm
- Spiritual
- Positive
- Emotional
- Human-like

Never sound robotic.
Always speak respectfully.

Do not make harmful, fearful, or extreme predictions.

Always provide practical and positive guidance."""

GREETING_HI = (
    "नमस्कार, आपका स्वागत है। "
    "मैं आपकी कुंडली के आधार पर आपके जीवन, करियर, "
    "विवाह और आने वाले समय के बारे में जानकारी दूंगा।"
)


class AIAstrologerService:
    def __init__(self) -> None:
        self.openai = get_openai_client()

    async def get_system_prompt(self, db: AsyncSession) -> str:
        result = await db.execute(
            select(AIPrompt).where(AIPrompt.name == "astrologer_default", AIPrompt.is_active == True)
        )
        prompt = result.scalar_one_or_none()
        return prompt.system_prompt if prompt else DEFAULT_SYSTEM_PROMPT

    async def _build_kundli_context(self, db: AsyncSession, user_id: uuid.UUID) -> str:
        result = await db.execute(
            select(KundliReport).where(KundliReport.user_id == user_id)
        )
        kundli = result.scalar_one_or_none()
        if not kundli:
            return "Kundli not yet generated for this user."
        return (
            f"Lagna: {kundli.lagna_chart}\n"
            f"Planets: {kundli.planet_positions}\n"
            f"Dasha: {kundli.dasha}\n"
            f"Dosha: {kundli.dosha_analysis}\n"
            f"Nakshatra: {kundli.nakshatra}, Rashi: {kundli.rashi}"
        )

    async def _get_recent_history(
        self, db: AsyncSession, user_id: uuid.UUID, session_id: Optional[uuid.UUID], limit: int = 10
    ) -> list[dict]:
        query = select(ChatHistory).where(ChatHistory.user_id == user_id)
        if session_id:
            query = query.where(ChatHistory.session_id == session_id)
        query = query.order_by(ChatHistory.created_at.desc()).limit(limit)
        result = await db.execute(query)
        messages = list(reversed(result.scalars().all()))
        return [{"role": m.role, "content": m.message} for m in messages]

    def _language_instruction(self, language: str) -> str:
        if language == "hindi":
            return "Respond primarily in Hindi (Devanagari script). Be warm and spiritual."
        if language == "hinglish":
            return "Respond in Hinglish (mix of Hindi and English). Be conversational and warm."
        return "Respond in English. Be warm, spiritual, and respectful."

    async def chat(
        self,
        db: AsyncSession,
        user: User,
        message: str,
        language: str = "hindi",
        session_id: Optional[uuid.UUID] = None,
    ) -> tuple[str, uuid.UUID]:
        session_id = session_id or uuid.uuid4()
        system_prompt = await self.get_system_prompt(db)
        kundli_ctx = await self._build_kundli_context(db, user.id)
        history = await self._get_recent_history(db, user.id, session_id)

        messages = [
            {"role": "system", "content": system_prompt},
            {
                "role": "system",
                "content": (
                    f"User: {user.full_name}, DOB: {user.date_of_birth}, "
                    f"Birth place: {user.birth_place}\n{kundli_ctx}\n"
                    f"{self._language_instruction(language)}"
                ),
            },
        ]
        messages.extend(history)
        messages.append({"role": "user", "content": message})

        response = await self.openai.chat_completion(messages)
        ai_text = response.choices[0].message.content or ""

        user_msg = ChatHistory(
            user_id=user.id,
            session_id=session_id,
            role="user",
            message=message,
            language=language,
        )
        ai_msg = ChatHistory(
            user_id=user.id,
            session_id=session_id,
            role="assistant",
            message=ai_text,
            language=language,
            kundli_context={"summary": kundli_ctx[:500]},
            tokens_used=response.usage.total_tokens if response.usage else 0,
        )
        db.add(user_msg)
        db.add(ai_msg)
        await db.flush()

        return ai_text, session_id

    def get_greeting(self, language: str) -> str:
        if language == "english":
            return (
                "Namaste, welcome. Based on your birth chart, I will guide you "
                "about life, career, marriage, and the times ahead."
            )
        return GREETING_HI
