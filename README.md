# Netflix SQL Data Analysis Project

This project involves analyzing data from a **Netflix dataset** using SQL queries. The analysis includes insights into the number of movies and TV shows, content ratings, release years, content from different countries, and more.

The project demonstrates various SQL techniques such as recursive queries, window functions, string manipulation, and data aggregation to answer specific business questions.

## Project Overview

The main goals of this project are:
- To extract meaningful insights from the Netflix database.
- To write efficient SQL queries to solve specific data problems.
- To demonstrate advanced SQL techniques such as recursive common table expressions (CTEs), window functions, and data manipulation.

### Data Source

The data used for this analysis is sourced from the following Kaggle dataset:  
[Netflix Shows and Movies Exploratory Analysis by Shivam Bansal](https://www.kaggle.com/code/shivamb/netflix-shows-and-movies-exploratory-analysis)

The dataset is stored in a table called `netflix` and includes columns such as `title`, `type`, `country`, `release_year`, `rating`, `director`, `casts`, `listed_in`, `duration`, and `date_added`.

---

## Analysis Breakdown

### 1. Counting Number of Movies and TV Shows
The first query counts the number of movies and TV shows available on Netflix.

```sql
SELECT type , COUNT(*) as total_count FROM netflix GROUP BY type;
```
### 2. Common Rating for Movies and TV Shows
This query finds the most common rating for both movies and TV shows using a ranking function.

```sql
SELECT type , rating FROM (
    SELECT type, rating, COUNT(rating), 
        RANK() OVER (PARTITION BY type ORDER BY COUNT(rating) DESC) as ranking
    FROM netflix 
    GROUP BY type, rating 
    ORDER BY type
) as t1
WHERE ranking = 1;
```

### 3. Movies Released in a Specific Year
This query lists all movies released in the year 2020.

```sql
SELECT title FROM netflix WHERE release_year = 2020 AND type = 'Movie';
```

### 4. 4. Top 5 Countries with Most Content
Using a recursive CTE, this query lists the top 5 countries with the most content available on Netflix.

```sql
WITH RECURSIVE country_split AS (
    SELECT show_id, title, TRIM(SUBSTRING_INDEX(country, ',', 1)) AS country_name,
        CASE WHEN LOCATE(',', country) > 0 THEN 
            TRIM(SUBSTRING(country, LOCATE(',', country) + 1))
        ELSE NULL END AS remaining_country
    FROM netflix WHERE country IS NOT NULL
    UNION ALL
    SELECT show_id, title, TRIM(SUBSTRING_INDEX(remaining_country, ',', 1)) AS country_name,
        CASE WHEN LOCATE(',', remaining_country) > 0 THEN
            TRIM(SUBSTRING(remaining_country, LOCATE(',', remaining_country) + 1))
        ELSE NULL END AS remaining_country
    FROM country_split WHERE remaining_country IS NOT NULL
)
SELECT country_name, COUNT(country_name) AS total_movies 
FROM country_split 
GROUP BY country_name 
ORDER BY total_movies DESC
LIMIT 5;
```


### 5. Longest Movie
This query finds the longest movie on Netflix by parsing the duration field.

```sql
SELECT title, CAST(REPLACE(duration, ' min', '') AS UNSIGNED) AS duration_in_min
FROM netflix
WHERE type = 'Movie' AND duration IS NOT NULL 
ORDER BY duration_in_min DESC;
```

### 6. Content Added in the Last 10 Years
This query retrieves all content added to Netflix in the last 10 years from the current date.

```sql
SELECT * FROM netflix 
WHERE str_to_date(date_added, '%M %D %Y') >= DATE_SUB(CURDATE(), INTERVAL 10 YEAR);
```

### 7. Content Directed by Daniel Sandu
This query finds all content directed by Daniel Sandu.

```sql
SELECT show_id, type, title FROM netflix 
WHERE LOWER(director) LIKE LOWER('%Daniel Sandu%');
```

### 8. TV Shows with More Than 1 Season
The query lists all TV shows that have more than 1 season.

```sql
SELECT show_id, title, duration 
FROM netflix 
WHERE LOWER(duration) LIKE LOWER('%seasons') AND type = 'TV Show'
    AND CAST(REPLACE(duration, ' Seasons', '') AS unsigned) > 1;
```

### 9. Top Genres Listed
This recursive query finds the top 5 most common genres listed on Netflix.

```sql
WITH RECURSIVE genre_split AS (
	SELECT show_id , title ,
		TRIM(SUBSTRING_INDEX(listed_in , ',', 1)) AS genre,
		CASE 
			WHEN LOCATE(',', listed_in) > 0 THEN
				TRIM(SUBSTRING(listed_in , LOCATE(',' , listed_in) + 1 ))
			ELSE NULL
		END AS remaining_genre
    FROM netflix 
    WHERE listed_in IS NOT NULL
    
    UNION ALL
    
    SELECT show_id , title , 
			TRIM(SUBSTRING_INDEX(remaining_genre, ',', 1)) AS genre,
            CASE
				WHEN LOCATE(',', remaining_genre) > 0 THEN
                TRIM(SUBSTRING(remaining_genre , LOCATE(',' , remaining_genre) + 1) )
			ELSE null
            END AS remaining_genre
	FROM genre_split
    WHERE remaining_genre IS NOT NULL
)
SELECT genre, COUNT(genre) AS total_count FROM genre_split  
GROUP BY genre ORDER BY total_count DESC
LIMIT 5;
```

### 10. Top 5 Years for Content Released by India
This query finds the top 5 years in which India released the highest average content on Netflix.


```sql
SELECT COUNT(show_id) AS total_content, 
CAST(TRIM(SUBSTRING_INDEX(date_added , ' ', -1)) AS UNSIGNED) AS year 
FROM netflix WHERE country = 'India' 
GROUP BY year ORDER BY total_content
LIMIT 5;
```

### 11. Movies that are Documentaries
This query lists all the movies on Netflix categorized as Documentaries.

```sql
WITH RECURSIVE listed_in_split AS (
	SELECT show_id , title , type, 
		TRIM(SUBSTRING_INDEX(listed_in , ',' , 1)) AS genre,
        CASE 
			WHEN LOCATE(',' , listed_in ) > 0 THEN 
				TRIM(SUBSTRING(listed_in , LOCATE(',' , listed_in) + 1)) 
			ELSE NULL
		END AS remaining_genre 
	FROM netflix
    WHERE listed_in IS NOT NULL
    
    UNION ALL
    
    SELECT show_id , title, type,
		TRIM(SUBSTRING_INDEX(remaining_genre , ',' , 1)) AS genre,
        CASE 
			WHEN LOCATE(',' , remaining_genre) > 0 THEN 
				TRIM(SUBSTRING(remaining_genre, LOCATE(',' , remaining_genre) + 1) )
			ELSE NULL
		END AS remaining_genre
	FROM listed_in_split
    WHERE remaining_genre IS NOT NULL
)
SELECT show_id , title AS total_movie_documentaries
FROM listed_in_split WHERE type = 'Movie' AND genre = 'Documentaries';

-- Both the queries are fine
SELECT show_id , type , listed_in 
FROM netflix 
WHERE listed_in LIKE '%Documentaries%';
```

### 12. Content Without a Director
This query retrieves all content that does not have a director listed.
```sql
SELECT show_id, title , director
FROM netflix
WHERE director = '' OR director IS NULL;
```

### 13. Movies with Cast Member "JUNKO" in the Last 5 Years
This query lists all movies where the cast includes Junko and were added in the last 5 years.

```sql
SELECT show_id , title , casts, date_added 
FROM netflix
WHERE LOWER(casts) LIKE '%junko%' 
AND  str_to_date(date_added , '%M %D %Y') >= DATE_SUB(CURDATE() , INTERVAL 5 YEAR);
```

### 14. Top 10 Actors Appeared in Most Movies in the US
This query uses a recursive CTE to find the top 10 actors who have appeared in the highest number of movies on Netflix in the United States.

```sql
WITH RECURSIVE casts_split AS (
	SELECT show_id , title , type, country,
		TRIM(SUBSTRING_INDEX(casts , ',' , 1)) AS cast,
        CASE 
			WHEN LOCATE(',' , casts ) > 0 THEN 
				TRIM(SUBSTRING( casts , LOCATE(',' , casts) + 1)) 
			ELSE NULL
		END AS remaining_cast
	FROM netflix 
    WHERE casts IS NOT NULL AND casts != ''
        
	UNION ALL
    
    SELECT show_id , title , type, country,
		TRIM(SUBSTRING_INDEX(remaining_cast , ',', 1)) AS cast,
        CASE 
			WHEN LOCATE(',', remaining_cast) > 0 
				THEN TRIM(SUBSTRING(remaining_cast , LOCATE(',', remaining_cast) + 1 ))
			ELSE NULL
		END AS remaining_cast
	FROM casts_split
    WHERE remaining_cast IS NOT NULL 
)
SELECT  cast, COUNT(show_id) as total_movies
FROM casts_split 
WHERE type = 'Movie' AND country LIKE '%United States%' 
GROUP BY cast ORDER BY total_movies DESC 
LIMIT 10;
```

### 15. Categorizing Content Based on Keywords in Description
This query categorizes content based on the presence of the keywords kill and violence in the description, labeling them as "Bad" and others as "Good."

```sql
WITH new_table AS
(SELECT show_id ,title, description,
	CASE 
		WHEN LOWER(description) LIKE '% kill%' OR LOWER(description) LIKE '% violence%' THEN 
				'Bad'
			ELSE 'Good'
	END AS category
FROM netflix ORDER BY category
)
SELECT COUNT(*), category FROM new_table GROUP BY category;
```
