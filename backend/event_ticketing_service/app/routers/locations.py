from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.location import LocationModel
from app.schemas.location import LocationDetails

router = APIRouter(prefix="/locations", tags=["locations"])


@router.get("/", response_model=List[LocationDetails])
async def get_all_locations(db: Session = Depends(get_db)):
    """
    Retrieve a list of all available event locations.
    """
    locations = db.query(LocationModel).order_by(LocationModel.name).all()
    return locations
