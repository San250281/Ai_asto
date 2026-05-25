from datetime import datetime
from typing import Any, Optional
from uuid import UUID

from pydantic import BaseModel


class KundliGenerateRequest(BaseModel):
    force_regenerate: bool = False


class KundliResponse(BaseModel):
    id: UUID
    user_id: UUID
    lagna_chart: dict[str, Any]
    planet_positions: dict[str, Any]
    dasha: dict[str, Any]
    horoscope_summary: Optional[str]
    dosha_analysis: dict[str, Any]
    nakshatra: Optional[str]
    rashi: Optional[str]
    generated_at: datetime

    model_config = {"from_attributes": True}


class PredictionResponse(BaseModel):
    id: UUID
    prediction_type: str
    prediction_date: str
    content_hi: Optional[str]
    content_en: Optional[str]
    metadata: dict[str, Any]

    model_config = {"from_attributes": True}
