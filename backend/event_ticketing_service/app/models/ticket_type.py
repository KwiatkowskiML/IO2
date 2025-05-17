from app.database import Base
from sqlalchemy.orm import relationship
from sqlalchemy import Float, Column, String, Integer, DateTime, ForeignKey


class TicketTypeModel(Base):
    __tablename__ = "ticket_types"

    type_id = Column(Integer, primary_key=True, index=True)
    event_id = Column(Integer, ForeignKey("events.event_id", ondelete="CASCADE"), nullable=False)
    description = Column(String(255))
    max_count = Column(Integer, nullable=False)
    price = Column(Float, nullable=False)
    currency = Column(String(3), nullable=False, default="PLN")
    available_from = Column(DateTime, nullable=False)

    event = relationship("EventModel", back_populates="ticket_types")
    tickets = relationship("TicketModel", back_populates="ticket_type")
