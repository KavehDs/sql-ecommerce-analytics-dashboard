-- Q12: Month-over-month growth and running revenue (window functions).
WITH monthly AS (
    SELECT strftime('%Y-%m', o.order_purchase_timestamp) AS month,
           ROUND(SUM(p.payment_value), 2) AS revenue_brl
    FROM orders o
    JOIN order_payments p USING (order_id)
    WHERE o.order_status = 'delivered'
    GROUP BY 1
)
SELECT month,
       revenue_brl,
       ROUND(SUM(revenue_brl) OVER (ORDER BY month), 2) AS running_revenue_brl,
       ROUND(100.0 * (revenue_brl - LAG(revenue_brl) OVER (ORDER BY month))
           / LAG(revenue_brl) OVER (ORDER BY month), 1) AS mom_growth_pct
FROM monthly
ORDER BY month;
