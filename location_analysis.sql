SELECT  cleaned_location AS country,
	COUNT(*) AS accounts,
	ROUND(AVG(mean_score)::numeric, 2) AS avg_score,
	ROUND(AVG(days_watched)::numeric, 2) AS avg_days_watched,
	ROUND(AVG(total_entries)::numeric, 2) AS avg_total_entries
FROM cleaned_locations_trimmed
GROUP BY cleaned_location;

SELECT  CLT.cleaned_location as country,
	AG.genre,
	AVG(UR.rating) as avg_rating,
	COUNT(CLT.user_id) as total_ratings
FROM cleaned_locations_trimmed AS CLT
INNER JOIN user_ratings AS UR ON CLT.user_id = UR.user_id
INNER JOIN anime_genres AS AG ON UR.anime_id = AG.anime_id
GROUP BY CLT.cleaned_location, AG.genre
HAVING COUNT(CLT.user_id) > 10;
