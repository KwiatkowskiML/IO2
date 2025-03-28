from fastapi import APIRouter

tickets = APIRouter()

@tickets.get("/hello")
async def hello():
    return {"message": "Hello from Ticket Service"}
