import os
import uuid
from datetime import datetime, timezone

import psycopg2


class DB:
    """Database connection handler."""
    conn = psycopg2.connect(
        dbname=os.getenv('POSTGRES_DB'),
        user=os.getenv('POSTGRES_USER'),
        password=os.getenv('POSTGRES_PASSWORD'),
        host=os.getenv('POSTGRES_HOST'),
        port=os.getenv('POSTGRES_PORT'),
    )


def get_connection():
    """Establish a connection to the database."""
    return psycopg2.connect(
        dbname=os.getenv('POSTGRES_DB'),
        user=os.getenv('POSTGRES_USER'),
        password=os.getenv('POSTGRES_PASSWORD'),
        host=os.getenv('POSTGRES_HOST'),
        port=os.getenv('POSTGRES_PORT'),
    )


def _generate_id(type):
    """Generate a unique ID with a prefix."""
    prefixes = {
        'user': 'u_',
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
    with get_connection() as conn:
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

    with get_connection() as conn:
        with conn.cursor() as cursor:
            cursor.execute(sql, params)
            return cursor.fetchone()


def _execute_sql_fetch_all(sql: str, params: tuple, *, cursor=None):
    """Execute an SQL query and fetch all results."""
    if cursor:
        cursor.execute(sql, params)
        return cursor.fetchall()

    with get_connection() as conn:
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

    with get_connection() as conn:
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


def add_news_to_db(title, description, time, location):
    """Add a disaster to the database."""
    return _execute_sql_fetch_one(
        """
        INSERT INTO disasters (title, description, time, location)
        VALUES (%s, %s, %s, %s)
        RETURNING id;
        """,
        (title, description, time, location),
    )[0]


def get_news_list():
    """Retrieve all disasters from the database."""
    return _execute_sql_fetch_all('SELECT * FROM disasters', ())
