from sqlalchemy import Column, Integer, String, Boolean, Numeric, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from enum import Enum

from backend.common.models.base import Base


class TicketStatus(Enum):
    IN_CART = 'in_cart'
    OWNED = 'owned'
    ON_SALE = 'on_sale'
    USED = 'used'
    EXPIRED = 'expired'
    CANCELLED = 'cancelled'


class Ticket(Base):
    __tablename__ = 'tickets'

    ticket_id = Column(Integer, primary_key=True, autoincrement=True)
    type_id = Column(Integer, ForeignKey('ticket_types.type_id', ondelete='CASCADE'), nullable=False)
    owner_id = Column(Integer, ForeignKey('customers.customer_id', ondelete='SET NULL'))
    name_on_ticket = Column(String(255))
    seat = Column(String(50))
    for_resell = Column(Boolean, nullable=False, server_default='false')
    resell_price = Column(Numeric(10, 2))
    purchased = Column(Boolean, nullable=False, server_default='false')
    status = Column(String(20), nullable=False, server_default='in_cart')

    def __repr__(self):
        return f"<Ticket(ticket_id={self.ticket_id}, type_id={self.type_id}, status='{self.status}')>"