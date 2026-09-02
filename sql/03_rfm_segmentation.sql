-- =============================================================================
-- Script: 03_rfm_segmentation.sql
-- Description: Customer Segmentation using RFM methodology via CTEs.
-- =============================================================================

CREATE OR REPLACE VIEW analytics.vw_rfm_segmentation AS

-- 1. Get the reference date (max date in dataset) to calculate Recency
WITH reference_date AS (
    SELECT MAX(order_purchase_timestamp) AS max_date 
    FROM analytics.vw_orders_clean
),

-- 2. Calculate raw R, F, M values per unique customer
customer_base AS (
    SELECT 
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp) AS last_purchase_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(p.payment_value) AS monetary
    FROM analytics.vw_customers_clean c
    JOIN analytics.vw_orders_clean o 
        ON c.customer_id = o.customer_id
    JOIN public.order_payments p 
        ON o.order_id = p.order_id
    GROUP BY c.customer_unique_id
),

-- 3. Calculate Recency in days
rfm_calc AS (
    SELECT 
        cb.customer_unique_id,
        EXTRACT(DAY FROM (rd.max_date - cb.last_purchase_date)) AS recency_days,
        cb.frequency,
        cb.monetary
    FROM customer_base cb
    CROSS JOIN reference_date rd
),

-- 4. Assign scores from 1 to 5 (5 is the best)
rfm_scores AS (
    SELECT 
        customer_unique_id,
        recency_days,
        frequency,
        monetary,
        -- R Score: 5 is best (lowest recency). NTILE(DESC) gives 5 to lowest numbers.
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        -- F Score: Custom logic due to 96% one-time buyers in Olist.
        CASE 
            WHEN frequency = 1 THEN 1
            WHEN frequency = 2 THEN 2
            WHEN frequency = 3 THEN 3
            WHEN frequency = 4 THEN 4
            ELSE 5 
        END AS f_score,
        -- M Score: 5 is best (highest spend). NTILE(ASC) gives 5 to highest numbers.
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_calc
)

-- 5. Final Segmentation Logic
SELECT 
    customer_unique_id,
    recency_days,
    frequency,
    monetary,
    (r_score::text || f_score::text || m_score::text) AS rfm_score_string,
    CASE
        WHEN r_score >= 4 AND f_score >= 2 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 2 AND m_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 3 AND f_score = 1 THEN 'Recent New Customers'
        WHEN r_score <= 2 AND f_score >= 2 THEN 'At Risk (Churning)'
        WHEN r_score <= 2 AND f_score = 1 THEN 'Lost One-Timers'
        ELSE 'Regulars/Others'
    END AS customer_segment
FROM rfm_scores;