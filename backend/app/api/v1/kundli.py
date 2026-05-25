from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.kundli import KundliReport
from app.models.user import User
from app.schemas.kundli import KundliGenerateRequest, KundliResponse, PredictionResponse
from app.services.astrology_engine import get_astrology_engine
from app.services.horoscope_service import HoroscopeService

router = APIRouter(prefix="/kundli", tags=["Kundli"])


@router.post("/generate", response_model=KundliResponse)
async def generate_kundli(
    request: KundliGenerateRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(KundliReport).where(KundliReport.user_id == user.id))
    existing = result.scalar_one_or_none()

    if existing and not request.force_regenerate:
        return KundliResponse.model_validate(existing)

    engine = get_astrology_engine()
    lat = float(user.birth_latitude or 28.6139)
    lng = float(user.birth_longitude or 77.2090)
    data = await engine.generate_kundli(
        user.date_of_birth, user.birth_time, lat, lng, user.birth_timezone
    )

    if existing:
        existing.lagna_chart = data["lagna_chart"]
        existing.planet_positions = data["planet_positions"]
        existing.dasha = data["dasha"]
        existing.dosha_analysis = data["dosha_analysis"]
        existing.nakshatra = data.get("nakshatra")
        existing.rashi = data.get("rashi")
        existing.horoscope_summary = data.get("horoscope_summary")
        existing.raw_ephemeris_data = data.get("raw_ephemeris_data")
        report = existing
    else:
        report = KundliReport(
            user_id=user.id,
            lagna_chart=data["lagna_chart"],
            planet_positions=data["planet_positions"],
            dasha=data["dasha"],
            dosha_analysis=data["dosha_analysis"],
            nakshatra=data.get("nakshatra"),
            rashi=data.get("rashi"),
            horoscope_summary=data.get("horoscope_summary"),
            raw_ephemeris_data=data.get("raw_ephemeris_data"),
        )
        db.add(report)

    await db.flush()
    return KundliResponse.model_validate(report)


@router.get("/", response_model=KundliResponse)
async def get_kundli(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(KundliReport).where(KundliReport.user_id == user.id))
    report = result.scalar_one_or_none()
    if not report:
        raise HTTPException(status_code=404, detail="Kundli not found. Generate first.")
    return KundliResponse.model_validate(report)


@router.get("/predictions/{prediction_type}", response_model=PredictionResponse)
async def get_prediction(
    prediction_type: str,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    pred = await HoroscopeService().get_or_generate_prediction(db, user, prediction_type)
    return PredictionResponse.model_validate(pred)
