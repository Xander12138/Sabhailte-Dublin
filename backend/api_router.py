from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from src.news_handler import create_news, delete_news, get_news, get_news_list, update_news

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
def api_create_news(news: NewsCreate):
    try:
        new_id = create_news(
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
def api_list_news():
    try:
        news_list = get_news_list()
        return {'news': news_list}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f'Error fetching news: {e}')


@app.get('/news/{news_id}')
def api_read_news(news_id: int):
    try:
        news_item = get_news(news_id)
        return news_item
    except ValueError as ve:
        raise HTTPException(status_code=404, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f'Error retrieving news: {e}')


@app.put('/news/{news_id}')
def api_update_news(news_id: int, news: NewsUpdate):
    try:
        updated = update_news(
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
def api_delete_news(news_id: int):
    try:
        result = delete_news(news_id)
        return result
    except ValueError as ve:
        raise HTTPException(status_code=404, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f'Error deleting news: {e}')
