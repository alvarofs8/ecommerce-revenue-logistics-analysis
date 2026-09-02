-- =============================================================================
-- Script: 05_views_for_powerbi.sql
-- Description: Star Schema views prepared for Power BI.
-- =============================================================================

-- 1. FACT TABLE: Order Items (Granular sales, freight, and delivery metrics)
CREATE OR REPLACE VIEW analytics.vw_pbi_fact_orders AS
SELECT 
    oi.order_id,
    oi.order_item_id,
    o.customer_id,
    oi.seller_id,
    oi.product_id,
    o.order_purchase_timestamp::date AS purchase_date,
    o.order_delivered_customer_date::date AS delivery_date,
    o.order_estimated_delivery_date::date AS estimated_delivery_date,
    o.order_status,
    o.actual_delivery_days,
    o.delivery_variance_days,
    oi.price AS item_price,
    oi.freight_value,
    (oi.price + oi.freight_value) AS total_item_value
FROM public.order_items oi
JOIN analytics.vw_orders_clean o 
    ON oi.order_id = o.order_id;

-- 2. DIMENSION TABLE: Customers with Pre-calculated RFM Segment
CREATE OR REPLACE VIEW analytics.vw_pbi_dim_customers AS
SELECT 
    c.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    c.customer_zip_code_prefix,
    COALESCE(rfm.customer_segment, 'Unsegmented') AS customer_segment,
    rfm.recency_days,
    rfm.frequency,
    rfm.monetary
FROM analytics.vw_customers_clean c
LEFT JOIN analytics.vw_rfm_segmentation rfm 
    ON c.customer_unique_id = rfm.customer_unique_id;

-- 3. DIMENSION TABLE: Products (Cleaned English categories)
CREATE OR REPLACE VIEW analytics.vw_pbi_dim_products AS
SELECT 
    product_id,
    product_category_english,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM analytics.vw_products_clean;

-- 4. DIMENSION TABLE: Sellers (Standardized geographic locations)
CREATE OR REPLACE VIEW analytics.vw_pbi_dim_sellers AS
SELECT 
    seller_id,
    LOWER(TRIM(seller_city)) AS seller_city,
    UPPER(seller_state) AS seller_state,
    seller_zip_code_prefix
FROM public.sellers;