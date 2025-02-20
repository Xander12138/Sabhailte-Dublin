from src.utils import db_utils


def create_user(username, email, password_hash, full_name):
    """Create a new user entry in the database.

    Returns:
        user_id (str): The ID of the newly created user.
    """
    return db_utils.add_user_to_db(username, email, password_hash, full_name)


def get_user(user_id):
    """Retrieve a single user entry by its ID.

    Args:
        user_id (str): The unique ID of the user.

    Returns:
        tuple: The user record.
    """
    return db_utils.get_user_by_id(user_id)


def get_users_list():
    """Retrieve a list of all users from the database.

    Returns:
        list: A list of user records.
    """
    return db_utils.get_all_users()


def update_user(user_id, username, email, password_hash, full_name):
    """Update an existing user's details.

    Returns:
        tuple: The updated user record.
    """
    return db_utils.update_user(user_id, username, email, password_hash, full_name)


def delete_user(user_id):
    """Delete a user from the database.

    Returns:
        dict: A message confirming deletion.
    """
    return db_utils.delete_user(user_id)
