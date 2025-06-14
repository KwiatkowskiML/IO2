from typing import List, Optional

from sqlalchemy.orm import Session

from app.database import get_db
from app.models.ticket import TicketModel
from fastapi import HTTPException, status, Depends
from app.filters.ticket_filter import TicketFilter
from app.models.ticket_type import TicketTypeModel
from app.schemas.ticket import TicketPDF, ResellTicketRequest


class TicketRepository:
    """Service layer for ticket operations."""

    def __init__(self, db: Session):
        self.db = db

    def list_tickets(self, filters: TicketFilter) -> List[TicketModel]:
        query = self.db.query(TicketModel)
        if filters.ticket_id is not None:
            query = query.filter(TicketModel.ticket_id == filters.ticket_id)
        if filters.type_id is not None:
            query = query.filter(TicketModel.type_id == filters.type_id)
        if filters.owner_id is not None:
            query = query.filter(TicketModel.owner_id == filters.owner_id)
        if filters.is_on_resale is not None:
            if filters.is_on_resale:
                query = query.filter(TicketModel.resell_price.isnot(None))
            else:
                query = query.filter(TicketModel.resell_price.is_(None))
        return query.all()

    def get_ticket(self, ticket_id: int) -> Optional[TicketModel]:
        ticket = self.db.get(TicketModel, ticket_id)
        if not ticket:
            raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Ticket not found")
        return ticket

    def get_ticket_type_by_id(self, type_id: int) -> Optional[TicketTypeModel]:
        """
        Retrieves a ticket type by its ID.
        """
        return self.db.get(TicketTypeModel, type_id)

    def download_ticket(self, ticket_id: int) -> TicketPDF:
        ticket = self.get_ticket(ticket_id)
        # Stub: actual PDF generation logic goes here
        return TicketPDF(pdf_data=f"base64_pdf_data for ticket {ticket.ticket_id}", filename=f"ticket_{ticket_id}.pdf")

    def list_resale_tickets(self, event_id: Optional[int] = None) -> List[TicketModel]:
        query = self.db.query(TicketModel).filter(TicketModel.resell_price.isnot(None))

        if event_id:
            query = query.join(TicketTypeModel).filter(TicketTypeModel.event_id == event_id)

        return query.all()

    def buy_resale_ticket(self, ticket_id: int, buyer_id: int) -> TicketModel:
        ticket = self.get_ticket(ticket_id)

        if ticket.resell_price is None:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, detail="Ticket is not for resale")

        if ticket.owner_id == buyer_id:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, detail="Cannot buy your own ticket")

        ticket.owner_id = buyer_id
        ticket.resell_price = None

        self.db.commit()
        self.db.refresh(ticket)
        return ticket

    def resell_ticket(self, data: ResellTicketRequest, user_id: int) -> TicketModel:
        ticket = self.get_ticket(data.ticket_id)
        if ticket.owner_id != user_id:
            raise HTTPException(status.HTTP_403_FORBIDDEN, detail="Not the ticket owner")
        if data.price is None:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, detail="Resell price required")
        ticket.resell_price = data.price
        self.db.commit()
        self.db.refresh(ticket)
        return ticket

    def cancel_resell(self, ticket_id: int, user_id: int) -> TicketModel:
        ticket = self.get_ticket(ticket_id)
        if ticket.owner_id != user_id:
            raise HTTPException(status.HTTP_403_FORBIDDEN, detail="Not the ticket owner")
        ticket.resell_price = None
        self.db.commit()
        self.db.refresh(ticket)
        return ticket

# Dependency to get the TicketRepository instance
def get_ticket_repository(db: Session = Depends(get_db)) -> TicketRepository:
    return TicketRepository(db)
