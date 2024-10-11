use netflix_database;
SELECT * FROM netflix;
 
-- 1 Counting num of movies and TV Shows
SELECT type , COUNT(*) as total_count FROM netflix GROUP BY type;

-- 2 common rating for movies and TV shows

SELECT type , rating FROM
(SELECT type ,rating ,  COUNT(rating) , 
		RANK() OVER (PARTITION BY type ORDER BY COUNT(rating) DESC) as ranking
FROM netflix GROUP BY type , rating  ORDER BY type 
) as t1
WHERE ranking = 1;
 
 
 
-- 3 Movies released in specific year
SELECT title FROM netflix WHERE release_year = 2020 AND type = 'Movie';

SELECT title , release_year FROM netflix WHERE type = 'Movie' ORDER BY release_year;


-- 4 Find 5 top countries with most content on netflix
WITH RECURSIVE country_split AS (
	SELECT show_id , 
		  title,
          TRIM(SUBSTRING_INDEX(country , ',', 1)) AS country_name,
          CASE 
				WHEN LOCATE(',' , country ) > 0 THEN 
					TRIM(SUBSTRING(country , LOCATE(',' , country) + 1 ))
				ELSE null
		 END AS remaining_country
	 FROM netflix WHERE country IS NOT NULL
     UNION ALL     
     SELECT show_id , 
			title , 
            TRIM(SUBSTRING_INDEX(remaining_country , ',' , 1)) AS country_name,
            CASE 
				WHEN LOCATE(',', remaining_country) > 0 THEN
					TRIM(SUBSTRING(remaining_country , LOCATE(',' , remaining_country) + 1 ) )
				ELSE NULL
            END AS remaining_country
	FROM country_split
    WHERE remaining_country IS NOT NULL
)
SELECT country_name, COUNT(country_name) AS total_movies FROM country_split 
GROUP BY country_name ORDER BY total_movies DESC
LIMIT 5;


-- 5 longest movie 
SELECT title, 
       CAST(REPLACE(duration, ' min', '') AS UNSIGNED) AS duration_in_min
FROM netflix
WHERE type = 'Movie' AND duration IS NOT NULL 
ORDER BY duration_in_min DESC;

-- 6 Content added in last 10 years
SELECT * FROM netflix 
WHERE str_to_date(date_added , '%M %D %Y') >= DATE_SUB(CURDATE() , INTERVAL 10 YEAR)  ;
 
 
-- 7 directed by Daniel Sandu
SELECT show_id , type , title FROM netflix 
WHERE LOWER(director) LIKE LOWER('%Daniel Sandu%');

-- 8 Listing TV Shows with more than 1 seasons
SELECT show_id, title, duration FROM netflix 
WHERE LOWER(duration) Like LOWER('%seasons') AND type = 'TV Show'
		AND CAST(REPLACE(duration , ' Seasons' , '') AS unsigned) > 1;
     
-- 9 What are the max genre listed
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

-- 10 Find each year and avg num of content release by India on netflix
--  	and return top 5 year with highest avg content

SELECT COUNT(show_id) AS total_content, 
CAST(TRIM(SUBSTRING_INDEX(date_added , ' ', -1)) AS UNSIGNED) AS year 
FROM netflix WHERE country = 'India' 
GROUP BY year ORDER BY total_content
LIMIT 5;


-- 11 Movies that are documentaries
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


-- 12 ALL content without director
SELECT show_id, title , director
FROM netflix
WHERE director = '' OR director IS NULL; 

-- 13 movies where JUNKO appeared in last 5 years in netflix
SELECT show_id , title , casts, date_added 
FROM netflix
WHERE LOWER(casts) LIKE '%junko%' 
AND  str_to_date(date_added , '%M %D %Y') >= DATE_SUB(CURDATE() , INTERVAL 5 YEAR);

-- 14 Actors(10) appeared in highest num of movies in US
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

-- 15 Catogerise content based on keywords 'kill' and 'violence' in description field and label them as 'Bad' and others as 'Good' So how many fall in which category

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