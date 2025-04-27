from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base

class TicketType(Base):
    __tablename__ = 'ticket_types'

    type_id = Column(Integer, primary_key=True, index=True)
    event_id = Column(Integer, ForeignKey('events.event_id', ondelete='CASCADE'), nullable=False)
    description = Column(String(255))
    max_count = Column(Integer, nullable=False)
    price = Column(Float, nullable=False)
    currency = Column(String(3), nullable=False, default='PLN')
    available_from = Column(DateTime, nullable=False)

    event = relationship('Event', back_populates='ticket_types')