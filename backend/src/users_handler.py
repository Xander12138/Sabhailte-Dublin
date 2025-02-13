# import uuid

# from utils.db_utils import _generate_id, get_connection

# def add_user_to_db(username, email):
#     """Add a new user to the database."""
#     try:
#         user_id = _generate_id('user')  # Generate a unique user ID
#         with get_connection() as conn:
#             with conn.cursor() as cur:
#                 cur.execute(
#                     """
#                     INSERT INTO users (user_id, username, email)
#                     VALUES (%s, %s, %s)
#                     RETURNING user_id;
#                     """,
#                     (user_id, username, email),
#                 )
#                 new_user_id = cur.fetchone()[0]
#                 return new_user_id
#     except Exception as e:
#         raise Exception(f'Error adding user to the database: {e}')

# def get_user_by_id(user_id):
#     """Retrieve a user by their user_id."""
#     try:
#         with get_connection() as conn:
#             with conn.cursor() as cur:
#                 cur.execute('SELECT * FROM users WHERE user_id = %s;', (user_id,))
#                 user = cur.fetchone()
#                 if user:
#                     return user
#                 else:
#                     raise ValueError(f'User with user_id {user_id} not found.')
#     except Exception as e:
#         raise Exception(f'Error retrieving user with user_id {user_id}: {e}')

# def update_user(user_id, username, email):
#     """Update the username and email for an existing user."""
#     try:
#         with get_connection() as conn:
#             with conn.cursor() as cur:
#                 cur.execute(
#                     """
#                     UPDATE users
#                     SET username = %s, email = %s
#                     WHERE user_id = %s
#                     RETURNING user_id, username, email;
#                     """,
#                     (username, email, user_id),
#                 )
#                 updated_user = cur.fetchone()
#                 if updated_user:
#                     return updated_user
#                 else:
#                     raise ValueError(f'User with user_id {user_id} not found.')
#     except Exception as e:
#         raise Exception(f'Error updating user with user_id {user_id}: {e}')

# def delete_user(user_id):
#     """Delete a user from the database."""
#     try:
#         with get_connection() as conn:
#             with conn.cursor() as cur:
#                 cur.execute('DELETE FROM users WHERE user_id = %s;', (user_id,))
#                 if cur.rowcount == 0:
#                     raise ValueError(f'User with user_id {user_id} not found.')
#                 conn.commit()
#                 return {'message': f'User with user_id {user_id} successfully deleted.'}
#     except Exception as e:
#         raise Exception(f'Error deleting user with user_id {user_id}: {e}')
