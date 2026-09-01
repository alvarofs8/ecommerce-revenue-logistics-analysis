-- =============================================================================
-- Script: 02_data_cleaning.sql
-- Description: Create analytical views, handle nulls, and translate categories.
-- =============================================================================

-- Schema creation for analytics views
CREATE SCHEMA IF NOT EXISTS analytics;

-- Cleaning and translating product categories
CREATE OR REPLACE VIEW analytics.vw_products_clean AS
SELECT 
    p.product_id,
    COALESCE(pct.product_category_name_english, 'unknown_category') AS product_category_english,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM public.products p
LEFT JOIN public.product_category_name_translation pct 
    ON p.product_category_name = pct.product_category_name;

-- Cleaning order data
CREATE OR REPLACE VIEW analytics.vw_orders_clean AS
SELECT 
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    -- Calculating delivery performance metrics
    EXTRACT(DAY FROM (order_delivered_customer_date - order_purchase_timestamp)) AS actual_delivery_days,
    EXTRACT(DAY FROM (order_delivered_customer_date - order_estimated_delivery_date)) AS delivery_variance_days
FROM public.orders
WHERE order_status = 'delivered' 
  AND order_delivered_customer_date IS NOT NULL;

-- Cleaning and standardizing customer data
CREATE OR REPLACE VIEW analytics.vw_customers_clean AS
SELECT 
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    LOWER(TRIM(customer_city)) AS customer_city,
    UPPER(customer_state) AS customer_state
FROM public.customers;