from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from src import map_handler, news_handler
from src.data_models import NewsCreate, NewsUpdate

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex='http.*',
    allow_credentials=True,
    allow_methods=['*'],
    allow_headers=['*'],
)

# @router.middleware('http')
# async def auth_middleware(request, call_next):
#     whitelist = ('/auth', '/connect', '/disconnect', '/message')
#     if not request.url.path.startswith(whitelist):
#         no_auth_response = PlainTextResponse(content='Unauthorized', status_code=401)
#         no_auth_response.headers['WWW-Authenticate'] = 'Basic'

#         auth_header = request.headers.get('Authorization')
#         if not auth_header:
#             return no_auth_response

#         scheme, credentials = auth_header.split()
#         decoded = base64.b64decode(credentials).decode('ascii')
#         username, password = decoded.split(':')
#         if username != 'ase' or password != 'ase':
#             return no_auth_response

#     body = await request.body()
#     try:
#         return await call_next(request)
#     except fastapi.HTTPException as http_e:
#         return _text_response_from_exception(http_e.status_code, http_e)
#     except Exception as e:
#         logging.error('Internal error on request: %s?%s %s', request.url.path, request.query_params, body)
#         logging.exception('Exception')
#         return _text_response_from_exception(500, e)

# def _text_response_from_exception(status_code, exc):
#     text = ''.join(traceback.format_exception(type(exc), exc, exc.__traceback__))
#     return plaintextresponse(status_code=status_code, content=text)

# ------------------ NEWS ENDPOINTS ------------------ #


@app.post('/news')
def api_create_news(news: NewsCreate):
    try:
        new_id = news_handler.create_news(
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
        news_list = news_handler.get_news_list()
        return {'news': news_list}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f'Error fetching news: {e}')


@app.get('/news/{news_id}')
def api_read_news(news_id: int):
    try:
        news_item = news_handler.get_news(news_id)
        return news_item
    except ValueError as ve:
        raise HTTPException(status_code=404, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f'Error retrieving news: {e}')


@app.get('/route_map')
def get_route_map(start: str, end: str):
    print('start:', start, 'end:', end)
    return map_handler.get_evacuate_map(start, end)


@app.put('/news/{news_id}')
def api_update_news(news_id: int, news: NewsUpdate):
    try:
        updated = news_handler.update_news(
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
        result = news_handler.delete_news(news_id)
        return result
    except ValueError as ve:
        raise HTTPException(status_code=404, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f'Error deleting news: {e}')
