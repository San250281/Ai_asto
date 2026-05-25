from app.models.user import User
from app.models.kundli import KundliReport
from app.models.prediction import AstrologyPrediction
from app.models.chat import ChatHistory
from app.models.subscription import Subscription, Payment
from app.models.voice import VoiceLog
from app.models.notification import Notification
from app.models.admin import AdminUser, AIPrompt
from app.models.otp import OTPVerification

__all__ = [
    "User",
    "KundliReport",
    "AstrologyPrediction",
    "ChatHistory",
    "Subscription",
    "Payment",
    "VoiceLog",
    "Notification",
    "AdminUser",
    "AIPrompt",
    "OTPVerification",
]
