from datetime import datetime
from decimal import Decimal
from typing import Optional
from uuid import UUID

from pydantic import BaseModel


class SubscriptionPlanResponse(BaseModel):
    plan_type: str
    name: str
    price: Decimal
    currency: str
    features: list[str]
    duration_days: int


class CreateOrderRequest(BaseModel):
    plan_type: str
    gateway: str = "razorpay"


class PaymentOrderResponse(BaseModel):
    order_id: str
    amount: Decimal
    currency: str
    gateway: str
    key_id: Optional[str] = None
    client_secret: Optional[str] = None


class SubscriptionResponse(BaseModel):
    id: UUID
    plan_type: str
    status: str
    starts_at: Optional[datetime]
    expires_at: Optional[datetime]

    model_config = {"from_attributes": True}
