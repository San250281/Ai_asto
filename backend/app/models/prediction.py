import uuid
from datetime import date, datetime
from typing import Optional

from sqlalchemy import Date, ForeignKey, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class AstrologyPrediction(Base):
    __tablename__ = "astrology_predictions"
    __table_args__ = (
        UniqueConstraint("user_id", "prediction_type", "prediction_date"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE")
    )
    prediction_type: Mapped[str] = mapped_column()
    prediction_date: Mapped[date] = mapped_column(Date)
    content_hi: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    content_en: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    metadata: Mapped[dict] = mapped_column(JSONB, default=dict)
    created_at: Mapped[datetime] = mapped_column(default=datetime.utcnow)

    user = relationship("User", back_populates="predictions")
