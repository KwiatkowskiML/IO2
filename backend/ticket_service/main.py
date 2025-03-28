from fastapi import FastAPI
from app.routers.tickets import router

app = FastAPI(title="Ticket Service", version="0.1.0")

app.include_router(router)
