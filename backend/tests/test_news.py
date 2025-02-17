import pytest
from src import news_handler

def test_create_news(monkeypatch):
    # Fake db_utils.add_news_to_db returns a dummy news_id.
    def fake_add_news_to_db(author_id, cover_link, title, subtitle, location, views=0):
        return "news_test_id"
    
    monkeypatch.setattr(news_handler.db_utils, "add_news_to_db", fake_add_news_to_db)
    
    result = news_handler.create_news("author_test", "cover_link", "title", "subtitle", "location", 0)
    assert result == "news_test_id"


def test_get_news_list(monkeypatch):
    fake_news_list = [
        ("news1", "author1", "link1", "title1", "subtitle1", "location1", 0),
        ("news2", "author2", "link2", "title2", "subtitle2", "location2", 10),
    ]
    
    def fake_get_news_list():
        return fake_news_list
    
    monkeypatch.setattr(news_handler.db_utils, "get_news_list", fake_get_news_list)
    
    result = news_handler.get_news_list()
    assert result == fake_news_list


def test_get_news(monkeypatch):
    fake_news = ("news1", "author1", "link1", "title1", "subtitle1", "location1", 0)
    
    def fake_get_news_by_id(news_id):
        if news_id == "news1":
            return fake_news
        return None
    
    monkeypatch.setattr(news_handler.db_utils, "get_news_by_id", fake_get_news_by_id)
    
    result = news_handler.get_news("news1")
    assert result == fake_news


def test_update_news(monkeypatch):
    fake_updated_news = ("news1", "link_updated", "title_updated", "subtitle_updated", "location_updated", 5)
    
    def fake_update_news(news_id, cover_link, title, subtitle, location, views):
        return fake_updated_news
    
    monkeypatch.setattr(news_handler.db_utils, "update_news", fake_update_news)
    
    result = news_handler.update_news("news1", "link_updated", "title_updated", "subtitle_updated", "location_updated", 5)
    assert result == fake_updated_news


def test_delete_news(monkeypatch):
    fake_delete_message = {"message": "News with news1 successfully deleted."}
    
    def fake_delete_news(news_id):
        return fake_delete_message
    
    monkeypatch.setattr(news_handler.db_utils, "delete_news", fake_delete_news)
    
    result = news_handler.delete_news("news1")
    assert result == fake_delete_message