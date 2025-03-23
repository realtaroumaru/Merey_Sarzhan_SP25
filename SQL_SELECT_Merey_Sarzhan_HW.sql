--I used a subquery to filter only "Animation" movies from the film_category table.
SELECT title, release_year, rating 
FROM film
WHERE release_year BETWEEN 2017 AND 2019
AND film_id IN (
SELECT film_id FROM film_category
WHERE category_id = (SELECT category_id FROM category WHERE name = 'Animation')
)
ORDER BY title;

--The JOINs help connect stores, staff, and payment tables. CONCAT() is used to combine address and address2 into a single column.

SELECT 
CONCAT(a.address, ' ', COALESCE(a.address2, '')) AS store_location,
SUM(p.amount) AS revenue
FROM store s
JOIN staff st ON s.store_id = st.store_id
JOIN payment p ON st.staff_id = p.staff_id
JOIN address a ON s.address_id = a.address_id
WHERE p.payment_date >= '2017-04-01'
GROUP BY store_location
ORDER BY revenue DESC;

--I used COUNT() to count how many movies each actor appeared in.The WHERE condition ensures we only count movies released after 2015.
SELECT a.first_name, a.last_name, COUNT(f.film_id) AS number_of_movies
FROM actor a
JOIN film_actor fa ON a.actor_id = fa.actor_id
JOIN film f ON fa.film_id = f.film_id
WHERE f.release_year > 2015
GROUP BY a.first_name, a.last_name
ORDER BY number_of_movies DESC
LIMIT 5;


--Instead of writing multiple queries, I used conditional aggregation (SUM with CASE).This way, I can count multiple categories in one query.
SELECT 
f.release_year,
SUM(CASE WHEN c.name = 'Drama' THEN 1 ELSE 0 END) AS number_of_drama_movies,
SUM(CASE WHEN c.name = 'Travel' THEN 1 ELSE 0 END) AS number_of_travel_movies,
SUM(CASE WHEN c.name = 'Documentary' THEN 1 ELSE 0 END) AS number_of_documentary_movies
FROM film f
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
WHERE c.name IN ('Drama', 'Travel', 'Documentary')
GROUP BY f.release_year
ORDER BY f.release_year DESC;


--Part 2: Problem-Solving Queries



--I joined staff, store, and payment to get revenue per employee.The ORDER BY and LIMIT ensure we only get the top 3 performers.
SELECT st.first_name, st.last_name, s.store_id, SUM(p.amount) AS total_revenue
FROM staff st
JOIN store s ON st.store_id = s.store_id
JOIN payment p ON st.staff_id = p.staff_id
WHERE p.payment_date BETWEEN '2017-01-01' AND '2017-12-31'
GROUP BY st.first_name, st.last_name, s.store_id
ORDER BY total_revenue DESC
LIMIT 3;


--I used COUNT() to count rentals per movie.The CASE statement categorizes each movie based on its MPAA rating.
SELECT 
f.title, 
COUNT(r.rental_id) AS rental_count,
CASE 
WHEN f.rating = 'G' THEN 'All Ages'
WHEN f.rating = 'PG' THEN '7+'
WHEN f.rating = 'PG-13' THEN '13+'
WHEN f.rating = 'R' THEN '17+'
WHEN f.rating = 'NC-17' THEN 'Adults Only'
ELSE 'Unknown'
END AS expected_audience
FROM film f
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY f.title, f.rating
ORDER BY rental_count DESC
LIMIT 5;


--Part 3: Actors with the Longest Acting Gap


--I used MAX() to find the latest movie for each actor.Then I subtracted it from the current year and sorted by the largest gap.
SELECT 
    a.first_name, a.last_name, 
    EXTRACT(YEAR FROM CURRENT_DATE) - MAX(f.release_year) AS years_since_last_movie
FROM actor a
JOIN film_actor fa ON a.actor_id = fa.actor_id
JOIN film f ON fa.film_id = f.film_id
GROUP BY a.first_name, a.last_name
ORDER BY years_since_last_movie DESC
LIMIT 5;


--Instead of finding the latest movie, I calculated the difference between their oldest and newest movie.The difference between MIN and MAX shows the largest gap.
SELECT 
a.first_name, a.last_name,
MAX(f.release_year) - MIN(f.release_year) AS max_gap_between_movies
FROM actor a
JOIN film_actor fa ON a.actor_id = fa.actor_id
JOIN film f ON fa.film_id = f.film_id
GROUP BY a.first_name, a.last_name
ORDER BY max_gap_between_movies DESC
LIMIT 5;