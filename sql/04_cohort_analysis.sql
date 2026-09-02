-- =============================================================================
-- Script: 04_cohort_analysis.sql
-- Description: Customer Retention Matrix / Cohort Analysis by Acquisition Month.
-- =============================================================================

CREATE OR REPLACE VIEW analytics.vw_cohort_retention AS

-- 1. Identify the first purchase date (Cohort) per unique customer
WITH customer_cohort AS (
    SELECT 
        c.customer_unique_id,
        DATE_TRUNC('month', MIN(o.order_purchase_timestamp))::date AS cohort_month
    FROM analytics.vw_customers_clean c
    JOIN analytics.vw_orders_clean o 
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
),

-- 2. Extract transaction months and compute the period index (Month 0, 1, 2...)
order_activities AS (
    SELECT 
        c.customer_unique_id,
        cc.cohort_month,
        DATE_TRUNC('month', o.order_purchase_timestamp)::date AS order_month,
        (
            (EXTRACT(YEAR FROM o.order_purchase_timestamp) - EXTRACT(YEAR FROM cc.cohort_month)) * 12 +
            (EXTRACT(MONTH FROM o.order_purchase_timestamp) - EXTRACT(MONTH FROM cc.cohort_month))
        )::int AS month_index
    FROM analytics.vw_customers_clean c
    JOIN analytics.vw_orders_clean o 
        ON c.customer_id = o.customer_id
    JOIN customer_cohort cc 
        ON c.customer_unique_id = cc.customer_unique_id
),

-- 3. Calculate cohort size (Total users acquired at Month 0)
cohort_sizes AS (
    SELECT 
        cohort_month,
        COUNT(DISTINCT customer_unique_id) AS total_cohort_users
    FROM customer_cohort
    GROUP BY cohort_month
)

-- 4. Final Aggregation: Retention counts and retention rates (%)
SELECT 
    oa.cohort_month,
    cs.total_cohort_users,
    oa.month_index,
    COUNT(DISTINCT oa.customer_unique_id) AS active_customers,
    ROUND(
        (COUNT(DISTINCT oa.customer_unique_id) * 100.0 / cs.total_cohort_users), 
        2
    ) AS retention_rate
FROM order_activities oa
JOIN cohort_sizes cs 
    ON oa.cohort_month = cs.cohort_month
GROUP BY oa.cohort_month, cs.total_cohort_users, oa.month_index
ORDER BY oa.cohort_month, oa.month_index;

SELECT * 
FROM analytics.vw_cohort_retention
WHERE cohort_month BETWEEN '2017-01-01' AND '2017-06-01'
  AND month_index <= 6
ORDER BY cohort_month, month_index;