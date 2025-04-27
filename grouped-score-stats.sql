-- Average rating given by each user grouped by the number of ratings they have given
WITH rating_stats AS (
    SELECT COUNT(rating) AS num_ratings, mean_score
    FROM user_info JOIN user_ratings USING(user_id)
    WHERE mean_score != 0
    GROUP BY user_id, mean_score
),
percentiles AS (
    SELECT 
    (percentile_cont(0.25) WITHIN GROUP (ORDER BY num_ratings)) AS p_25,
    (percentile_cont(0.5) WITHIN GROUP (ORDER BY num_ratings)) AS p_50,
    (percentile_cont(0.75) WITHIN GROUP (ORDER BY num_ratings)) AS p_75,
    (percentile_cont(0.99) WITHIN GROUP (ORDER BY num_ratings)) AS p_99
    FROM rating_stats
),
filtered AS (
    SELECT * FROM rating_stats WHERE num_ratings <= (SELECT p_99 FROM percentiles)
),
grouped AS (
    SELECT num_ratings, mean_score,
    CASE
        WHEN num_ratings > 0 AND num_ratings <= (SELECT p_25 FROM percentiles) THEN '< 25th percentile'
        WHEN num_ratings > (SELECT p_25 FROM percentiles) AND num_ratings <= (SELECT p_50 FROM percentiles) THEN '25th to 50th percentile'
        WHEN num_ratings > (SELECT p_50 FROM percentiles) AND num_ratings <= (SELECT p_75 FROM percentiles) THEN '50th to 75th percentile'
        WHEN num_ratings > (SELECT p_75 FROM percentiles) AND num_ratings <= (SELECT p_99 FROM percentiles) THEN '75th to 99th percentile'
        ELSE 'Invalid Count'
    END AS grouping
    FROM filtered
)
SELECT grouping, AVG(mean_score) AS avg_rating 
FROM grouped GROUP BY grouping ORDER BY grouping; 

