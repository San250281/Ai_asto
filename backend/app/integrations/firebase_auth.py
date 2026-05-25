from typing import Optional

from app.config import get_settings

settings = get_settings()
_firebase_app = None


def _init_firebase():
    global _firebase_app
    if _firebase_app is not None:
        return _firebase_app
    try:
        import firebase_admin
        from firebase_admin import credentials

        if settings.firebase_credentials_path:
            cred = credentials.Certificate(settings.firebase_credentials_path)
            _firebase_app = firebase_admin.initialize_app(cred)
        return _firebase_app
    except Exception:
        return None


async def verify_firebase_token(id_token: str) -> Optional[dict]:
    """Verify Firebase ID token and return decoded claims."""
    _init_firebase()
    try:
        from firebase_admin import auth

        decoded = auth.verify_id_token(id_token)
        return {
            "uid": decoded.get("uid"),
            "phone_number": decoded.get("phone_number"),
            "email": decoded.get("email"),
        }
    except Exception:
        if settings.app_env == "development":
            return {"uid": f"dev_{id_token[:28]}", "phone_number": None, "email": None}
        return None
