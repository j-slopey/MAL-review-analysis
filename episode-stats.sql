-- Ep count vs completion rate for all TV shows
SELECT ep_count, completed_count::FLOAT/viewer_count AS completion_rate
FROM anime_info JOIN anime_stats USING(anime_id)
WHERE format = 'TV' AND completed_count > 0 AND ep_count > 0;