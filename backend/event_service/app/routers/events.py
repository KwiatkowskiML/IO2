from fastapi import APIRouter

events = APIRouter()

@events.get("/hello")
async def hello():
    return {"message": "Hello from Event Service"}
