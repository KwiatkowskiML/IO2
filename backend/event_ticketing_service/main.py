import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import cart, events, tickets, ticket_types

app = FastAPI(
    title="Resellio Tickets & Events Service",
    description="Tickets & Events microservice for Resellio ticket selling platform",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For production, restrict this to specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers for different functionalities
app.include_router(tickets.router)
app.include_router(events.router)
app.include_router(ticket_types.router)
app.include_router(cart.router)


@app.get("/")
def read_root():
    """Root endpoint to verify service is running"""
    return {
        "service": "Resellio Tickets & Events Service",
        "status": "operational",
        "version": "0.0.1",
    }


@app.get("/health")
def health_check():
    """Health check endpoint for monitoring"""
    return {"status": "healthy"}


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)
