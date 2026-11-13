-- Q11: Monthly cohort retention — do customers from a given first-order
-- month come back in the following months? (delivered orders only)
WITH first_order AS (
    SELECT c.customer_unique_id,
           strftime('%Y-%m', MIN(o.order_purchase_timestamp)) AS cohort_month
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1
),
activity AS (
    SELECT c.customer_unique_id,
           fo.cohort_month,
           CAST((strftime('%Y', o.order_purchase_timestamp) * 12
                 + strftime('%m', o.order_purchase_timestamp))
               - (substr(fo.cohort_month, 1, 4) * 12
                 + substr(fo.cohort_month, 6, 2)) AS INTEGER) AS month_offset
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    JOIN first_order fo ON fo.customer_unique_id = c.customer_unique_id
    WHERE o.order_status = 'delivered'
),
cohort_size AS (
    SELECT cohort_month, COUNT(*) AS customers FROM first_order GROUP BY 1
)
SELECT a.cohort_month,
       a.month_offset,
       COUNT(DISTINCT a.customer_unique_id) AS active_customers,
       cs.customers AS cohort_size,
       ROUND(100.0 * COUNT(DISTINCT a.customer_unique_id) / cs.customers, 1)
           AS retention_pct
FROM activity a
JOIN cohort_size cs USING (cohort_month)
WHERE a.month_offset BETWEEN 0 AND 5
GROUP BY 1, 2, 4
ORDER BY 1, 2;
