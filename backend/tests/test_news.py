# # tests/test_news.py

# import os
# import sys
# import pytest
# from unittest.mock import MagicMock

# # Ensure the source path is available
# sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../src')))

# from src.news_handler import add_news_to_db, get_news_by_id, update_news, delete_news
# from src.utils.db_utils import _generate_id

# # Mock the get_connection function
# @pytest.fixture
# def mock_get_connection(monkeypatch):
#     mock_connection = MagicMock()
#     monkeypatch.setattr('src.utils.db_utils.get_connection', lambda: mock_connection)
#     return mock_connection

# def test_add_news_to_db(mock_get_connection):
#     """Test adding a news entry to the database."""
#     # Prepare mock cursor and result
#     mock_cursor = MagicMock()
#     mock_cursor.fetchone.return_value = ["news_123"]  # Simulate returned news ID
#     mock_get_connection.return_value.cursor.return_value.__enter__.return_value = mock_cursor
    
#     news_id = add_news_to_db("user_123", "https://example.com/image.jpg", "News Title", "Subtitle", "SRID=4326;POINT(-6.2603 53.3498)", 100)
    
#     # Verify that the function is calling SQL statements correctly
#     mock_cursor.execute.assert_called_with(
#         """
#         INSERT INTO news (news_id, author_id, cover_link, title, subtitle, location, views)
#         VALUES (%s, %s, %s, %s, %s, %s, %s)
#         RETURNING news_id;
#         """, ("news_123", "user_123", "https://example.com/image.jpg", "News Title", "Subtitle", "SRID=4326;POINT(-6.2603 53.3498)", 100)
#     )
    
#     # Verify that the function returned the correct news ID
#     assert news_id == "news_123"

# def test_get_news_by_id(mock_get_connection):
#     """Test retrieving a news entry by news_id."""
#     # Prepare mock cursor and result
#     mock_cursor = MagicMock()
#     mock_cursor.fetchone.return_value = {"news_id": "news_123", "title": "News Title", "subtitle": "Subtitle", "views": 100}
#     mock_get_connection.return_value.cursor.return_value.__enter__.return_value = mock_cursor
    
#     news = get_news_by_id("news_123")
    
#     # Verify that the function called the SQL query correctly
#     mock_cursor.execute.assert_called_with("SELECT * FROM news WHERE news_id = %s;", ("news_123",))
    
#     # Verify that the news data returned is correct
#     assert news == {"news_id": "news_123", "title": "News Title", "subtitle": "Subtitle", "views": 100}

# def test_update_news(mock_get_connection):
#     """Test updating a news entry."""
#     # Prepare mock cursor and result
#     mock_cursor = MagicMock()
#     mock_cursor.fetchone.return_value = ("news_123", "https://example.com/image.jpg", "Updated Title", "Updated Subtitle", "SRID=4326;POINT(-6.2603 53.3498)", 150)
#     mock_get_connection.return_value.cursor.return_value.__enter__.return_value = mock_cursor
    
#     updated_news = update_news("news_123", "https://example.com/image.jpg", "Updated Title", "Updated Subtitle", "SRID=4326;POINT(-6.2603 53.3498)", 150)
    
#     # Verify the correct SQL was executed
#     mock_cursor.execute.assert_called_with(
#         """
#         UPDATE news
#         SET cover_link = %s, title = %s, subtitle = %s, location = %s, views = %s
#         WHERE news_id = %s
#         RETURNING news_id, cover_link, title, subtitle, location, views;
#         """, ("https://example.com/image.jpg", "Updated Title", "Updated Subtitle", "SRID=4326;POINT(-6.2603 53.3498)", 150, "news_123")
#     )
    
#     # Verify that the returned news is correct
#     assert updated_news == ("news_123", "https://example.com/image.jpg", "Updated Title", "Updated Subtitle", "SRID=4326;POINT(-6.2603 53.3498)", 150)

# def test_delete_news(mock_get_connection):
#     """Test deleting a news entry."""
#     # Prepare mock cursor and simulate rowcount
#     mock_cursor = MagicMock()
#     mock_cursor.rowcount = 1  # Simulate that one row was deleted
#     mock_get_connection.return_value.cursor.return_value.__enter__.return_value = mock_cursor
    
#     response = delete_news("news_123")
    
#     # Verify that the delete SQL query was executed
#     mock_cursor.execute.assert_called_with("DELETE FROM news WHERE news_id = %s;", ("news_123",))
    
#     # Verify the correct message was returned
#     assert response == {"message": "News with news_id news_123 successfully deleted."}