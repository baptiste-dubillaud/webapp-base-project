from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from settings.settings import ApplicationSettings

# Loads settings at start
ApplicationSettings()

# FastAPI application instance
app = FastAPI(title="Base App Backend", version="0.1.0")

# CORS middleware configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def root():
    """Root endpoint."""
    return {"message": "Welcome to the CoachLM API", "docs": "/docs"}


