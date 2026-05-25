from functools import lru_cache
from typing import List

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    app_name: str = "AI Jyotish Guru"
    app_env: str = "development"
    debug: bool = False
    api_version: str = "v1"
    secret_key: str = "dev-secret-change-in-production-min-32-chars"
    jwt_algorithm: str = "HS256"
    jwt_access_token_expire_minutes: int = 30
    jwt_refresh_token_expire_days: int = 7
    encryption_key: str = "dev-encryption-key-32bytes-base64!!"

    host: str = "0.0.0.0"
    port: int = 8000
    cors_origins: str = "http://localhost:3000"

    database_url: str = "postgresql+asyncpg://jyotish:jyotish_secret@localhost:5432/ai_jyotish_guru"
    database_pool_size: int = 20
    database_max_overflow: int = 40

    redis_url: str = "redis://localhost:6379/0"

    firebase_project_id: str = ""
    firebase_credentials_path: str = ""

    openai_api_key: str = ""
    openai_model: str = "gpt-4o"
    openai_max_tokens: int = 2048
    whisper_model: str = "whisper-1"

    elevenlabs_api_key: str = ""
    elevenlabs_voice_id: str = ""
    elevenlabs_model: str = "eleven_multilingual_v2"

    astrology_provider: str = "swiss_ephemeris"
    vedic_api_base_url: str = ""
    vedic_api_key: str = ""
    swiss_ephemeris_path: str = "/usr/share/ephe"

    razorpay_key_id: str = ""
    razorpay_key_secret: str = ""
    razorpay_webhook_secret: str = ""

    stripe_secret_key: str = ""
    stripe_webhook_secret: str = ""
    stripe_publishable_key: str = ""

    aws_access_key_id: str = ""
    aws_secret_access_key: str = ""
    aws_region: str = "ap-south-1"
    aws_s3_bucket: str = ""

    fcm_server_key: str = ""

    rate_limit_per_minute: int = 60
    voice_rate_limit_per_minute: int = 10
    free_daily_chat_limit: int = 5

    premium_monthly_price: float = 299.0
    premium_yearly_price: float = 2499.0

    @property
    def cors_origin_list(self) -> List[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
