from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class InventoryItemBase(BaseModel):
    # Modificar para permitir valores nulos se necessário
    product_id: Optional[int] = None
    quantity: int = 0


class InventoryItemCreate(InventoryItemBase):
    # Para criação, produto_id é obrigatório
    product_id: int


class InventoryItemUpdate(BaseModel):
    quantity: Optional[int] = None


class InventoryItemInDBBase(InventoryItemBase):
    id: int
    last_updated: datetime

    class Config:
        orm_mode = True


class InventoryItem(InventoryItemInDBBase):
    pass


class InventoryAdjustment(BaseModel):
    product_id: int  # Positive for additions, negative for removals
    quantity: int
