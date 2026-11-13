-- Q2: Which product categories make the money?
-- Item revenue = SUM(price) of order items on delivered orders
-- (freight excluded). Share uses a window function.
SELECT
    COALESCE(t.product_category_name_english, 'unknown') AS category,
    COUNT(DISTINCT oi.order_id) AS orders,
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price), 2) AS item_revenue_brl,
    ROUND(100.0 * SUM(oi.price) / SUM(SUM(oi.price)) OVER (), 2) AS revenue_share_pct
FROM order_items oi
JOIN products pr ON pr.product_id = oi.product_id
LEFT JOIN category_translation t
    ON t.product_category_name = pr.product_category_name
JOIN orders o ON o.order_id = oi.order_id AND o.order_status = 'delivered'
GROUP BY 1
ORDER BY item_revenue_brl DESC;
