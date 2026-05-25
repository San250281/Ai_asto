from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import verify_password, create_access_token, hash_password
from app.models.admin import AdminUser, AIPrompt
from app.models.user import User
from app.models.subscription import Subscription

router = APIRouter(prefix="/admin", tags=["Admin"])


class AdminLoginRequest(BaseModel):
    email: str
    password: str


class PromptUpdateRequest(BaseModel):
    system_prompt: str


@router.post("/login")
async def admin_login(data: AdminLoginRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(AdminUser).where(AdminUser.email == data.email))
    admin = result.scalar_one_or_none()
    if not admin or not verify_password(data.password, admin.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    token = create_access_token(str(admin.id), extra={"role": "admin"})
    return {"access_token": token, "token_type": "bearer"}


@router.get("/analytics")
async def get_analytics(db: AsyncSession = Depends(get_db)):
    total_users = await db.scalar(select(func.count(User.id)))
    premium_users = await db.scalar(
        select(func.count(User.id)).where(User.is_premium == True)
    )
    active_subs = await db.scalar(
        select(func.count(Subscription.id)).where(Subscription.status == "active")
    )
    return {
        "total_users": total_users or 0,
        "premium_users": premium_users or 0,
        "active_subscriptions": active_subs or 0,
    }


@router.get("/users")
async def list_users(skip: int = 0, limit: int = 50, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).offset(skip).limit(limit))
    users = result.scalars().all()
    return [
        {
            "id": str(u.id),
            "full_name": u.full_name,
            "mobile": u.mobile_number,
            "is_premium": u.is_premium,
            "created_at": u.created_at.isoformat(),
        }
        for u in users
    ]


@router.get("/prompts")
async def list_prompts(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(AIPrompt))
    return result.scalars().all()


@router.put("/prompts/{name}")
async def update_prompt(
    name: str, data: PromptUpdateRequest, db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(AIPrompt).where(AIPrompt.name == name))
    prompt = result.scalar_one_or_none()
    if not prompt:
        raise HTTPException(status_code=404, detail="Prompt not found")
    prompt.system_prompt = data.system_prompt
    prompt.version += 1
    await db.flush()
    return {"message": "Prompt updated", "version": prompt.version}
