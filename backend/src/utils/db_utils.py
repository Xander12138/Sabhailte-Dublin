import os
import uuid
from datetime import datetime, timezone

import psycopg2


def _get_connection():
    """Establish a connection to the database."""
    return psycopg2.connect(
        dbname=os.getenv('POSTGRES_DB'),
        user=os.getenv('POSTGRES_USER'),
        password=os.getenv('POSTGRES_PASSWORD'),
        host=os.getenv('POSTGRES_HOST'),
        port=os.getenv('POSTGRES_PORT'),
    )


# This will return "user_{UUID}" or "news_{UUID}" depending on type.
def _generate_id(type):
    """Generate a unique ID with a prefix."""
    prefixes = {
        'user': 'user_',
        'news': 'news_',
    }

    if type not in prefixes:
        raise ValueError('ID type is not supported')

    return prefixes[type] + uuid.uuid1().hex


def _current_utc_time():
    """Get the current UTC time."""
    return datetime.now(timezone.utc)


def _execute_multiple_sqls(sql_params_list: list):
    """Execute multiple SQL statements in a single transaction.

    Args:
        sql_params_list: list of tuples, each containing an SQL statement and its parameters.
        Example: [(sql, params), (sql, params), ...]
    """
    results = []
    with _get_connection() as conn:
        with conn.cursor() as cursor:
            for sql, params in sql_params_list:
                cursor.execute(sql, params)
                results.append(cursor.fetchall())
        conn.commit()
    return results


def _execute_sql_fetch_one(sql: str, params: tuple, *, cursor=None):
    """Execute an SQL query and fetch one result."""
    if cursor:
        cursor.execute(sql, params)
        return cursor.fetchone()

    with _get_connection() as conn:
        with conn.cursor() as cursor:
            cursor.execute(sql, params)
            return cursor.fetchone()


def _execute_sql_fetch_all(sql: str, params: tuple, *, cursor=None):
    """Execute an SQL query and fetch all results."""
    if cursor:
        cursor.execute(sql, params)
        return cursor.fetchall()

    with _get_connection() as conn:
        with conn.cursor() as cursor:
            cursor.execute(sql, params)
            return cursor.fetchall()


def _batch_execute_sql_fetch_all(sql: str, params: list, *, cursor=None, returning=True):
    """Execute multiple SQL queries in a batch and fetch all results."""
    if cursor:
        cursor.executemany(sql, params, returning=returning)
        rows = []
        row_count = cursor.rowcount
        if row_count > 0 and returning:
            while True:
                rows.append(cursor.fetchone())
                if not cursor.nextset():
                    break
        return rows

    with _get_connection() as conn:
        with conn.cursor() as cursor:
            cursor.executemany(sql, params, returning=returning)
            rows = []
            row_count = cursor.rowcount
            if row_count > 0 and returning:
                while True:
                    rows.append(cursor.fetchone())
                    if not cursor.nextset():
                        break
            return rows


# NEWS FUNCTIONS


def add_news_to_db(author_id, cover_link, title, subtitle, location, views=0):
    """Add a news entry to the database with a generated ID."""
    try:
        news_id = _generate_id('news')
        sql = """
            INSERT INTO news (news_id, author_id, cover_link, title, subtitle, location, views)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING news_id;
        """
        result = _execute_sql_fetch_one(sql, (news_id, author_id, cover_link, title, subtitle, location, views))
        return result[0] if result else None
    except Exception as e:
        raise Exception(f'Error adding news to the database: {e}')


def get_news_list():
    """Retrieve a list of all news entries using helper functions."""
    sql = 'SELECT * FROM news;'
    try:
        news_list = _execute_sql_fetch_all(sql, ())
        return news_list
    except Exception as e:
        raise Exception(f'Error retrieving news list: {e}')


def get_news_by_id(news_id):
    """Retrieve a news entry by its news_id using helper functions."""
    sql = 'SELECT * FROM news WHERE news_id = %s;'
    try:
        result = _execute_sql_fetch_one(sql, (news_id,))
        if result:
            return result
        else:
            raise ValueError(f'News with news_id{news_id} not found')
    except Exception as e:
        raise Exception(f'Error retrieving news with news_id{news_id}: {e}')


def update_news(news_id, cover_link, title, subtitle, location, views):
    """Update the details of an existing news entry using a helper function."""
    sql = """
        UPDATE news
        SET cover_link = %s, title = %s, subtitle = %s, location = %s, views = %s
        WHERE news_id = %s
        RETURNING news_id, cover_link, title, subtitle, location, views;
    """
    try:
        updated_news = _execute_sql_fetch_one(sql, (cover_link, title, subtitle, location, views, news_id))
        if updated_news:
            return updated_news
        else:
            raise ValueError(f'News with news_id {news_id} not found.')
    except Exception as e:
        raise Exception(f'Error updating news with news_id {news_id}: {e}')


def delete_news(news_id):
    """Delete a news entry from the database using a helper function."""
    sql = 'DELETE FROM news WHERE news_id = %s RETURNING news_id;'
    try:
        deleted = _execute_sql_fetch_one(sql, (news_id,))
        if not deleted:
            raise ValueError(f'News with news_id {news_id} not found.')
        return {'message': f'News with news_id {news_id} successfully deleted.'}
    except Exception as e:
        raise Exception(f'Error deleting news with news_id {news_id}: {e}')


# USER FUNCTIONS


def add_user_to_db(username, email, password_hash, full_name):
    """Add a user entry to the database with a generated ID."""
    try:
        user_id = _generate_id('user')
        sql = """
            INSERT INTO users (user_id, username, email, password_hash, full_name)
            VALUES (%s, %s, %s, %s, %s)
            RETURNING user_id;
        """
        result = _execute_sql_fetch_one(sql, (user_id, username, email, password_hash, full_name))
        return result[0] if result else None
    except Exception as e:
        raise Exception(f'Error adding user to the database: {e}')


def get_user_by_id(user_id):
    """Retrieve a user by their user_id."""
    sql = 'SELECT * FROM users WHERE user_id = %s;'
    try:
        return _execute_sql_fetch_one(sql, (user_id,))
    except Exception as e:
        raise Exception(f'Error retrieving user with user_id {user_id}: {e}')


def get_all_users():
    """Retrieve all users from the database."""
    sql = 'SELECT * FROM users;'
    try:
        return _execute_sql_fetch_all(sql, ())
    except Exception as e:
        raise Exception(f'Error retrieving users: {e}')


def update_user(user_id, username, email, password_hash, full_name):
    """Update user details."""
    sql = """
        UPDATE users
        SET username = %s, email = %s, password_hash = %s, full_name = %s
        WHERE user_id = %s
        RETURNING user_id, username, email, full_name;
    """
    try:
        updated_user = _execute_sql_fetch_one(sql, (username, email, password_hash, full_name, user_id))
        if updated_user:
            return updated_user
        else:
            raise ValueError(f'User with user_id {user_id} not found.')
    except Exception as e:
        raise Exception(f'Error updating user with user_id {user_id}: {e}')


def delete_user(user_id):
    """Delete a user from the database."""
    sql = 'DELETE FROM users WHERE user_id = %s RETURNING user_id;'
    try:
        deleted = _execute_sql_fetch_one(sql, (user_id,))
        if not deleted:
            raise ValueError(f'User with user_id {user_id} not found.')
        return {'message': f'User with user_id {user_id} successfully deleted.'}
    except Exception as e:
        raise Exception(f'Error deleting user with user_id {user_id}: {e}')
