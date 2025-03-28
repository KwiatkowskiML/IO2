from fastapi import FastAPI
from app.routers.tickets import tickets

app = FastAPI(title="Ticket Service", version="0.1.0")

app.include_router(tickets)
