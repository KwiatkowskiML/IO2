from sqlalchemy import Column, Integer, String, ForeignKey, Numeric
from sqlalchemy.orm import relationship
from app.database import Base

class TicketModel(Base):
    __tablename__ = 'tickets'

    ticket_id = Column(Integer, primary_key=True, index=True)
    type_id = Column('type_id', Integer, ForeignKey('ticket_types.type_id', ondelete='CASCADE'), nullable=False)
    owner_id = Column(Integer, nullable=True)
    seat = Column(String(50), nullable=True)
    resell_price = Column(Numeric(10, 2), nullable=True)

    # relationships
    ticket_type = relationship('TicketTypeModel', back_populates='tickets')

    def __repr__(self):
        return f"<Ticket(ticket_id={self.ticket_id}, type_id={self.type_id}, owner_id={self.owner_id})>"
