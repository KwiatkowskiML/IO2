import logging
from typing import List, Optional

from sqlalchemy.orm import Session, joinedload

from app.database import get_db
from app.models.ticket import TicketModel
from fastapi import HTTPException, status, Depends
from app.filters.ticket_filter import TicketFilter
from app.schemas.ticket import TicketPDF, ResellTicketRequest
from app.models.events import EventModel
from app.models.ticket_type import TicketTypeModel
from app.models.location import LocationModel
from app.services.email import send_ticket_email
from app.schemas.ticket import TicketType

logger = logging.getLogger(__name__)

class TicketRepository:
    """Service layer for ticket operations."""

    def __init__(self, db: Session):
        self.db = db

    def list_tickets(self, filters: TicketFilter) -> List[dict]:
        query = (
            self.db.query(
                TicketModel.ticket_id,
                TicketModel.type_id,
                TicketModel.seat,
                TicketModel.owner_id,
                TicketModel.resell_price,
                TicketTypeModel.price.label('original_price'),
                EventModel.name.label('event_name'),
                EventModel.start_date.label('event_start_date'),
                LocationModel.name.label('event_location'),
                TicketTypeModel.description.label('ticket_type_description')
            )
            .join(TicketTypeModel, TicketModel.type_id == TicketTypeModel.type_id)
            .join(EventModel, TicketTypeModel.event_id == EventModel.event_id)
            .join(LocationModel, EventModel.location_id == LocationModel.location_id)
        )

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
        results = query.all()

        # Convert to dictionaries that match the TicketDetails schema
        tickets = []
        for result in results:
            ticket_dict = {
                'ticket_id': result.ticket_id,
                'type_id': result.type_id,
                'seat': result.seat,
                'owner_id': result.owner_id,
                'resell_price': result.resell_price,
                'original_price': result.original_price,
                'event_name': result.event_name,
                'event_start_date': result.event_start_date,
                'event_location': result.event_location,
                'ticket_type_description': result.ticket_type_description
            }
            tickets.append(ticket_dict)

        return tickets

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

    def buy_resale_ticket(self, ticket_id: int, buyer_id: int, buyer_email: str, buyer_name: str) -> TicketModel:
        ticket = self.get_ticket(ticket_id)

        if ticket.resell_price is None:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, detail="Ticket is not for resale")

        if ticket.owner_id == buyer_id:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, detail="Cannot buy your own ticket")

        ticket.owner_id = buyer_id
        ticket.resell_price = None

        self.db.commit()
        self.db.refresh(ticket)

        ticket_info = self.db.query(TicketModel).options(
            joinedload(TicketModel.ticket_type)
            .joinedload(TicketTypeModel.event)
            .joinedload(EventModel.location)
        ).filter(TicketModel.ticket_id == ticket_id).first()

        # Format the date and time as strings
        event_datetime = ticket_info.ticket_type.event.start_date
        formatted_event_date = event_datetime.strftime("%B %d, %Y")  # e.g., "June 15, 2025"
        formatted_event_time = event_datetime.strftime("%I:%M %p")  # e.g., "02:30 PM"

        email_sent = send_ticket_email(
            to_email=buyer_email,
            user_name=buyer_name,
            event_name=ticket_info.ticket_type.event.name,
            ticket_id=str(ticket_info.ticket_id),
            event_date=formatted_event_date,
            event_time=formatted_event_time,
            venue=ticket_info.ticket_type.event.location.name,
            seat=ticket_info.seat,
        )
        if not email_sent:
            logger.error(
                f"Failed to send confirmation email for ticket {ticket_id} to {buyer_email}")

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

    def create_ticket_type(self, ticket_type_data: TicketType) -> TicketType:
        """
        Creates a new ticket type in the database.
        """
        event = self.db.get(EventModel, ticket_type_data.event_id)
        if not event:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Event with id {ticket_type_data.event_id} not found"
            )

        # Create SQLAlchemy model from Pydantic schema data
        db_ticket_type = TicketTypeModel(
            event_id=ticket_type_data.event_id,
            description=ticket_type_data.description,
            max_count=ticket_type_data.max_count,
            price=ticket_type_data.price,
            currency=ticket_type_data.currency,
            available_from=ticket_type_data.available_from,
        )

        self.db.add(db_ticket_type)
        self.db.commit()
        self.db.refresh(db_ticket_type)

        return TicketType.model_validate(db_ticket_type)

# Dependency to get the TicketRepository instance
def get_ticket_repository(db: Session = Depends(get_db)) -> TicketRepository:
    return TicketRepository(db)
