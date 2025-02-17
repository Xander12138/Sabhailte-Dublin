from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from src.news_handler import add_news_to_db
from src.news_handler import delete_news as delete_news_in_db
from src.news_handler import get_news_by_id
from src.news_handler import update_news as update_news_in_db
from src.utils.db_utils import get_connection

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex='http.*',
    allow_credentials=True,
    allow_methods=['*'],
    allow_headers=['*'],
)

# ------------------ NEWS ENDPOINTS ------------------ #


# Pydantic models for news creation and update
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


@app.post('/news')
def create_news(news: NewsCreate):
    try:
        new_id = add_news_to_db(
            news.author_id,
            news.cover_link,
            news.title,
            news.subtitle,
            news.location,
            news.views,
        )
        return {'message': 'News added successfully', 'news_id': new_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f'Error adding news: {e}')


@app.get('/news')
def list_news():
    try:
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute('SELECT * FROM news;')
                rows = cur.fetchall()
                return {'news': rows}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f'Error fetching news: {e}')


@app.get('/news/{news_id}')
def read_news(news_id: int):
    try:
        news_item = get_news_by_id(news_id)
        return news_item
    except ValueError as ve:
        raise HTTPException(status_code=404, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f'Error retrieving news: {e}')


@app.put('/news/{news_id}')
def update_news(news_id: int, news: NewsUpdate):
    try:
        updated = update_news_in_db(
            news_id,
            news.cover_link,
            news.title,
            news.subtitle,
            news.location,
            news.views,
        )
        return {'message': 'News updated successfully', 'news': updated}
    except ValueError as ve:
        raise HTTPException(status_code=404, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f'Error updating news: {e}')


@app.delete('/news/{news_id}')
def delete_news(news_id: int):
    try:
        result = delete_news_in_db(news_id)
        return result
    except ValueError as ve:
        raise HTTPException(status_code=404, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f'Error deleting news: {e}')
