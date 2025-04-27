import matplotlib.pyplot as plt
import pg8000 
import os
from dotenv import load_dotenv
from scipy import stats

load_dotenv()
# Add credentials to .env before use
print("Connecting to database...")
connection = pg8000.connect(
    user= os.environ.get('STUDENT_USERNAME'),
    password=os.environ.get('STUDENT_PASSWORD'),
    host="ada.mines.edu",
    port=5432,
    database="csci403"
)

cursor = connection.cursor()

cursor.execute("SET search_path TO group31")
print("Retrieving data from database...")

cursor.execute("""
SELECT COUNT(rating) AS num_ratings, mean_score
FROM user_info JOIN user_ratings USING(user_id)
WHERE mean_score != 0
GROUP BY user_id, mean_score
HAVING COUNT(rating) < 1804;
               """)
score_data = cursor.fetchall()

cursor.execute("""
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
               """)
grouped_score_data = cursor.fetchall()

# Data for episode count and completion rate for all tv shows
cursor.execute("""
SELECT ep_count, completed_count::FLOAT/viewer_count AS completion_rate
FROM anime_info JOIN anime_stats USING(anime_id)
WHERE format = 'TV' AND completed_count > 0 AND ep_count BETWEEN 0 AND 1500 ;
               """)
ep_count_data = cursor.fetchall()


# Top 5 genres by average score for genres with > 500 shows.
cursor.execute("""
SELECT genre, AVG(score) AS average_score
FROM anime_stats JOIN anime_genres USING(anime_id)
GROUP BY genre
HAVING COUNT(genre) > 500
ORDER BY average_score DESC
LIMIT 5;
               """)
genre_score_data = cursor.fetchall()

# Top 5 genres by drop rate score for genres with > 500 shows.
cursor.execute("""
SELECT genre, AVG(dropped_count::FLOAT/viewer_count) AS drop_rate
FROM anime_stats JOIN anime_genres USING(anime_id) 
GROUP BY genre
HAVING COUNT(genre) > 500
ORDER BY drop_rate DESC
LIMIT 5;
               """)
genre_drop_data = cursor.fetchall()

# Top 5 genres by completion rate score for genres with > 500 shows.
cursor.execute("""
SELECT genre, AVG(completed_count::FLOAT/viewer_count) AS completion_rate
FROM anime_stats JOIN anime_genres USING(anime_id) 
GROUP BY genre
HAVING COUNT(genre) > 500
ORDER BY completion_rate DESC
LIMIT 5;
               """)
genre_comp_data = cursor.fetchall()


print("Closing connection")
cursor.close()
connection.close()

print("Building figures...")

# Scatterplot of # of rankings vs average score for different users
num_ratings = [pair[0] for pair in score_data]
mean_score = [pair[1] for pair in score_data]
plt.figure(1)
plt.scatter(num_ratings, mean_score, marker='x', s=10)
plt.xlabel("Total Number of Ratings By User")
plt.ylabel("Average Score Given")
plt.title("Average Score vs. Number of Ratings")
rating_correlation = stats.spearmanr(num_ratings, mean_score)
print("Score vs. Ranking Count Correlation (Spearman Rank-Order): ", rating_correlation.statistic)

# Bar chart of average score grouped by rating count
groups = [pair[0] for pair in grouped_score_data]
averages = [pair[1]-8 for pair in grouped_score_data]
plt.figure(2)
plt.bar(groups, averages, bottom=8, color=['red','blue','orange','green'])
plt.xlabel("Grouping based on # of ratings")
plt.ylabel("Average score given")
plt.title("Average Score for Different Groups of Users")

# Scatterplot of episode count vs completion rate for different users
ep_count = [pair[0] for pair in ep_count_data]
comp_rate = [pair[1] for pair in ep_count_data]
plt.figure(3)
plt.scatter(ep_count, comp_rate, marker='x', color='salmon')
plt.xlabel("Total Number of Episodes")
plt.ylabel("Completion Rate (# of completions / # of show watchers)")
plt.title("Episode Count vs. Completion Rate")
completion_correlation = stats.spearmanr(ep_count, comp_rate)
print("Completion Rate vs. Episode Count Correlation (Spearman Rank-Order): ", completion_correlation.statistic)

# Bar chart of average score for different genres (Top 5)
genres = [pair[0] for pair in genre_score_data]
genre_scores = [pair[1]-6 for pair in genre_score_data]
plt.figure(4)
plt.bar(genres, genre_scores, bottom=6,color=['skyblue','lightpink','lightgreen','plum','teal'])
plt.xlabel("Genre")
plt.ylabel("Average score given")
plt.title("Average Score for Different Genres (Top 5)")

# Bar chart of drop rate for different genres (Top 5)
genres = [pair[0] for pair in genre_drop_data]
genre_drop_rate = [pair[1] for pair in genre_drop_data]
plt.figure(5)
plt.bar(genres, genre_drop_rate, color=['skyblue','lightpink','lightgreen','plum','teal'])
plt.xlabel("Genre")
plt.ylabel("Drop Rate (# of drops / # of show watchers)")
plt.title("Drop Rate for Different Genres (Top 5)")

# Bar chart of completion rate for different genres (Top 5)
genres = [pair[0] for pair in genre_comp_data]
genre_comp_rate = [pair[1] for pair in genre_comp_data]
plt.figure(6)
plt.bar(genres, genre_comp_rate, color=['skyblue','lightpink','lightgreen','plum','teal'])
plt.xlabel("Genre")
plt.ylabel("Completion Rate (# of completions / # of show watchers)")
plt.title("Completion Rate for Different Genres (Top 5)")

plt.show()


