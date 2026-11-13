-- Q6: How do customers pay? Payment mix and instalments.
SELECT
    p.payment_type,
    COUNT(*) AS payments,
    COUNT(DISTINCT p.order_id) AS orders,
    ROUND(SUM(p.payment_value), 2) AS revenue_brl,
    ROUND(100.0 * SUM(p.payment_value)
        / SUM(SUM(p.payment_value)) OVER (), 2) AS revenue_share_pct,
    ROUND(AVG(p.payment_installments), 2) AS avg_installments
FROM order_payments p
JOIN orders o USING (order_id)
WHERE o.order_status = 'delivered'
GROUP BY 1
ORDER BY revenue_brl DESC;
