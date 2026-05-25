from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.schemas.subscription import (
    CreateOrderRequest,
    PaymentOrderResponse,
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


@router.post("/razorpay/webhook")
async def razorpay_webhook(request: Request, db: AsyncSession = Depends(get_db)):
    body = await request.body()
    # Verify signature in production with razorpay_webhook_secret
    import json
    payload = json.loads(body)
    if payload.get("event") == "payment.captured":
        notes = payload.get("payload", {}).get("payment", {}).get("entity", {}).get("notes", {})
        # Activate subscription based on notes
        pass
    return {"status": "ok"}


@router.post("/stripe/webhook")
async def stripe_webhook(request: Request, db: AsyncSession = Depends(get_db)):
    # Verify with stripe_webhook_secret
    return {"status": "ok"}
