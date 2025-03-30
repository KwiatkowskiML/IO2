from common.security import get_current_user
from fastapi import Path, Depends, APIRouter
from user_service.app.schemas.cart import CartItem, ShoppingCartResponse
from common.schemas.payment import PaymentResponse

router = APIRouter(prefix="/cart", tags=["cart"])


@router.get("/")
def home():
    return {"message": "Hello World - Cart"}


@router.get("/")
async def get_shopping_cart(current_user=Depends(get_current_user)) -> ShoppingCartResponse:
    return ShoppingCartResponse(id="123", user_id="123", items=[], total=0.0, currency="PLN")


@router.post("/cart/items")
async def add_to_cart(item: CartItem, current_user=Depends(get_current_user)) -> ShoppingCartResponse:
    return ShoppingCartResponse(id="123", user_id="123", items=[], total=0.0, currency="PLN")


@router.delete("/cart/items/{item_id}")
async def remove_from_cart(
    item_id: str = Path(..., title="cart item ID"), current_user=Depends(get_current_user)
) -> ShoppingCartResponse:
    return ShoppingCartResponse(id="123", user_id="123", items=[], total=0.0, currency="PLN")


@router.post("/cart/checkout")
async def checkout_cart(current_user=Depends(get_current_user)) -> PaymentResponse:
    return PaymentResponse(success=True, transaction_id="123", error_message=None)
