# datamodels.py
from pydantic import BaseModel


class NewsCreate(BaseModel):
    author_id: int
    cover_link: str
    title: str
    subtitle: str
    location: str
    views: int = 0


class NewsUpdate(BaseModel):
    cover_link: str
    title: str
    subtitle: str
    location: str
    views: int
