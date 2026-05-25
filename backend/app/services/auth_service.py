import secrets
from datetime import datetime, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token, create_refresh_token, hash_password, verify_password
from app.integrations.firebase_auth import verify_firebase_token
from app.models.otp import OTPVerification
from app.models.user import User
from app.schemas.user import UserRegisterRequest


class AuthService:
    async def register_user(
        self, db: AsyncSession, data: UserRegisterRequest
    ) -> tuple[User, str, str]:
        firebase_claims = await verify_firebase_token(data.firebase_token)
        if not firebase_claims:
            raise ValueError("Invalid Firebase token")

        existing = await db.execute(
            select(User).where(User.firebase_uid == firebase_claims["uid"])
        )
        if existing.scalar_one_or_none():
            raise ValueError("User already registered")

        user = User(
            firebase_uid=firebase_claims["uid"],
            full_name=data.full_name,
            gender=data.gender,
            date_of_birth=data.date_of_birth,
            birth_time=data.birth_time,
            birth_place=data.birth_place,
            birth_latitude=data.birth_latitude,
            birth_longitude=data.birth_longitude,
            current_city=data.current_city,
            language_preference=data.language_preference,
            mobile_number=data.mobile_number,
            gdpr_consent=data.gdpr_consent,
            last_login_at=datetime.utcnow(),
        )
        db.add(user)
        await db.flush()

        access = create_access_token(str(user.id))
        refresh = create_refresh_token(str(user.id))
        return user, access, refresh

    async def login_by_firebase(
        self, db: AsyncSession, firebase_token: str
    ) -> tuple[User, str, str]:
        claims = await verify_firebase_token(firebase_token)
        if not claims:
            raise ValueError("Invalid Firebase token")

        result = await db.execute(
            select(User).where(User.firebase_uid == claims["uid"])
        )
        user = result.scalar_one_or_none()
        if not user:
            raise ValueError("User not found. Please register first.")

        user.last_login_at = datetime.utcnow()
        access = create_access_token(str(user.id))
        refresh = create_refresh_token(str(user.id))
        return user, access, refresh

    async def send_otp(self, db: AsyncSession, mobile_number: str) -> bool:
        otp = f"{secrets.randbelow(900000) + 100000}"
        otp_record = OTPVerification(
            mobile_number=mobile_number,
            otp_hash=hash_password(otp),
            expires_at=datetime.utcnow() + timedelta(minutes=10),
        )
        db.add(otp_record)
        await db.flush()
        # In production: send via Firebase/SMS gateway
        if db.bind and hasattr(db.bind, "url"):
            pass  # SMS integration hook
        return True

    async def verify_otp(
        self, db: AsyncSession, mobile_number: str, otp: str
    ) -> bool:
        result = await db.execute(
            select(OTPVerification)
            .where(
                OTPVerification.mobile_number == mobile_number,
                OTPVerification.verified == False,
                OTPVerification.expires_at > datetime.utcnow(),
            )
            .order_by(OTPVerification.created_at.desc())
        )
        record = result.scalar_one_or_none()
        if not record or record.attempts >= 5:
            return False
        record.attempts += 1
        if verify_password(otp, record.otp_hash):
            record.verified = True
            user_result = await db.execute(
                select(User).where(User.mobile_number == mobile_number)
            )
            user = user_result.scalar_one_or_none()
            if user:
                user.mobile_verified = True
            return True
        return False

    async def refresh_tokens(
        self, db: AsyncSession, refresh_token: str
    ) -> tuple[str, str]:
        from app.core.security import decode_token

        payload = decode_token(refresh_token)
        if not payload or payload.get("type") != "refresh":
            raise ValueError("Invalid refresh token")
        user_id = payload["sub"]
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if not user:
            raise ValueError("User not found")
        return create_access_token(str(user.id)), create_refresh_token(str(user.id))
