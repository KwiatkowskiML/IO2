from pydantic import BaseModel

class LocationBase(BaseModel):
    name: str
    address: str
    zipcode: str | None = None
    city: str
    country: str

class LocationDetails(LocationBase):
    location_id: int
    class Config:
        orm_mode = True