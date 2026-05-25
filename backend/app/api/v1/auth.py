from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.schemas.user import (
    OTPRequest,
    OTPVerifyRequest,
    TokenResponse,
    UserRegisterRequest,
    UserResponse,
)
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=TokenResponse)
async def register(data: UserRegisterRequest, db: AsyncSession = Depends(get_db)):
    try:
        user, access, refresh = await AuthService().register_user(db, data)
        return TokenResponse(
            access_token=access,
            refresh_token=refresh,
            user=UserResponse.model_validate(user),
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.post("/login", response_model=TokenResponse)
async def login(firebase_token: str, db: AsyncSession = Depends(get_db)):
    try:
        user, access, refresh = await AuthService().login_by_firebase(db, firebase_token)
        return TokenResponse(
            access_token=access,
            refresh_token=refresh,
            user=UserResponse.model_validate(user),
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(e))


@router.post("/otp/send")
async def send_otp(data: OTPRequest, db: AsyncSession = Depends(get_db)):
    await AuthService().send_otp(db, data.mobile_number)
    return {"message": "OTP sent successfully"}


@router.post("/otp/verify")
async def verify_otp(data: OTPVerifyRequest, db: AsyncSession = Depends(get_db)):
    verified = await AuthService().verify_otp(db, data.mobile_number, data.otp)
    if not verified:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid OTP")
    return {"verified": True}


@router.post("/refresh")
async def refresh_token(refresh_token: str, db: AsyncSession = Depends(get_db)):
    try:
        access, new_refresh = await AuthService().refresh_tokens(db, refresh_token)
        return {"access_token": access, "refresh_token": new_refresh}
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(e))
