from app.database import Base
from sqlalchemy.orm import relationship
from sqlalchemy import Text, Column, String, Integer, DateTime, ForeignKey, CheckConstraint


class EventModel(Base):
    __tablename__ = "events"
    __table_args__ = (CheckConstraint("start_date < end_date", name="check_start_before_end"),)

    event_id = Column(Integer, primary_key=True, index=True)
    organiser_id = Column(Integer, nullable=False)
    location_id = Column(Integer, ForeignKey("locations.location_id", ondelete="RESTRICT"), nullable=False)
    name = Column(String(255), nullable=False)
    description = Column(Text)
    start_date = Column(DateTime, nullable=False)
    end_date = Column(DateTime, nullable=False)
    minimum_age = Column(Integer)
    status = Column(String(20), nullable=False, default="created")

    location = relationship("LocationModel", back_populates="events")
    ticket_types = relationship("TicketTypeModel", back_populates="event", cascade="all, delete-orphan")
