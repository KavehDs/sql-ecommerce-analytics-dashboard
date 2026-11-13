-- Q8: Which categories make customers happy? Review score by category.
SELECT
    COALESCE(t.product_category_name_english, 'unknown') AS category,
    COUNT(*) AS reviews,
    ROUND(AVG(r.review_score), 2) AS avg_score,
    ROUND(100.0 * SUM(CASE WHEN r.review_score = 5 THEN 1 ELSE 0 END)
        / COUNT(*), 1) AS pct_five_star,
    ROUND(100.0 * SUM(CASE WHEN r.review_score = 1 THEN 1 ELSE 0 END)
        / COUNT(*), 1) AS pct_one_star
FROM order_reviews r
JOIN order_items oi ON oi.order_id = r.order_id
JOIN products pr ON pr.product_id = oi.product_id
LEFT JOIN category_translation t
    ON t.product_category_name = pr.product_category_name
GROUP BY 1
HAVING COUNT(*) >= 500
ORDER BY avg_score DESC;
