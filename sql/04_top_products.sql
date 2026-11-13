-- Q4: Top 10 products by item revenue (delivered orders only).
SELECT
    oi.product_id,
    COALESCE(t.product_category_name_english, 'unknown') AS category,
    COUNT(*) AS items_sold,
    COUNT(DISTINCT oi.order_id) AS orders,
    ROUND(SUM(oi.price), 2) AS item_revenue_brl,
    ROUND(AVG(oi.price), 2) AS avg_price_brl
FROM order_items oi
JOIN products pr ON pr.product_id = oi.product_id
LEFT JOIN category_translation t
    ON t.product_category_name = pr.product_category_name
JOIN orders o ON o.order_id = oi.order_id AND o.order_status = 'delivered'
GROUP BY 1, 2
ORDER BY item_revenue_brl DESC
LIMIT 10;
