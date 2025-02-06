# import json
# import os

import pandas as pd
# import psycopg2
from src.utils import db_utils


class News:

    @staticmethod
    def getAll():
        conn = db_utils.DB.conn
        sql = """
		SELECT
			id,
			cover_link,
			title1,
			title2,
			TO_CHAR(date, 'YYYY-MM-DD HH24:MI:SS') AS date,
			location,
			views
		FROM news;
        """
        df = pd.read_sql_query(sql, conn)
        data = df.to_dict(orient='records')
        return data

    @staticmethod
    def getOne(news_id):
        conn = db_utils.DB.conn
        sql = """
		SELECT
			id,
			cover_link,
			title1,
			title2,
			TO_CHAR(date, 'YYYY-MM-DD HH24:MI:SS') AS date,
			location,
			views
		FROM news
        WHERE id = {}
        """.format(news_id)
        df = pd.read_sql_query(sql, conn)
        data = df.to_dict(orient='records')
        return data[0] if len(data) else ''

    @staticmethod
    def delete(news_id):
        conn = db_utils.DB.conn
        sql = """
        UPDATE news
        SET flag = 1
        WHERE id = {}
        """.format(news_id)
        cur = conn.cursor()
        cur.execute(sql)
        print(sql)
        return 'success'
