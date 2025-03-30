from fastapi import APIRouter

router = APIRouter(prefix="/customers", tags=["customers"])


@router.get("/")
def home():
    return {"message": "Hello World - Cart"}
