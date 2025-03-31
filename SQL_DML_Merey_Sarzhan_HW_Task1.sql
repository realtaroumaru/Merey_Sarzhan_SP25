-- Task 1: Insert Favorite Movies into the 'film' Table
-- This shows that our favorite movies exist in the database with proper rental rates and durations.
INSERT INTO film (title, rental_rate, rental_duration, last_update)
SELECT * FROM (VALUES
    ('Inception', 4.99, 7, CURRENT_DATE),
    ('The Matrix', 9.99, 14, CURRENT_DATE),
    ('Interstellar', 19.99, 21, CURRENT_DATE)
) AS new_movies
ON CONFLICT (title) DO NOTHING;

-- Task 1: Add Leading Actors to 'actor' Table
-- We ensure actors exist in the database before linking them to the films.
INSERT INTO actor (first_name, last_name, last_update)
SELECT * FROM (VALUES
    ('Leonardo', 'DiCaprio', CURRENT_DATE),
    ('Joseph', 'Gordon-Levitt', CURRENT_DATE),
    ('Keanu', 'Reeves', CURRENT_DATE),
    ('Laurence', 'Fishburne', CURRENT_DATE),
    ('Matthew', 'McConaughey', CURRENT_DATE),
    ('Anne', 'Hathaway', CURRENT_DATE)
) AS new_actors
ON CONFLICT (first_name, last_name) DO NOTHING;

-- Task 1: Link Movies and Actors in 'film_actor' Table
-- This shows a proper connections between films and their actors.
INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT a.actor_id, f.film_id, CURRENT_DATE
FROM actor a
JOIN film f ON (
    (a.first_name = 'Leonardo' AND a.last_name = 'DiCaprio' AND f.title = 'Inception') OR
    (a.first_name = 'Joseph' AND a.last_name = 'Gordon-Levitt' AND f.title = 'Inception') OR
    (a.first_name = 'Keanu' AND a.last_name = 'Reeves' AND f.title = 'The Matrix') OR
    (a.first_name = 'Laurence' AND a.last_name = 'Fishburne' AND f.title = 'The Matrix') OR
    (a.first_name = 'Matthew' AND a.last_name = 'McConaughey' AND f.title = 'Interstellar') OR
    (a.first_name = 'Anne' AND a.last_name = 'Hathaway' AND f.title = 'Interstellar')
)
ON CONFLICT DO NOTHING;

-- Task 1: Add Movies to Store Inventory
-- This shows that our favorite movies are available for rental.
INSERT INTO inventory (film_id, store_id, last_update)
SELECT f.film_id, 1, CURRENT_DATE FROM film f WHERE title IN ('Inception', 'The Matrix', 'Interstellar')
ON CONFLICT DO NOTHING;

-- Task 1: Update an Existing Customer's Data
-- We select a customer with at least 43 rentals to ensure we modify an active customer and this avoids creating a new customer and maintains database integrity.
UPDATE customer
SET first_name = 'Merey', last_name = 'Sarzhan', email = 'angrymaryy@gmail.com', last_update = CURRENT_DATE
WHERE customer_id = (
    SELECT customer_id FROM rental
    GROUP BY customer_id HAVING COUNT(*) >= 43
    LIMIT 1
);

-- Task 1: Rent and Pay for Movies
-- Step 1: Identify the customer renting the movies. This ensures we only process rentals for the updated customer
WITH customer_renting AS (
    SELECT customer_id FROM customer WHERE first_name = 'Merey' AND last_name = 'Sarzhan'
),
-- Step 2. We limit to 3 to match the favorite movies we inserted earlier
inventory_selection AS (
    SELECT inventory_id FROM inventory WHERE film_id IN (SELECT film_id FROM film WHERE title IN ('Inception', 'The Matrix', 'Interstellar')) LIMIT 3
),
-- Step 3. We create rental records for the selected movies, ensuring each rental has a 7-day return period
rental_insertion AS (
    INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
    SELECT CURRENT_DATE, inventory_id, (SELECT customer_id FROM customer_renting), CURRENT_DATE + INTERVAL '7 days', 1, CURRENT_DATE FROM inventory_selection
    RETURNING rental_id, customer_id
)
-- Step 4. Payments are recorded for each rental, using the correct rental rates from the 'film' table
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT rental_insertion.customer_id, 1, rental_insertion.rental_id, f.rental_rate, CURRENT_DATE
FROM rental_insertion
JOIN film f ON f.film_id = (SELECT film_id FROM inventory WHERE inventory_id = rental_insertion.rental_id)
ON CONFLICT DO NOTHING;