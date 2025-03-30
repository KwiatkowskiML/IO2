from fastapi import APIRouter

router = APIRouter(prefix="/cart", tags=["cart"])


@router.get("/")
def home():
    return {"message": "Hello World - Cart"}
