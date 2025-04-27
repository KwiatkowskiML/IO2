from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship
from app.database import Base

class Location(Base):
    __tablename__ = 'locations'
    location_id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    address = Column(String(255), nullable=False)
    zipcode = Column(String(20))
    city = Column(String(100), nullable=False)
    country = Column(String(100), nullable=False)
    events = relationship('Event', back_populates='location')