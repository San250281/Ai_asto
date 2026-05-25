from fastapi import APIRouter

from app.api.v1 import auth, kundli, chat, voice, horoscope, payments, users, admin

api_router = APIRouter()
api_router.include_router(auth.router)
api_router.include_router(users.router)
api_router.include_router(kundli.router)
api_router.include_router(chat.router)
api_router.include_router(voice.router)
api_router.include_router(horoscope.router)
api_router.include_router(payments.router)
api_router.include_router(admin.router)
