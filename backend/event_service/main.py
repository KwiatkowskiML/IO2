from fastapi import FastAPI
from app.routers.events import events

app = FastAPI(title="Event Service", version="0.1.0")

app.include_router(events)
