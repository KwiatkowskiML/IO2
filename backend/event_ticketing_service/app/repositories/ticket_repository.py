from typing import List, Any
from sqlalchemy.orm import Session

from fastapi import HTTPException, status
from app.filters.ticket_filter import TicketFilter
from app.models.ticket import TicketModel
from app.models.ticket_type import TicketTypeModel
from app.schemas.ticket import TicketDetails, TicketPDF, ResellTicketRequest

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
        if filters.is_on_resale is not None:
            if filters.is_on_resale:
                query = query.filter(TicketModel.resell_price.isnot(None))
            else:
                query = query.filter(TicketModel.resell_price.is_(None))
        return query.all()

    def get_ticket(self, ticket_id: int) -> TicketModel:
        ticket = self.db.get(TicketModel, ticket_id)
        if not ticket:
            raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Ticket not found")
        return ticket

    def download_ticket(self, ticket_id: int) -> TicketPDF:
        ticket = self.get_ticket(ticket_id)
        # Stub: actual PDF generation logic goes here
        return TicketPDF(pdf_data="base64_pdf_data", filename=f"ticket_{ticket_id}.pdf")

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