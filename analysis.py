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
cursor.execute("""
               SELECT COUNT(rating) AS num_ratings, mean_score
               FROM user_info JOIN user_ratings USING(user_id)
               WHERE mean_score != 0
               GROUP BY user_id, mean_score
               HAVING COUNT(rating) < 5000;
               
               """)
data = cursor.fetchall()

print("Building scatterplot...")
num_ratings = [pair[0] for pair in data]
mean_score = [pair[1] for pair in data]
plt.scatter(num_ratings, mean_score)
plt.show();


print("Closing connection")
cursor.close()
connection.close()

