from src.utils import db_utils


def create_news(author_id, cover_link, title, subtitle, location, views=0):
    """Create a new news entry by adding it to the database.

    Returns:
        news_id (str): The ID of the newly created news entry.
    """
    return db_utils.add_news_to_db(author_id, cover_link, title, subtitle, location, views)


def get_news_list():
    """Retrieve a list of all news entries from the database.

    Returns:
        list: A list of news records.
    """
    return db_utils.get_news_list()


def get_news(news_id):
    """Retrieve a single news entry by its ID.

    Args:
        news_id (str): The unique ID of the news entry.

    Returns:
        tuple: The news record.
    """
    return db_utils.get_news_by_id(news_id)


def update_news(news_id, cover_link, title, subtitle, location, views):
    """Update an existing news entry.

    Returns:
        tuple: The updated news record.
    """
    return db_utils.update_news(news_id, cover_link, title, subtitle, location, views)


def delete_news(news_id):
    """Delete a news entry from the database.

    Returns:
        dict: A message confirming deletion.
    """
    return db_utils.delete_news(news_id)
