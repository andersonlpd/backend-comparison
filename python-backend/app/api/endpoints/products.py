from typing import Any, List
import logging

from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session

from app.api.dependencies import get_current_active_user, get_db
from app.db.models import Product, User
from app.schemas.product import Product as ProductSchema, ProductCreate, ProductUpdate

# Modificar a configuração do router para desativar o redirecionamento de barra final
router = APIRouter(redirect_slashes=False)
logger = logging.getLogger(__name__)


@router.get("/", response_model=List[ProductSchema])
def read_products(
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """
    Retrieve products.
    """
    products = db.query(Product).offset(skip).limit(limit).all()
    return products


@router.post("/", response_model=ProductSchema)
async def create_product(
    request: Request,
    *,
    db: Session = Depends(get_db),
    product_in: ProductCreate,
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """
    Create new product.
    """
    # Log the request details to help debug the issue
    logger.info(f"Creating product: {product_in.dict()}")
    logger.info(f"Request URL: {request.url}")
    logger.info(f"Request headers: {request.headers}")
    
    try:
        product = Product(
            name=product_in.name,
            description=product_in.description,
            price=product_in.price,
            sku=product_in.sku,
            owner_id=current_user.id,
        )
        db.add(product)
        db.commit()
        db.refresh(product)
        return product
    except Exception as e:
        logger.error(f"Error creating product: {str(e)}")
        raise


@router.get("/{id}", response_model=ProductSchema)
def read_product(
    *,
    db: Session = Depends(get_db),
    id: int,
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """
    Get product by ID.
    """
    product = db.query(Product).filter(Product.id == id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    return product


@router.put("/{id}", response_model=ProductSchema)
def update_product(
    *,
    db: Session = Depends(get_db),
    id: int,
    product_in: ProductUpdate,
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """
    Update a product.
    """
    product = db.query(Product).filter(Product.id == id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    update_data = product_in.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(product, field, value)
    
    db.add(product)
    db.commit()
    db.refresh(product)
    return product


@router.delete("/{id}", response_model=ProductSchema)
def delete_product(
    *,
    db: Session = Depends(get_db),
    id: int,
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """
    Delete a product.
    """
    product = db.query(Product).filter(Product.id == id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    db.delete(product)
    db.commit()
    return product
