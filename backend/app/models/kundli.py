import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import ForeignKey, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class KundliReport(Base):
    __tablename__ = "kundli_reports"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), unique=True
    )
    lagna_chart: Mapped[dict] = mapped_column(JSONB, default=dict)
    planet_positions: Mapped[dict] = mapped_column(JSONB, default=dict)
    dasha: Mapped[dict] = mapped_column(JSONB, default=dict)
    horoscope_summary: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    dosha_analysis: Mapped[dict] = mapped_column(JSONB, default=dict)
    nakshatra: Mapped[Optional[str]] = mapped_column(nullable=True)
    rashi: Mapped[Optional[str]] = mapped_column(nullable=True)
    raw_ephemeris_data: Mapped[Optional[dict]] = mapped_column(JSONB, nullable=True)
    generated_at: Mapped[datetime] = mapped_column(default=datetime.utcnow)

    user = relationship("User", back_populates="kundli_report")
