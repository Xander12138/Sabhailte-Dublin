# src/news_handler.py

from src.utils.db_utils import _generate_id, get_connection


def add_news_to_db(author_id, cover_link, title, subtitle, location, views=0):
    """Add a new news entry to the database."""
    try:
        news_id = _generate_id('news')  # Generate a unique news ID
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    INSERT INTO news (news_id, author_id, cover_link, title, subtitle, location, views)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                    RETURNING news_id;
                    """,
                    (news_id, author_id, cover_link, title, subtitle, location, views),
                )
                new_news_id = cur.fetchone()[0]
                return new_news_id
    except Exception as e:
        raise Exception(f'Error adding news to the database: {e}')


def get_news_by_id(news_id):
    """Retrieve a news entry by its news_id."""
    try:
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute('SELECT * FROM news WHERE news_id = %s;', (news_id,))
                news = cur.fetchone()
                if news:
                    return news
                else:
                    raise ValueError(f'News with news_id {news_id} not found.')
    except Exception as e:
        raise Exception(f'Error retrieving news with news_id {news_id}: {e}')


def update_news(news_id, cover_link, title, subtitle, location, views):
    """Update the details of an existing news entry."""
    try:
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    UPDATE news
                    SET cover_link = %s, title = %s, subtitle = %s, location = %s, views = %s
                    WHERE news_id = %s
                    RETURNING news_id, cover_link, title, subtitle, location, views;
                    """,
                    (cover_link, title, subtitle, location, views, news_id),
                )
                updated_news = cur.fetchone()
                if updated_news:
                    return updated_news
                else:
                    raise ValueError(f'News with news_id {news_id} not found.')
    except Exception as e:
        raise Exception(f'Error updating news with news_id {news_id}: {e}')


def delete_news(news_id):
    """Delete a news entry from the database."""
    try:
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute('DELETE FROM news WHERE news_id = %s;', (news_id,))
                if cur.rowcount == 0:
                    raise ValueError(f'News with news_id {news_id} not found.')
                conn.commit()
                return {'message': f'News with news_id {news_id} successfully deleted.'}
    except Exception as e:
        raise Exception(f'Error deleting news with news_id {news_id}: {e}')
