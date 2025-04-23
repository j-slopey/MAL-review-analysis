SET search_path to group31;
DROP TABLE IF EXISTS user_ratings;
DROP TABLE IF EXISTS user_info;

CREATE TABLE user_ratings (
    user_id INTEGER,
    anime_id INTEGER,
    rating INTEGER
);

CREATE TABLE user_info (
    user_id INTEGER,
    username TEXT,
    gender TEXT,
    birthday DATE,
    user_location TEXT,
    date_joined DATE,
    days_watched FLOAT,
    mean_score FLOAT,
    watching_count FLOAT,
    completed_count FLOAT,
    hold_count FLOAT,
    dropped_count FLOAT,
    planning_count FLOAT,
    total_entries FLOAT,
    animes_rewatched FLOAT,
    episodes_rewatched FLOAT

);

\COPY user_ratings FROM 'data/user-filtered.csv' WITH (FORMAT CSV, HEADER);
\COPY user_info FROM 'data/users-details-2023.csv' WITH (FORMAT CSV, HEADER);

