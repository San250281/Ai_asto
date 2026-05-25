import uuid
from datetime import date, datetime, time
from typing import Optional

from sqlalchemy import Boolean, Date, LargeBinary, Numeric, String, Text, Time
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    firebase_uid: Mapped[str] = mapped_column(String(128), unique=True, index=True)
    full_name: Mapped[str] = mapped_column(String(255))
    gender: Mapped[str] = mapped_column(String(16))
    date_of_birth: Mapped[date] = mapped_column(Date)
    birth_time: Mapped[time] = mapped_column(Time)
    birth_place: Mapped[str] = mapped_column(String(255))
    birth_latitude: Mapped[Optional[float]] = mapped_column(Numeric(10, 7), nullable=True)
    birth_longitude: Mapped[Optional[float]] = mapped_column(Numeric(10, 7), nullable=True)
    birth_timezone: Mapped[str] = mapped_column(String(64), default="Asia/Kolkata")
    current_city: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    language_preference: Mapped[str] = mapped_column(String(16), default="hindi")
    mobile_number: Mapped[Optional[str]] = mapped_column(String(20), unique=True, nullable=True)
    mobile_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    email: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    profile_image_url: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    is_premium: Mapped[bool] = mapped_column(Boolean, default=False)
    encrypted_birth_data: Mapped[Optional[bytes]] = mapped_column(LargeBinary, nullable=True)
    fcm_token: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    gdpr_consent: Mapped[bool] = mapped_column(Boolean, default=False)
    last_login_at: Mapped[Optional[datetime]] = mapped_column(nullable=True)
    created_at: Mapped[datetime] = mapped_column(default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        default=datetime.utcnow, onupdate=datetime.utcnow
    )

    kundli_report = relationship("KundliReport", back_populates="user", uselist=False)
    chat_history = relationship("ChatHistory", back_populates="user")
    subscriptions = relationship("Subscription", back_populates="user")
    predictions = relationship("AstrologyPrediction", back_populates="user")
