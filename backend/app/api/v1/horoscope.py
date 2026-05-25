from datetime import date

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.schemas.kundli import PredictionResponse
from app.services.horoscope_service import HoroscopeService

router = APIRouter(prefix="/horoscope", tags=["Horoscope"])


@router.get("/daily", response_model=PredictionResponse)
async def daily_horoscope(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    pred = await HoroscopeService().get_or_generate_prediction(db, user, "daily")
    return PredictionResponse.model_validate(pred)


@router.get("/weekly", response_model=PredictionResponse)
async def weekly_horoscope(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    pred = await HoroscopeService().get_or_generate_prediction(db, user, "weekly")
    return PredictionResponse.model_validate(pred)


@router.get("/{prediction_type}", response_model=PredictionResponse)
async def get_prediction(
    prediction_type: str,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    pred = await HoroscopeService().get_or_generate_prediction(db, user, prediction_type)
    return PredictionResponse.model_validate(pred)
