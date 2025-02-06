import os

import psycopg2
from psycopg2.extras import RealDictCursor


class DB:
    conn = psycopg2.connect(
        dbname=os.getenv('POSTGRES_DB'),
        user=os.getenv('POSTGRES_USER'),
        password=os.getenv('POSTGRES_PASSWORD'),
        host=os.getenv('POSTGRES_HOST'),
        port=os.getenv('POSTGRES_PORT'),
    )


def get_version():
    """Get the PostgreSQL version."""
    conn = psycopg2.connect(
        dbname=os.getenv('POSTGRES_DB'),
        user=os.getenv('POSTGRES_USER'),
        password=os.getenv('POSTGRES_PASSWORD'),
        host=os.getenv('POSTGRES_HOST'),
        port=os.getenv('POSTGRES_PORT'),
    )
    cur = conn.cursor()
    cur.execute('SELECT version();')
    db_version = cur.fetchone()
    cur.close()
    conn.close()
    return db_version


def get_connection():
    """Establish a connection to the database."""
    return psycopg2.connect(
        dbname=os.getenv('POSTGRES_DB'),
        user=os.getenv('POSTGRES_USER'),
        password=os.getenv('POSTGRES_PASSWORD'),
        host=os.getenv('POSTGRES_HOST'),
        port=os.getenv('POSTGRES_PORT'),
    )


def add_disaster_to_db(title, description, time, location):
    """Add a disaster to the database."""
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            """
            INSERT INTO disasters (title, description, time, location)
            VALUES (%s, %s, %s, %s)
            RETURNING id;
            """,
            (title, description, time, location),
        )
        disaster_id = cur.fetchone()[0]
        conn.commit()
        return disaster_id
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        cur.close()
        conn.close()


def get_all_disasters():
    """Retrieve all disasters from the database."""
    conn = get_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    try:
        cur.execute('SELECT * FROM disasters;')
        disasters = cur.fetchall()
        return disasters
    except Exception as e:
        raise e
    finally:
        cur.close()
        conn.close()
