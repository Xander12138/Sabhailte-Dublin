import pytest
from src import users_handler

def test_create_user(monkeypatch):
    # Fake db_utils.add_user_to_db returns a dummy user_id.
    def fake_add_user_to_db(username, password, email, full_name):
        return "user_test_id"
    
    monkeypatch.setattr(users_handler.db_utils, "add_user_to_db", fake_add_user_to_db)
    
    result = users_handler.create_user("testuser", "password123", "test@example.com", "John Doe")
    assert result == "user_test_id"


def test_get_user_list(monkeypatch):
    fake_user_list = [
        ("user1", "username1", "user1@example.com"),
        ("user2", "username2", "user2@example.com"),
    ]
    
    def fake_get_user_list():
        return fake_user_list
    
    monkeypatch.setattr(users_handler.db_utils, "get_all_users", fake_get_user_list)
    
    result = users_handler.get_users_list()
    assert result == fake_user_list


def test_get_user(monkeypatch):
    fake_user = ("user1", "username1", "user1@example.com")
    
    def fake_get_user_by_id(user_id):
        if user_id == "user1":
            return fake_user
        return None
    
    monkeypatch.setattr(users_handler.db_utils, "get_user_by_id", fake_get_user_by_id)
    
    result = users_handler.get_user("user1")
    assert result == fake_user


def test_update_user(monkeypatch):
    fake_updated_user = ("user1", "username_updated", "updated@example.com")
    
    def fake_update_user(user_id, username, email, password_hash, full_name):
        return fake_updated_user
    
    monkeypatch.setattr(users_handler.db_utils, "update_user", fake_update_user)
    
    result = users_handler.update_user("user1", "username_updated", "updated@example.com", password_hash="pass123", full_name="john doe")
    assert result == fake_updated_user


def test_delete_user(monkeypatch):
    fake_delete_message = {"message": "User with user1 successfully deleted."}
    
    def fake_delete_user(user_id):
        return fake_delete_message
    
    monkeypatch.setattr(users_handler.db_utils, "delete_user", fake_delete_user)
    
    result = users_handler.delete_user("user1")
    assert result == fake_delete_message
