from typing import List

import fastapi
from fastapi import HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from src.router import news
from src.utils import db_utils
from src.map_handler import get_evacuate_map

app = fastapi.FastAPI()

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

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex='http.*',
    allow_credentials=True,
    allow_methods=['*'],
    allow_headers=['*'],
)


# Pydantic model for disaster data
class Disaster(BaseModel):
    title: str
    description: str
    time: str
    location: str


# Class to manage WebSocket connections
class ConnectionManager:

    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def broadcast(self, message: bytes):
        for connection in self.active_connections:
            try:
                await connection.send_bytes(message)
            except WebSocketDisconnect:
                self.disconnect(connection)


manager = ConnectionManager()


@app.get('/')
def read_root():
    return {'message': 'Welcome to the FastAPI Backend!'}


@app.get('/db')
def read_db():
    db_version = db_utils.get_version()
    return {'db_version': db_version}


@app.post('/api/disasters')
def add_disaster(data: Disaster):
    try:
        # Store the disaster data in the PostgreSQL database
        inserted_id = db_utils.add_news_to_db(data.title, data.description, data.time, data.location)
        return {'message': 'Disaster added successfully', 'id': inserted_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f'An error occurred: {e}')


@app.get('/api/disasters')
def get_disasters():
    try:
        # Retrieve all disasters from the PostgreSQL database
        disasters = db_utils.get_news_list()
        if not disasters:
            raise HTTPException(status_code=404, detail='No disaster data found.')
        return {'disasters': disasters}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f'An error occurred: {e}')


# WebSocket endpoint for live streaming
@app.websocket('/ws/stream')
async def stream_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            # Receive binary data (video frames) from the streamer
            data = await websocket.receive_bytes()
            # Broadcast the data to all connected viewers
            await manager.broadcast(data)
    except WebSocketDisconnect:
        manager.disconnect(websocket)
    except Exception as e:
        print(f'WebSocket error: {e}')


@app.get('/news')
def get_news_list():
    return news.News.getAll()


@app.get('/news/{_id}')
def get_news(_id: int):
    return news.News.getOne(_id)


@app.delete('/news/{_id}')
def delete_news(_id: int):
    return news.News.delete(_id)

@app.get('/route_map')
def get_route_map():
    return get_evacuate_map()
