from typing import Optional

from pydantic import BaseModel


class ProductBase(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    price: Optional[float] = None
    sku: Optional[str] = None


class ProductCreate(ProductBase):
    name: str
    price: float
    sku: str


class ProductUpdate(ProductBase):
    pass


class ProductInDBBase(ProductBase):
    id: int
    owner_id: int

    class Config:
        orm_mode = True


class Product(ProductInDBBase):
    pass
