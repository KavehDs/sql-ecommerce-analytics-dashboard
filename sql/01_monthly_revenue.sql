-- Q1: How is revenue trending month by month?
-- Revenue = sum of payment_value for DELIVERED orders only, so
-- cancelled / unavailable orders do not inflate the numbers.
SELECT
    strftime('%Y-%m', o.order_purchase_timestamp) AS month,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(SUM(p.payment_value), 2) AS revenue_brl,
    ROUND(SUM(p.payment_value) * 1.0 / COUNT(DISTINCT o.order_id), 2) AS aov_brl
FROM orders o
JOIN order_payments p USING (order_id)
WHERE o.order_status = 'delivered'
GROUP BY 1
ORDER BY 1;
