# import pytest
# from unittest.mock import MagicMock

# from src.users_handler import add_user_to_db, get_user_by_id, update_user, delete_user
# from src.utils.db_utils import _generate_id

# # Mock the get_connection function
# @pytest.fixture
# def mock_get_connection(monkeypatch):
#     mock_connection = MagicMock()
#     monkeypatch.setattr('src.utils.db_utils.get_connection', lambda: mock_connection)
#     return mock_connection

# def test_add_user_to_db(mock_get_connection):
#     """Test adding a user to the database."""
#     # Prepare mock cursor and result
#     mock_cursor = MagicMock()
#     mock_cursor.fetchone.return_value = ["user_123"]  # Simulate returned user ID
#     mock_get_connection.return_value.cursor.return_value.__enter__.return_value = mock_cursor
    
#     user_id = add_user_to_db("john_doe", "john.doe@example.com")
    
#     # Verify that the function is calling SQL statements correctly
#     mock_cursor.execute.assert_called_with(
#         """
#         INSERT INTO users (user_id, username, email)
#         VALUES (%s, %s, %s)
#         RETURNING user_id;
#         """, ("user_123", "john_doe", "john.doe@example.com")
#     )
    
#     # Verify that the function returned the correct user ID
#     assert user_id == "user_123"

# def test_get_user_by_id(mock_get_connection):
#     """Test retrieving a user by user_id."""
#     # Prepare mock cursor and result
#     mock_cursor = MagicMock()
#     mock_cursor.fetchone.return_value = {"user_id": "user_123", "username": "john_doe", "email": "john.doe@example.com"}
#     mock_get_connection.return_value.cursor.return_value.__enter__.return_value = mock_cursor
    
#     user = get_user_by_id("user_123")
    
#     # Verify that the function called the SQL query correctly
#     mock_cursor.execute.assert_called_with("SELECT * FROM users WHERE user_id = %s;", ("user_123",))
    
#     # Verify that the user data returned is correct
#     assert user == {"user_id": "user_123", "username": "john_doe", "email": "john.doe@example.com"}

# def test_update_user(mock_get_connection):
#     """Test updating a user."""
#     # Prepare mock cursor and result
#     mock_cursor = MagicMock()
#     mock_cursor.fetchone.return_value = ("user_123", "john_doe_updated", "john.doe.updated@example.com")
#     mock_get_connection.return_value.cursor.return_value.__enter__.return_value = mock_cursor
    
#     updated_user = update_user("user_123", "john_doe_updated", "john.doe.updated@example.com")
    
#     # Verify the correct SQL was executed
#     mock_cursor.execute.assert_called_with(
#         """
#         UPDATE users
#         SET username = %s, email = %s
#         WHERE user_id = %s
#         RETURNING user_id, username, email;
#         """, ("john_doe_updated", "john.doe.updated@example.com", "user_123")
#     )
    
#     # Verify that the returned user is correct
#     assert updated_user == ("user_123", "john_doe_updated", "john.doe.updated@example.com")

# def test_delete_user(mock_get_connection):
#     """Test deleting a user."""
#     # Prepare mock cursor and simulate rowcount
#     mock_cursor = MagicMock()
#     mock_cursor.rowcount = 1  # Simulate that one row was deleted
#     mock_get_connection.return_value.cursor.return_value.__enter__.return_value = mock_cursor
    
#     response = delete_user("user_123")
    
#     # Verify that the delete SQL query was executed
#     mock_cursor.execute.assert_called_with("DELETE FROM users WHERE user_id = %s;", ("user_123",))
    
#     # Verify the correct message was returned
#     assert response == {"message": "User with user_id user_123 successfully deleted."}
