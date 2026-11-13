-- Q7: Are deliveries on time? Actual vs promised delivery, by year.
-- delay_days > 0 means the order arrived AFTER the estimated date.
SELECT
    strftime('%Y', o.order_purchase_timestamp) AS order_year,
    COUNT(*) AS delivered_orders,
    ROUND(AVG(julianday(o.order_delivered_customer_date)
        - julianday(o.order_purchase_timestamp)), 1) AS avg_delivery_days,
    ROUND(AVG(julianday(o.order_delivered_customer_date)
        - julianday(o.order_estimated_delivery_date)), 1) AS avg_delay_days,
    ROUND(100.0 * SUM(CASE WHEN o.order_delivered_customer_date
        > o.order_estimated_delivery_date THEN 1 ELSE 0 END)
        / COUNT(*), 1) AS pct_late
FROM orders o
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY 1
ORDER BY 1;
