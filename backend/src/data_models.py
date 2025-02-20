# Pydantic model for disaster data
from pydantic import BaseModel


class Disaster(BaseModel):
    title: str
    description: str
    time: str
    location: str
