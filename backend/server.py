from fastapi import FastAPI, APIRouter, HTTPException
from dotenv import load_dotenv
from starlette.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
import os
import logging
from pathlib import Path
from pydantic import BaseModel, Field, EmailStr
from typing import List, Optional
import uuid
from datetime import datetime


ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

# MongoDB connection
mongo_url = os.environ['MONGO_URL']
client = AsyncIOMotorClient(mongo_url)
db = client[os.environ['DB_NAME']]

# Create the main app without a prefix
app = FastAPI()

# Create a router with the /api prefix
api_router = APIRouter(prefix="/api")


# Define Models
class StatusCheck(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    client_name: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)

class StatusCheckCreate(BaseModel):
    client_name: str

# Contact Form Models
class ContactRequest(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str
    email: EmailStr
    phone: str
    subject: str
    message: str
    has_pets: bool = False
    has_vulnerable_people: bool = False
    created_at: datetime = Field(default_factory=datetime.utcnow)
    status: str = "nouveau"

class ContactRequestCreate(BaseModel):
    name: str
    email: EmailStr
    phone: str
    subject: str
    message: str
    hasPets: bool = False
    hasVulnerablePeople: bool = False

class ContactResponse(BaseModel):
    success: bool
    message: str
    id: str

# Add your routes to the router instead of directly to app
@api_router.get("/")
async def root():
    return {"message": "Hello World"}

@api_router.post("/status", response_model=StatusCheck)
async def create_status_check(input: StatusCheckCreate):
    status_dict = input.dict()
    status_obj = StatusCheck(**status_dict)
    _ = await db.status_checks.insert_one(status_obj.dict())
    return status_obj

@api_router.get("/status", response_model=List[StatusCheck])
async def get_status_checks():
    status_checks = await db.status_checks.find().to_list(1000)
    return [StatusCheck(**status_check) for status_check in status_checks]

# Contact Form Endpoints
@api_router.post("/contact", response_model=ContactResponse)
async def create_contact_request(contact_data: ContactRequestCreate):
    try:
        # Convert frontend field names to backend field names
        contact_dict = contact_data.dict()
        contact_dict['has_pets'] = contact_dict.pop('hasPets')
        contact_dict['has_vulnerable_people'] = contact_dict.pop('hasVulnerablePeople')
        
        # Create contact request object
        contact_obj = ContactRequest(**contact_dict)
        
        # Save to database
        result = await db.contact_requests.insert_one(contact_obj.dict())
        
        if result.inserted_id:
            logger.info(f"New contact request created: {contact_obj.id}")
            return ContactResponse(
                success=True,
                message="Votre demande a été envoyée avec succès. Nous vous recontacterons sous 24h.",
                id=contact_obj.id
            )
        else:
            raise HTTPException(status_code=500, detail="Erreur lors de la sauvegarde")
            
    except Exception as e:
        logger.error(f"Error creating contact request: {str(e)}")
        raise HTTPException(status_code=500, detail="Une erreur interne s'est produite")

@api_router.get("/contact", response_model=List[ContactRequest])
async def get_contact_requests(status: Optional[str] = None):
    """Endpoint pour récupérer les demandes de contact (usage admin)"""
    try:
        filter_query = {}
        if status:
            filter_query["status"] = status
            
        contact_requests = await db.contact_requests.find(filter_query).sort("created_at", -1).to_list(1000)
        return [ContactRequest(**request) for request in contact_requests]
    except Exception as e:
        logger.error(f"Error fetching contact requests: {str(e)}")
        raise HTTPException(status_code=500, detail="Erreur lors de la récupération des données")

# Include the router in the main app
app.include_router(api_router)

app.add_middleware(
    CORSMiddleware,
    allow_credentials=True,
    allow_origins=os.environ.get('CORS_ORIGINS', '*').split(','),
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@app.on_event("shutdown")
async def shutdown_db_client():
    client.close()
