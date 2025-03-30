from fastapi import APIRouter

router = APIRouter(prefix="/organisers", tags=["organisers"])


@router.get("/")
def home():
    return {"message": "Hello World - Organisers"}
