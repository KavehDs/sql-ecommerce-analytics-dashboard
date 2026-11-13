-- Q5: Who are the biggest customers? (by total spend, delivered orders)
SELECT
    c.customer_unique_id,
    c.customer_state AS state,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(SUM(p.payment_value), 2) AS total_spent_brl,
    ROUND(AVG(p.payment_value), 2) AS avg_order_brl,
    MIN(o.order_purchase_timestamp) AS first_order,
    MAX(o.order_purchase_timestamp) AS last_order
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
JOIN order_payments p USING (order_id)
WHERE o.order_status = 'delivered'
GROUP BY 1, 2
ORDER BY total_spent_brl DESC
LIMIT 10;
