from datetime import datetime, timedelta
from decimal import Decimal
from typing import Optional
import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.models.subscription import Payment, Subscription
from app.models.user import User

settings = get_settings()

PLANS = {
    "free": {
        "name": "Free",
        "price": Decimal("0"),
        "duration_days": 36500,
        "features": ["5 AI chats/day", "Basic Kundli", "Daily horoscope"],
    },
    "premium_monthly": {
        "name": "Premium Monthly",
        "price": Decimal(str(settings.premium_monthly_price)),
        "duration_days": 30,
        "features": [
            "Unlimited AI chat",
            "Advanced predictions",
            "Detailed reports",
            "Voice consultation",
        ],
    },
    "premium_yearly": {
        "name": "Premium Yearly",
        "price": Decimal(str(settings.premium_yearly_price)),
        "duration_days": 365,
        "features": [
            "Unlimited AI chat",
            "All predictions",
            "Priority voice",
            "Consultation booking",
        ],
    },
}


class PaymentService:
    async def get_plans(self) -> list[dict]:
        return [
            {
                "plan_type": key,
                "name": val["name"],
                "price": val["price"],
                "currency": "INR",
                "features": val["features"],
                "duration_days": val["duration_days"],
            }
            for key, val in PLANS.items()
            if key != "free"
        ]

    async def create_razorpay_order(
        self, db: AsyncSession, user: User, plan_type: str
    ) -> dict:
        import razorpay

        plan = PLANS.get(plan_type)
        if not plan or plan["price"] == 0:
            raise ValueError("Invalid plan")

        client = razorpay.Client(
            auth=(settings.razorpay_key_id, settings.razorpay_key_secret)
        )
        amount_paise = int(plan["price"] * 100)
        order = client.order.create(
            {
                "amount": amount_paise,
                "currency": "INR",
                "payment_capture": 1,
                "notes": {"user_id": str(user.id), "plan": plan_type},
            }
        )

        payment = Payment(
            user_id=user.id,
            amount=plan["price"],
            gateway="razorpay",
            gateway_order_id=order["id"],
            status="pending",
            metadata={"plan_type": plan_type},
        )
        db.add(payment)
        await db.flush()

        return {
            "order_id": order["id"],
            "amount": plan["price"],
            "currency": "INR",
            "gateway": "razorpay",
            "key_id": settings.razorpay_key_id,
        }

    async def create_stripe_session(
        self, db: AsyncSession, user: User, plan_type: str
    ) -> dict:
        import stripe

        stripe.api_key = settings.stripe_secret_key
        plan = PLANS.get(plan_type)
        if not plan:
            raise ValueError("Invalid plan")

        session = stripe.checkout.Session.create(
            payment_method_types=["card"],
            line_items=[
                {
                    "price_data": {
                        "currency": "inr",
                        "product_data": {"name": plan["name"]},
                        "unit_amount": int(plan["price"] * 100),
                    },
                    "quantity": 1,
                }
            ],
            mode="payment",
            success_url="aijyotishguru://payment/success",
            cancel_url="aijyotishguru://payment/cancel",
            metadata={"user_id": str(user.id), "plan_type": plan_type},
        )

        payment = Payment(
            user_id=user.id,
            amount=plan["price"],
            gateway="stripe",
            gateway_order_id=session.id,
            status="pending",
            metadata={"plan_type": plan_type},
        )
        db.add(payment)
        await db.flush()

        return {
            "order_id": session.id,
            "amount": plan["price"],
            "currency": "INR",
            "gateway": "stripe",
            "client_secret": session.url,
        }

    async def activate_subscription(
        self, db: AsyncSession, user: User, plan_type: str, payment_id: Optional[uuid.UUID] = None
    ) -> Subscription:
        plan = PLANS[plan_type]
        now = datetime.utcnow()
        sub = Subscription(
            user_id=user.id,
            plan_type=plan_type,
            status="active",
            starts_at=now,
            expires_at=now + timedelta(days=plan["duration_days"]),
        )
        db.add(sub)
        user.is_premium = True
        await db.flush()
        return sub

    async def get_user_subscription(
        self, db: AsyncSession, user_id: uuid.UUID
    ) -> Optional[Subscription]:
        result = await db.execute(
            select(Subscription)
            .where(Subscription.user_id == user_id, Subscription.status == "active")
            .order_by(Subscription.expires_at.desc())
        )
        return result.scalar_one_or_none()
