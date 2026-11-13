-- Q3: Where does the money come from? Revenue by customer state.
SELECT
    c.customer_state AS state,
    COUNT(DISTINCT c.customer_unique_id) AS customers,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(SUM(p.payment_value), 2) AS revenue_brl,
    ROUND(SUM(p.payment_value) * 1.0 / COUNT(DISTINCT o.order_id), 2) AS aov_brl
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
JOIN order_payments p USING (order_id)
WHERE o.order_status = 'delivered'
GROUP BY 1
ORDER BY revenue_brl DESC;
