import matplotlib.pyplot as plt
import pg8000 
import os
from dotenv import load_dotenv

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

print("Retrieving data from database...")
# Only analyzing bottom 99% of raters by frequency
cursor.execute("""
SELECT COUNT(rating) AS num_ratings, mean_score
FROM user_info JOIN user_ratings USING(user_id)
WHERE mean_score != 0
GROUP BY user_id, mean_score
HAVING COUNT(rating) < 1804;
               """)
data = cursor.fetchall()

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
grouped_data = cursor.fetchall()

print("Building figures...")
num_ratings = [pair[0] for pair in data]
mean_score = [pair[1] for pair in data]
plt.figure(1)
plt.scatter(num_ratings, mean_score, marker='x', s=10)
plt.xlabel("Total Number of Ratings By User")
plt.ylabel("Average Score Given")
plt.title("Average Score vs. Number of Ratings")

groups = [pair[0] for pair in grouped_data]
averages = [pair[1]-8 for pair in grouped_data]
plt.figure(2)
plt.bar(groups, averages, bottom=8, color=['red','blue','orange','green'], label= averages)




plt.show()





print("Closing connection")
cursor.close()
connection.close()

