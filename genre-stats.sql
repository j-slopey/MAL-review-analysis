-- Query determines rankings of anime by genre for genres with at least 500 shows
SELECT genre, AVG(score) AS average_score
FROM anime_info JOIN anime_genres USING(anime_id)
GROUP BY genre
HAVING COUNT(genre) > 500
ORDER BY average_score DESC
LIMIT 5;

-- Query determines drop rate of anime by genre for genres with at least 500 shows
SELECT genre, AVG(dropped_count::FLOAT/viewer_count) AS drop_rate
FROM anime_stats JOIN anime_genres USING(anime_id) 
GROUP BY genre
HAVING COUNT(genre) > 500
ORDER BY drop_rate DESC
LIMIT 5;

-- Query determines completion rate of anime by genre for genres with at least 500 shows
SELECT genre, AVG(completed_count::FLOAT/viewer_count) AS completion_rate
FROM anime_stats JOIN anime_genres USING(anime_id) 
GROUP BY genre
HAVING COUNT(genre) > 500
ORDER BY completion_rate DESC
LIMIT 5;