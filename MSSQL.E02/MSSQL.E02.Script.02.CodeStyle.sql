--Bad Style
with tabl as
(select actor_id, max(release_year) lry from film_actor join film on film_actor.film_id = film.film_id
group by actor_id)
select concat(first_name, ' ', last_name), lry from tabl join actor on tabl.actor_id = actor.actor_id 
where lry in (select min(lry) from tabl);


--Good Style
WITH tabl AS (
	SELECT
		fact.actor_id,
		lry		= MAX(flm.release_year)
	FROM
		film_actor			AS fact
		INNER JOIN film		AS flm		ON film_actor.film_id = film.film_id
	GROUP BY
		fact.actor_id
)
SELECT
	full_name	= CONCAT(act.first_name, ' ', act.last_name),
	tbl.lry
FROM
	tabl				AS tbl
	INNER JOIN actor	AS act	ON tabl.actor_id = actor.actor_id 
WHERE
	bl.lry IN (SELECT MIN(lry) FROM tabl)
;