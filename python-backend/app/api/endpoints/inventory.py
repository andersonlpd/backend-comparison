from typing import Any, List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api.dependencies import get_current_active_user, get_db
from app.db.models import InventoryItem, Product, User
from app.schemas.inventory import InventoryAdjustment, InventoryItem as InventoryItemSchema

router = APIRouter(redirect_slashes=False)


@router.get("/", response_model=List[InventoryItemSchema])
def read_inventory(
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """
    Retrieve inventory items.
    """
    # Modificado para filtrar itens com product_id nulo
    inventory = db.query(InventoryItem).filter(InventoryItem.product_id.isnot(None)).offset(skip).limit(limit).all()
    
    # Verificação adicional para garantir que não haja valores nulos
    valid_inventory = []
    for item in inventory:
        if item.product_id is not None:
            valid_inventory.append(item)
    
    return valid_inventory


@router.post("/add", response_model=InventoryItemSchema)
def add_to_inventory(
    *,
    db: Session = Depends(get_db),
    adjustment: InventoryAdjustment,
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """
    Add items to inventory.
    """
    # Ensure product exists
    product = db.query(Product).filter(Product.id == adjustment.product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    # Check if inventory item already exists
    inventory_item = db.query(InventoryItem).filter(
        InventoryItem.product_id == adjustment.product_id
    ).first()
    
    if inventory_item:
        # Update existing inventory
        inventory_item.quantity += adjustment.quantity
    else:
        # Create new inventory item
        inventory_item = InventoryItem(
            product_id=adjustment.product_id,
            quantity=adjustment.quantity
        )
        db.add(inventory_item)
    
    db.commit()
    db.refresh(inventory_item)
    return inventory_item


@router.post("/remove", response_model=InventoryItemSchema)
def remove_from_inventory(
    *,
    db: Session = Depends(get_db),
    adjustment: InventoryAdjustment,
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """
    Remove items from inventory.
    """
    # Ensure inventory item exists
    inventory_item = db.query(InventoryItem).filter(
        InventoryItem.product_id == adjustment.product_id
    ).first()
    
    if not inventory_item:
        raise HTTPException(status_code=404, detail="Product not in inventory")
    
    # Check if we have enough items
    if inventory_item.quantity < adjustment.quantity:
        raise HTTPException(status_code=400, detail="Not enough items in inventory")
    
    # Update inventory
    inventory_item.quantity -= adjustment.quantity
    
    db.commit()
    db.refresh(inventory_item)
    return inventory_item
