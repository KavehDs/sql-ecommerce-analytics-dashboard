-- Q10: RFM segmentation — Recency, Frequency, Monetary per customer.
-- Scores 1-4 come from NTILE quartiles; 4 = best on that dimension.
-- Reference date is the last purchase in the data (2018-10-17).
WITH rfm AS (
    SELECT c.customer_unique_id,
           CAST(julianday('2018-10-17')
             - julianday(MAX(o.order_purchase_timestamp)) AS INTEGER) AS recency_days,
           COUNT(DISTINCT o.order_id) AS frequency,
           SUM(p.payment_value) AS monetary
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    JOIN order_payments p USING (order_id)
    WHERE o.order_status = 'delivered'
    GROUP BY 1
),
scored AS (
    SELECT *,
           NTILE(4) OVER (ORDER BY recency_days DESC) AS r_score,
           NTILE(4) OVER (ORDER BY frequency) AS f_score,
           NTILE(4) OVER (ORDER BY monetary) AS m_score
    FROM rfm
),
segmented AS (
    SELECT *,
           CASE WHEN r_score = 4 AND f_score >= 3 AND m_score >= 3 THEN 'Champions'
                WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal'
                WHEN r_score = 4 AND f_score <= 2 THEN 'New / promising'
                WHEN r_score <= 2 AND f_score >= 3 THEN 'At risk'
                WHEN r_score = 1 AND f_score <= 2 THEN 'Lost / hibernating'
                ELSE 'Regular' END AS segment
    FROM scored
)
SELECT segment,
       COUNT(*) AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_customers,
       ROUND(AVG(recency_days), 0) AS avg_recency_days,
       ROUND(AVG(frequency), 2) AS avg_frequency,
       ROUND(SUM(monetary), 2) AS revenue_brl
FROM segmented
GROUP BY 1
ORDER BY revenue_brl DESC;
