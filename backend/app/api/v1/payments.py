from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.schemas.subscription import (
    CreateOrderRequest,
    PaymentOrderResponse,
    RazorpayVerifyRequest,
    SubscriptionPlanResponse,
    SubscriptionResponse,
)
from app.services.payment_service import PaymentService

router = APIRouter(prefix="/payments", tags=["Payments"])


@router.get("/plans", response_model=list[SubscriptionPlanResponse])
async def get_plans():
    plans = await PaymentService().get_plans()
    return [SubscriptionPlanResponse(**p) for p in plans]


@router.post("/create-order", response_model=PaymentOrderResponse)
async def create_order(
    request: CreateOrderRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = PaymentService()
    try:
        if request.gateway == "stripe":
            order = await service.create_stripe_session(db, user, request.plan_type)
        else:
            order = await service.create_razorpay_order(db, user, request.plan_type)
        return PaymentOrderResponse(**order)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/subscription", response_model=SubscriptionResponse)
async def get_subscription(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    sub = await PaymentService().get_user_subscription(db, user.id)
    if not sub:
        raise HTTPException(status_code=404, detail="No active subscription")
    return SubscriptionResponse.model_validate(sub)


@router.post("/razorpay/verify", response_model=SubscriptionResponse)
async def verify_razorpay_payment(
    request: RazorpayVerifyRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = PaymentService()
    try:
        sub = await service.verify_razorpay_payment(
            db,
            user,
            request.razorpay_order_id,
            request.razorpay_payment_id,
            request.razorpay_signature,
        )
        return SubscriptionResponse.model_validate(sub)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/razorpay/webhook")
async def razorpay_webhook(request: Request, db: AsyncSession = Depends(get_db)):
    import hashlib
    import hmac
    import json
    from uuid import UUID

    from app.config import get_settings
    from app.models.user import User

    settings = get_settings()
    body = await request.body()
    signature = request.headers.get("X-Razorpay-Signature", "")

    if settings.razorpay_webhook_secret:
        expected = hmac.new(
            settings.razorpay_webhook_secret.encode(),
            body,
            hashlib.sha256,
        ).hexdigest()
        if not hmac.compare_digest(expected, signature):
            raise HTTPException(status_code=400, detail="Invalid webhook signature")

    payload = json.loads(body)
    if payload.get("event") == "payment.captured":
        entity = payload.get("payload", {}).get("payment", {}).get("entity", {})
        notes = entity.get("notes", {})
        user_id = notes.get("user_id")
        plan_type = notes.get("plan", "premium_monthly")
        if user_id:
            result = await db.execute(select(User).where(User.id == UUID(user_id)))
            user = result.scalar_one_or_none()
            if user:
                service = PaymentService()
                await service.activate_subscription(db, user, plan_type)
    return {"status": "ok"}


@router.post("/stripe/webhook")
async def stripe_webhook(request: Request, db: AsyncSession = Depends(get_db)):
    # Verify with stripe_webhook_secret
    return {"status": "ok"}
