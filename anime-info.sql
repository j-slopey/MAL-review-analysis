-- SET search_path to group31;
DROP TABLE IF EXISTS anime_filtered_raw;

-- Create single table with all original columns
CREATE TEMP TABLE anime_filtered_raw (
    anime_id INTEGER,
    anime_name TEXT,
    score FLOAT,
    genres TEXT,
    english_name TEXT,
    japanese_name TEXT,
    synopsis TEXT,
    format TEXT,
    ep_count TEXT,
    aired TEXT,
    premiered TEXT,
    producers TEXT,
    licensors TEXT,
    studios TEXT,
    source_material TEXT,
    episode_duration TEXT,
    age_rating TEXT,
    ranking FLOAT,
    popularity INTEGER,
    viewer_count INTEGER,
    viewer_favorite_count INTEGER,
    currently_watching_count INTEGER,
    completed_count INTEGER,
    hold_count INTEGER,
    dropped_count INTEGER
);

-- Copy data from CSV
\COPY anime_filtered_raw FROM 'data/anime-filtered.csv' WITH (FORMAT CSV, HEADER);

-- Create Desired Tables
DROP TABLE IF EXISTS anime_info;
DROP TABLE IF EXISTS anime_stats;
DROP TABLE IF EXISTS anime_producers;
DROP TABLE IF EXISTS anime_studios;
DROP TABLE IF EXISTS anime_licensors;
DROP TABLE IF EXISTS anime_genres;


CREATE TABLE anime_info(
    anime_id INTEGER,
    anime_name TEXT,
    score FLOAT,
    synopsis TEXT,
    format TEXT,
    ep_count INTEGER,
    start_year INTEGER,
    end_year INTEGER,
    premiere_date DATE,
    source_material TEXT,
    episode_duration INTERVAL,
    age_rating TEXT
);

CREATE TABLE anime_stats (
    anime_id INTEGER,
    ranking FLOAT,
    popularity INTEGER,
    viewer_count INTEGER,
    viewer_favorite_count INTEGER,
    currently_watching_count INTEGER,
    completed_count INTEGER,
    hold_count INTEGER,
    dropped_count INTEGER
);

CREATE TABLE anime_producers (
    anime_id INTEGER,
    producer TEXT
);

CREATE TABLE anime_studios (
    anime_id INTEGER,
    studio TEXT

);

CREATE TABLE anime_licensors (
    anime_id INTEGER,
    licensor TEXT
);

CREATE TABLE anime_genres (
    anime_id INTEGER,
    genre TEXT

);

-- Move data from raw table to organized schema
INSERT INTO anime_info (
    anime_id,
    anime_name,
    score,
    synopsis,
    format,
    ep_count,
    start_year,
    end_year,
    source_material,
    episode_duration,
    age_rating
)
SELECT
    anime_id,
    anime_name,
    score,
    synopsis,
    format,
    CASE
        WHEN ep_count IS NULL OR trim(ep_count) = 'Unknown' THEN NULL
        ELSE trim(ep_count)::INTEGER
    END, 

    CASE
        WHEN aired IS NULL OR trim(aired) = 'Unknown' THEN NULL
        ELSE substring(trim(split_part(aired, ' to ', 1)) from '\d{4}')::INTEGER
    END AS start_year,

    CASE
        WHEN aired IS NULL OR trim(aired) = 'Unknown' OR trim(aired) LIKE '% to ?' THEN NULL
        WHEN aired LIKE '% to %' THEN substring(trim(split_part(aired, ' to ', 2)) from '\d{4}')::INTEGER
        ELSE substring(trim(aired) from '\d{4}')::INTEGER
    END AS end_year,

    source_material,

    CASE
        WHEN episode_duration IS NULL OR trim(episode_duration) = 'Unknown' THEN NULL
        WHEN episode_duration LIKE '% per ep.' THEN REPLACE(substring(episode_duration FROM 1 FOR length(episode_duration) - 8), '.', '')::INTERVAL
        ELSE REPLACE(episode_duration, '.', '')::INTERVAL
    END AS episode_duration,

    age_rating

FROM
    anime_filtered_raw;


INSERT INTO anime_stats (
    anime_id, ranking, popularity, viewer_count, viewer_favorite_count,
    currently_watching_count, completed_count, hold_count, dropped_count
)
SELECT
    anime_id, ranking, popularity, viewer_count, viewer_favorite_count,
    currently_watching_count, completed_count, hold_count, dropped_count
FROM
    anime_filtered_raw;


INSERT INTO anime_producers (anime_id, producer)
SELECT
    anime_id,
    trim(unnest(string_to_array(producers, ',')))
FROM
    anime_filtered_raw;


INSERT INTO anime_studios (anime_id, studio)
SELECT
    anime_id,
    trim(unnest(string_to_array(studios, ',')))
FROM
    anime_filtered_raw;


INSERT INTO anime_licensors (anime_id, licensor)
SELECT
    anime_id,
    trim(unnest(string_to_array(licensors, ',')))
FROM
    anime_filtered_raw;


INSERT INTO anime_genres (anime_id, genre)
SELECT
    anime_id,
    trim(unnest(string_to_array(genres, ',')))
FROM
    anime_filtered_raw;
