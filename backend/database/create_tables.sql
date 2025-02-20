-- SQL file for initial DB setup

-- =====================================
-- NEWS TABLE (News Page)
-- =====================================

CREATE TABLE users (
    user_id VARCHAR(50) PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL
);

-- =====================================
-- NEWS TABLE (News Page)
-- =====================================

CREATE TABLE news (
    news_id VARCHAR(50) PRIMARY KEY,
    author_id VARCHAR(50) NOT NULL,
    cover_link TEXT NOT NULL,
    title VARCHAR(255) NOT NULL,
    subtitle VARCHAR(255),
    published_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    location VARCHAR(100) NOT NULL,
    views INT DEFAULT 0 CHECK (views >= 0),
    CONSTRAINT fk_news_author FOREIGN KEY (author_id) REFERENCES users(user_id) ON DELETE CASCADE
);


-- =====================================
-- NEWS_DETAILS TABLE (News Page)
-- =====================================

CREATE TABLE news_details (
    news_id VARCHAR(50) PRIMARY KEY,
    summary TEXT NOT NULL,
    CONSTRAINT fk_news_details FOREIGN KEY (news_id) REFERENCES news(news_id) ON DELETE CASCADE
);
