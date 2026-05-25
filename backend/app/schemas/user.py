from datetime import date, datetime, time
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field


class UserRegisterRequest(BaseModel):
    firebase_token: str
    full_name: str = Field(..., min_length=2, max_length=255)
    gender: str = Field(..., pattern="^(male|female|other)$")
    date_of_birth: date
    birth_time: time
    birth_place: str
    birth_latitude: Optional[float] = None
    birth_longitude: Optional[float] = None
    current_city: Optional[str] = None
    language_preference: str = "hindi"
    mobile_number: str = Field(..., pattern=r"^\+?[1-9]\d{9,14}$")
    gdpr_consent: bool = True


class UserUpdateRequest(BaseModel):
    full_name: Optional[str] = None
    current_city: Optional[str] = None
    language_preference: Optional[str] = None
    fcm_token: Optional[str] = None
    profile_image_url: Optional[str] = None


class UserResponse(BaseModel):
    id: UUID
    full_name: str
    gender: str
    date_of_birth: date
    birth_time: time
    birth_place: str
    current_city: Optional[str]
    language_preference: str
    mobile_number: Optional[str]
    mobile_verified: bool
    is_premium: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserResponse


class OTPRequest(BaseModel):
    mobile_number: str


class OTPVerifyRequest(BaseModel):
    mobile_number: str
    otp: str
