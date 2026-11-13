-- Q9: Do customers come back? Order-count distribution per customer.
-- Delivered orders only; a "repeat customer" placed 2+ orders.
WITH per_customer AS (
    SELECT c.customer_unique_id,
           COUNT(DISTINCT o.order_id) AS n_orders,
           SUM(p.payment_value) AS total_spent
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    JOIN order_payments p USING (order_id)
    WHERE o.order_status = 'delivered'
    GROUP BY 1
)
SELECT
    CASE WHEN n_orders = 1 THEN '1 order'
         WHEN n_orders = 2 THEN '2 orders'
         WHEN n_orders BETWEEN 3 AND 4 THEN '3-4 orders'
         ELSE '5+ orders' END AS order_bucket,
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_customers,
    ROUND(SUM(total_spent), 2) AS revenue_brl,
    ROUND(100.0 * SUM(total_spent) / SUM(SUM(total_spent)) OVER (), 1) AS pct_revenue
FROM per_customer
GROUP BY 1
ORDER BY MIN(n_orders);
