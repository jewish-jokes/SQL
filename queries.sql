--Вывести количество фильмов в каждой категории, отсортировать по убыванию.
SELECT c.name AS category_name, COUNT(*) AS movie_count
FROM film_category fc
JOIN film f ON fc.film_id = f.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY c.name
ORDER BY movie_count DESC;

--Вывести 10 актеров, чьи фильмы большего всего арендовали, отсортировать по убыванию.
SELECT a.first_name, a.last_name, COUNT(*) as rental_count
FROM actor a
JOIN film_actor fa ON a.actor_id = fa.actor_id
JOIN inventory i ON fa.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY a.actor_id
ORDER BY rental_count DESC
LIMIT 10;

--Вывести категорию фильмов, на которую потратили больше всего денег.
SELECT c.name AS category_name, COUNT(*) as payment_amount
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
JOIN inventory i ON fc.film_id = i.film_id 
JOIN rental r ON i.inventory_id = r.inventory_id
JOIN payment p ON r.rental_id = p.rental_id
GROUP BY c.name
ORDER BY payment_amount DESC
LIMIT 1;

--Вывести названия фильмов, которых нет в inventory. Написать запрос без использования оператора IN.
SELECT f.title
FROM film f
WHERE NOT EXISTS (
  SELECT 1
  FROM inventory i
  WHERE i.film_id = f.film_id
);

--Вывести топ 3 актеров, которые больше всего появлялись в фильмах в категории “Children”. Если у нескольких актеров одинаковое кол-во фильмов, вывести всех.
WITH actor_children_movies AS(
	SELECT a.actor_id, a.first_name, a.last_name, COUNT(*) AS movie_count
	FROM film_category fc
	JOIN film f ON fc.film_id = f.film_id
	JOIN film_actor fa ON f.film_id = fa.film_id
	JOIN actor a ON fa.actor_id = a.actor_id
	WHERE fc.category_id = (
	  SELECT category_id FROM category WHERE name = 'Children'
	)
	GROUP BY a.actor_id
)
SELECT first_name, last_name, movie_count
FROM (
  SELECT first_name, last_name, movie_count, DENSE_RANK() OVER (ORDER BY movie_count DESC) AS rank
  FROM actor_children_movies
) subquery
WHERE rank <= 3;



--Вывести города с количеством активных и неактивных клиентов (активный — customer.active = 1). Отсортировать по количеству неактивных клиентов по убыванию.
SELECT 
    c.city, 
    COUNT(CASE WHEN cu.active = 1 THEN 1 END) AS active_customers,
    COUNT(CASE WHEN cu.active = 0 THEN 1 END) AS inactive_customers
FROM 
    city c
	JOIN address a ON c.city_id = a.city_id
	JOIN customer cu ON a.address_id = cu.address_id
GROUP BY 
    c.city
ORDER BY 
    inactive_customers DESC;

--Вывести категорию фильмов, у которой самое большое кол-во часов суммарной аренды в городах (customer.address_id в этом city), и которые начинаются на букву “a”. То же самое сделать для городов в которых есть символ “-”. Написать все в одном запросе.
SELECT category_name
FROM
  (
    SELECT
      NAME AS category_name,
      SUM(return_date - rental_date) AS time_diff,
      DENSE_RANK() OVER(
        ORDER BY
          SUM(return_date - rental_date) DESC
      ) rank_sum
    FROM city
      JOIN address using (city_id)
      JOIN customer using (address_id)
      JOIN rental using (customer_id)
      JOIN inventory using (inventory_id)
      JOIN film using (film_id)
      JOIN film_category using (film_id)
      JOIN category using (category_id)
    WHERE city_id IN (
        SELECT city_id
        FROM city
        WHERE LOWER(film.title) LIKE 'a%' AND LOWER(city) LIKE '%-%'
      )
    GROUP BY category.name
  ) grouped_category_by_hours
WHERE rank_sum <= 1;


