/*
Note:
All CTEs are assigned names according to the arrangement of the alphabet,
with the first CTE named 'A' and the last named 'E'.
*/

--Q1
---Count the total number of customers who joined in 2023.
SELECT
	COUNT(*)
FROM
	data.lauchpad.customers
WHERE join_date BETWEEN '2023-01-01' AND '2023-12-31'

--Q2
--- For each customer return customer_id, full_name, total_revenue (sum of total_amount from orders). Sort descending.
SELECT
	c.customer_id,
	c.full_name
	SUM(o.total_amount) total_revenue,
FROM
	data.lauchpad.customers AS c
JOIN
	data.lauchpad.orders AS o
ON c.customer_id = o.customer_id
GROUP BY
	c.customer_id,c.full_name
ORDER BY
	total_revenue DESC

--Q3
-- Return the top 5 customers by total_revenue with their rank.
WITH A AS(
	SELECT
		c.customer_id,
		c.full_name,
		SUM(o.total_amount) AS total_revenue
	FROM
		data.lauchpad.customers AS c
	JOIN
		data.lauchpad.orders AS o
	ON c.customer_id = o.customer_id
	GROUP BY
		c.customer_id,c.full_name
	),
B AS(
	SELECT
		customer_id,
		full_name,
		total_revenue,
		RANK() OVER(ORDER BY total_revenue DESC) AS customer_rank
	FROM
		A
)
SELECT * FROM B
LIMIT 5

--Q4
-- Produce a table with year, month, monthly_revenue for all months in 2023 ordered chronologically.
SELECT
	EXTRACT(YEAR FROM order_date) AS order_year,
	TO_CHAR(order_date,'Month') AS order_month,
	SUM(total_amount)
FROM
	data.lauchpad.orders
WHERE EXTRACT(YEAR FROM order_date) = 2023
GROUP BY
	EXTRACT(YEAR FROM order_date),
	TO_CHAR(order_date,'Month'),
	EXTRACT(MONTH FROM order_date)
ORDER BY
	EXTRACT(MONTH FROM order_date)

--Q5
--Find customers with no orders in the last 60 days relative to 2023-12-31 (i.e., consider last active date up to 2023-12-31). Return customer_id, full_name, last_order_date.
SELECT
	c.customer_id,
	c.full_name,
	MAX(o.order_date)
FROM
	data.lauchpad.customers AS c
LEFT JOIN
	data.lauchpad.orders AS o
ON c.customer_id = o.customer_id
GROUP BY c.customer_id,c.full_name
HAVING MAX(o.order_date)< DATE '2023-12-31' - INTERVAL '60 day'

--Q6
-- Calculate average order value (AOV) for each customer: return customer_id, full_name, aov (average total_amount of their orders). Exclude customers with no orders.
SELECT
    c.customer_id,
    c.full_name,
    (SELECT ROUND(AVG(o.total_amount),2)
     FROM data.lauchpad.orders AS o
     WHERE o.customer_id = c.customer_id) AS average_order_value
FROM data.lauchpad.customers AS c
WHERE c.customer_id IN (
    SELECT customer_id
    FROM data.lauchpad.orders
)
ORDER BY average_order_value DESC;

--Q7
-- For all customers who have at least one order, compute customer_id, full_name, total_revenue, spend_rank where spend_rank is a dense rank, highest spender = rank 1.
SELECT
	c.customer_id,
	c.full_name,
	SUM(o.total_amount),
	DENSE_RANK() OVER(ORDER BY SUM(o.total_amount) DESC) AS "rank"
FROM
	data.lauchpad.customers AS c
LEFT JOIN
	data.lauchpad.orders AS o
ON c.customer_id = o.customer_id
GROUP BY c.customer_id,c.full_name
HAVING COUNT(o.order_id) >= 1

--Q8
-- List customers who placed more than 1 order and show customer_id, full_name, order_count, first_order_date, last_order_date.
SELECT *
FROM(
	SELECT
		c.customer_id,
		c.full_name,
		COUNT(o.order_id),
		MIN(o.order_date) as first_order_date,
		MAX(o.order_date) AS last_order_date
	FROM
		data.lauchpad.customers AS c
	JOIN
		data.lauchpad.orders AS o
	ON c.customer_id = o.customer_id
	GROUP BY
		c.customer_id, c.full_name
	HAVING COUNT(o.order_id) > 1)

--Q9
--Compute total loyalty points per customer. Include customers with 0 points.
SELECT
	c.customer_id,
	c.full_name,
	SUM(l.points_earned) as total_loyalty_points
FROM
	data.lauchpad.customers AS c
JOIN
	data.lauchpad.loyalty_points AS l
ON c.customer_id = l.customer_id
GROUP BY
	c.customer_id,c.full_name
HAVING SUM(l.points_earned) >= 0
ORDER BY total_loyalty_points DESC

--Q10
--Assign loyalty tiers based on total points:
SELECT
	CASE
	    WHEN points_earned < 100 THEN 'Bronze'
	    WHEN points_earned >= 100 AND points_earned < 500 THEN 'Silver'
	    WHEN points_earned >= 500 THEN 'Gold'
	    ELSE 'Unknown'
	END AS tier,
	COUNT(*) AS tier_count,
	SUM(points_earned) AS tier_total_points

FROM
	data.lauchpad.loyalty_points
GROUP BY tier
ORDER BY tier_count DESC

--Q11
-- Identify customers who spent more than ₦50,000 in total but have less than 200 loyalty points. Return customer_id, full_name, total_spend, total_points.
WITH C AS (
    SELECT
        c.customer_id,
        c.full_name,
        SUM(l.points_earned) AS total_points,
        SUM(o.total_amount) AS total_spend
    FROM data.lauchpad.customers AS c
    JOIN data.lauchpad.orders AS o
        ON c.customer_id = o.customer_id
    JOIN data.lauchpad.loyalty_points AS l
        ON c.customer_id = l.customer_id
    GROUP BY c.customer_id, c.full_name
    HAVING SUM(o.total_amount) > 50000
       AND SUM(l.points_earned) < 200
)
SELECT *
FROM C;

--Q12
-- Flag customers as churn_risk if they have no orders in the last 90 days (relative to 2023-12-31) AND are in the Bronze tier. Return customer_id, full_name, last_order_date, total_points.
WITH D AS (
	-- Customer loyalty to the company
    SELECT
        c.customer_id,
        c.full_name,
        SUM(l.points_earned) AS total_points,
	    CASE
		    WHEN points_earned < 100 THEN 'Bronze'
		    WHEN points_earned >= 100 AND points_earned < 500 THEN 'Silver'
		    WHEN points_earned >= 500 THEN 'Gold'
		    ELSE 'Unknown'
	END AS tier
    FROM
        data.lauchpad.customers AS c
    LEFT JOIN
        data.lauchpad.loyalty_points AS l
        ON c.customer_id = l.customer_id
    GROUP BY
        c.customer_id, c.full_name,l.points_earned
),
--- customer order activity
E AS (
    SELECT
        d.customer_id,
        d.full_name,
        d.tier,
        d.total_points,
        MAX(o.order_date) AS last_order_date
    FROM
        D AS d
    LEFT JOIN
        data.lauchpad.orders AS o
    	ON d.customer_id = o.customer_id
    GROUP BY
        d.customer_id, d.full_name, d.tier, d.total_points
)
SELECT
    customer_id,
    full_name,
    last_order_date,
    total_points
FROM
   E
WHERE
    tier = 'Bronze'
    AND
		(last_order_date < DATE '2023-12-31' - INTERVAL '90 day');

