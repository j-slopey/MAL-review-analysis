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


CRATE TABLE anime_info(
    anime_id INTEGER,
    anime_name TEXT,
    score FLOAT,
    synopsis TEXT,
    format TEXT,
    ep_count INTEGER,
    airing_start DATE,
    airing_end DATE,
    premiere_date DATE,
    source_material TEXT,
    episode_duration INTERVAL,
    age_rating TEXT,
)

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
)

CREATE TABLE anime_producers (
    anime_id INTEGER,
    producer TEXT
)

CREATE TABLE anime_studios (
    anime_id INTEGER,
    studio TEXT

)

CREATE TABLE anime_licensors (
    anime_id INTEGER,
    licensor TEXT
)

CREATE TABLE anime_genres (
    anime_id INTEGER,
    genre TEXT

)

-- Move data from raw table to organized schema
INSERT INTO anime_info (
    anime_id,
    anime_name,
    score,
    synopsis,
    format,
    ep_count,
    airing_start,
    airing_end,
    source_material,
    episode_duration,
    age_rating
)
SELECT
    anime_id,
    anime_name,
    score,
    synopsis, 
    NULLIF(trim(format), 'Unknown'),
    NULLIF(ep_count, 'Unknown')::INTEGER,
    CASE
        WHEN aired IS NULL OR trim(aired) = '' OR trim(aired) = 'Unknown' THEN NULL
        ELSE trim(split_part(aired, ' to ', 1))::DATE
    END AS airing_start,

    CASE
        WHEN aired IS NULL OR trim(aired) = '' OR trim(aired) = 'Unknown' THEN NULL
        WHEN aired LIKE '% to %' THEN trim(split_part(aired, ' to ', 2))::DATE,
        ELSE trim(split_part(aired, ' to ', 1))::DATE,
    END AS airing_end,

    NULLIF(trim(source_material), 'Unknown'),

    CASE
        WHEN episode_duration LIKE '% per ep.'
        -- TODO
    END AS episode_duration,

    NULLIF(trim(age_rating), 'Unknown')

FROM
    anime_filtered_raw;