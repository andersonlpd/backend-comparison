from typing import Any, List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api.dependencies import get_current_active_user, get_db
from app.db.models import InventoryItem, Order, OrderItem, Product, User
from app.schemas.order import Order as OrderSchema, OrderCreate

router = APIRouter(redirect_slashes=False)


@router.get("/", response_model=List[OrderSchema])
def read_orders(
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """
    Retrieve orders.
    """
    orders = db.query(Order).filter(
        Order.customer_id == current_user.id
    ).offset(skip).limit(limit).all()
    
    # Filter out order items with None product_id
    for order in orders:
        valid_items = []
        for item in order.items:
            if item.product_id is not None:
                valid_items.append(item)
        # Replace items list with filtered list
        order.items = valid_items
    
    return orders


@router.post("/", response_model=OrderSchema)
def create_order(
    *,
    db: Session = Depends(get_db),
    order_in: OrderCreate,
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """
    Create new order.
    """
    # Create order
    order = Order(
        customer_id=current_user.id,
        status=order_in.status,
        total_amount=0.0
    )
    db.add(order)
    db.commit()
    db.refresh(order)
    
    # Calculate total and add order items
    total_amount = 0.0
    for item_data in order_in.items:
        # Check product exists
        product = db.query(Product).filter(Product.id == item_data.product_id).first()
        if not product:
            db.delete(order)
            db.commit()
            raise HTTPException(status_code=404, detail=f"Product {item_data.product_id} not found")
        
        # Check inventory
        inventory = db.query(InventoryItem).filter(InventoryItem.product_id == item_data.product_id).first()
        if not inventory or inventory.quantity < item_data.quantity:
            db.delete(order)
            db.commit()
            raise HTTPException(status_code=400, detail=f"Not enough items in inventory for product {item_data.product_id}")
        
        # Create order item
        order_item = OrderItem(
            order_id=order.id,
            product_id=item_data.product_id,
            quantity=item_data.quantity,
            unit_price=item_data.unit_price
        )
        db.add(order_item)
        
        # Update inventory
        inventory.quantity -= item_data.quantity
        
        # Add to total
        total_amount += item_data.quantity * item_data.unit_price
    
    # Update order total
    order.total_amount = total_amount
    
    db.commit()
    db.refresh(order)
    return order


@router.get("/{id}", response_model=OrderSchema)
def read_order(
    *,
    db: Session = Depends(get_db),
    id: int,
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """
    Get order by ID.
    """
    order = db.query(Order).filter(Order.id == id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    if order.customer_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    # Filter out order items with None product_id
    valid_items = []
    for item in order.items:
        if item.product_id is not None:
            valid_items.append(item)
    # Replace items list with filtered list
    order.items = valid_items
    
    return order
