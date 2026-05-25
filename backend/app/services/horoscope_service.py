from datetime import date, timedelta
from typing import Optional
import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.integrations.openai_client import get_openai_client
from app.models.kundli import KundliReport
from app.models.prediction import AstrologyPrediction
from app.models.user import User


class HoroscopeService:
    PREDICTION_TYPES = ["daily", "weekly", "career", "marriage", "health"]

    def __init__(self) -> None:
        self.openai = get_openai_client()

    async def get_or_generate_prediction(
        self,
        db: AsyncSession,
        user: User,
        prediction_type: str,
        target_date: Optional[date] = None,
    ) -> AstrologyPrediction:
        target_date = target_date or date.today()

        result = await db.execute(
            select(AstrologyPrediction).where(
                AstrologyPrediction.user_id == user.id,
                AstrologyPrediction.prediction_type == prediction_type,
                AstrologyPrediction.prediction_date == target_date,
            )
        )
        existing = result.scalar_one_or_none()
        if existing:
            return existing

        kundli_result = await db.execute(
            select(KundliReport).where(KundliReport.user_id == user.id)
        )
        kundli = kundli_result.scalar_one_or_none()
        kundli_summary = ""
        if kundli:
            kundli_summary = (
                f"Lagna: {kundli.lagna_chart}, Rashi: {kundli.rashi}, "
                f"Dasha: {kundli.dasha}"
            )

        prompt = (
            f"Generate a personalized {prediction_type} Vedic astrology prediction for "
            f"{user.full_name}, born {user.date_of_birth} in {user.birth_place}. "
            f"Kundli: {kundli_summary}. Date: {target_date}. "
            f"Provide content in Hindi (content_hi) and English (content_en). "
            f"Be positive, spiritual, practical. No fearful predictions."
        )

        response = await self.openai.chat_completion(
            [
                {
                    "role": "system",
                    "content": "You are a Vedic astrologer. Return JSON with keys: content_hi, content_en",
                },
                {"role": "user", "content": prompt},
            ],
            temperature=0.7,
        )
        text = response.choices[0].message.content or ""

        content_hi = text
        content_en = text
        if "content_hi" in text:
            import json
            try:
                data = json.loads(text)
                content_hi = data.get("content_hi", text)
                content_en = data.get("content_en", text)
            except json.JSONDecodeError:
                pass

        prediction = AstrologyPrediction(
            user_id=user.id,
            prediction_type=prediction_type,
            prediction_date=target_date,
            content_hi=content_hi,
            content_en=content_en,
            metadata={"generated": True, "rashi": kundli.rashi if kundli else None},
        )
        db.add(prediction)
        await db.flush()
        return prediction

    async def generate_weekly_batch(self, db: AsyncSession, user: User) -> list:
        predictions = []
        for ptype in ["daily", "weekly"]:
            pred = await self.get_or_generate_prediction(db, user, ptype)
            predictions.append(pred)
        return predictions
