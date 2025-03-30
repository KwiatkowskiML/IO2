from sqlalchemy import Column, Integer, String, Numeric, DateTime, ForeignKey
from backend.common.models.base import Base

class TicketType(Base):
    __tablename__ = 'ticket_types'

    type_id = Column(Integer, primary_key=True, autoincrement=True)
    event_id = Column(Integer, ForeignKey('events.event_id', ondelete='CASCADE'), nullable=False)
    description = Column(String(255))
    max_count = Column(Integer, nullable=False)
    price = Column(Numeric(10, 2), nullable=False)
    currency = Column(String(3), nullable=False, server_default='PLN')
    available_from = Column(DateTime, nullable=False)