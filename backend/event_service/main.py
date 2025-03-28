from fastapi import FastAPI
from app.routers.events import router

app = FastAPI(title="Event Service", version="0.1.0")

app.include_router(router)
