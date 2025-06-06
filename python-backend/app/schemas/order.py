from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, validator


class OrderItemBase(BaseModel):
    product_id: Optional[int] = None  # Allow None values
    quantity: int
    unit_price: float
    
    @validator('product_id')
    def validate_product_id(cls, v):
        # For creation, we'll still require product_id
        if v is None:
            raise ValueError('product_id cannot be None')
        return v


class OrderItemCreate(OrderItemBase):
    product_id: int  # For creation, product_id is required


class OrderItemInDBBase(OrderItemBase):
    id: int
    order_id: int

    class Config:
        orm_mode = True


class OrderItem(OrderItemInDBBase):
    pass


class OrderBase(BaseModel):
    status: Optional[str] = "pending"
    total_amount: Optional[float] = 0.0


class OrderCreate(OrderBase):
    items: List[OrderItemCreate]


class OrderUpdate(OrderBase):
    pass


class OrderInDBBase(OrderBase):
    id: int
    customer_id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True


class Order(OrderInDBBase):
    items: List[OrderItem] = []
