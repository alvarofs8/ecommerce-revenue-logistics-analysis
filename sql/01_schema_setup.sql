-- =============================================================================
-- SCRIPT:  01_schema_setup.sql
-- PURPOSE: Define relational database schema, data types, and primary/foreign keys
-- =============================================================================

-- 1. Drop existing tables if they exist to avoid conflicts during schema creation
DROP TABLE IF EXISTS order_reviews;
DROP TABLE IF EXISTS order_payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS product_category_name_translation;
DROP TABLE IF EXISTS sellers;
DROP TABLE IF EXISTS geolocation;

-- 2. Customers Reference Table
CREATE TABLE customers (
    customer_id                 VARCHAR(32) PRIMARY KEY, 
    customer_unique_id          VARCHAR(32) NOT NULL,    
    customer_zip_code_prefix    VARCHAR(10) NOT NULL,
    customer_city               VARCHAR(100) NOT NULL,
    customer_state              VARCHAR(5) NOT NULL
);

-- 3. Sellers Reference Table
CREATE TABLE sellers (
    seller_id                   VARCHAR(32) PRIMARY KEY,
    seller_zip_code_prefix      VARCHAR(10) NOT NULL,
    seller_city                 VARCHAR(100) NOT NULL,
    seller_state                VARCHAR(5) NOT NULL
);

-- 4. Category Translation Lookup Table
CREATE TABLE product_category_name_translation (
    product_category_name           VARCHAR(100) PRIMARY KEY,
    product_category_name_english   VARCHAR(100) NOT NULL
);

-- 5. Products Catalog Table
CREATE TABLE products (
    product_id                  VARCHAR(32) PRIMARY KEY,
    product_category_name       VARCHAR(100),
    product_name_length         INT,
    product_description_length  INT,
    product_photos_qty          INT,
    product_weight_g            DECIMAL(10, 2),
    product_length_cm           DECIMAL(10, 2),
    product_height_cm           DECIMAL(10, 2),
    product_width_cm            DECIMAL(10, 2)
);

-- 7. Geolocation Log (Zip code level coordinates)
CREATE TABLE geolocation (
    geolocation_zip_code_prefix VARCHAR(10) NOT NULL,
    geolocation_lat             DECIMAL(10, 8) NOT NULL,
    geolocation_lng             DECIMAL(11, 8) NOT NULL,
    geolocation_city            VARCHAR(100) NOT NULL,
    geolocation_state           VARCHAR(5) NOT NULL
);

-- 8. Orders Header Table
CREATE TABLE orders (
    order_id                        VARCHAR(32) PRIMARY KEY,
    customer_id                     VARCHAR(32) NOT NULL,
    order_status                    VARCHAR(30) NOT NULL,
    order_purchase_timestamp        TIMESTAMP NOT NULL,
    order_approved_at               TIMESTAMP,
    order_delivered_carrier_date    TIMESTAMP,
    order_delivered_customer_date   TIMESTAMP,
    order_estimated_delivery_date   TIMESTAMP NOT NULL,
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- 9. Order Items Table
CREATE TABLE order_items (
    order_id                    VARCHAR(32) NOT NULL,
    order_item_id               INT NOT NULL,
    product_id                  VARCHAR(32) NOT NULL,
    seller_id                   VARCHAR(32) NOT NULL,
    shipping_limit_date         TIMESTAMP NOT NULL,
    price                       DECIMAL(10, 2) NOT NULL,
    freight_value               DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (order_id, order_item_id),
    CONSTRAINT fk_items_order FOREIGN KEY (order_id) REFERENCES orders(order_id),
    CONSTRAINT fk_items_product FOREIGN KEY (product_id) REFERENCES products(product_id),
    CONSTRAINT fk_items_seller FOREIGN KEY (seller_id) REFERENCES sellers(seller_id)
);

-- 10. Order Payments Table
CREATE TABLE order_payments (
    order_id                    VARCHAR(32) NOT NULL,
    payment_sequential          INT NOT NULL,
    payment_type                VARCHAR(30) NOT NULL,
    payment_installments        INT NOT NULL,
    payment_value               DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (order_id, payment_sequential),
    CONSTRAINT fk_payments_order FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- 11. Order Reviews and Customer Feedback
CREATE TABLE order_reviews (
    review_id                   VARCHAR(32) NOT NULL,
    order_id                    VARCHAR(32) NOT NULL,
    review_score                INT NOT NULL CHECK (review_score BETWEEN 1 AND 5),
    review_comment_title        VARCHAR(255),
    review_comment_message      TEXT,
    review_creation_date        TIMESTAMP NOT NULL,
    review_answer_timestamp     TIMESTAMP NOT NULL,
    PRIMARY KEY (review_id, order_id),
    CONSTRAINT fk_reviews_order FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- 12. Indexes for Performance Optimization
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_purchase_date ON orders(order_purchase_timestamp);
CREATE INDEX idx_order_items_product ON order_items(product_id);
CREATE INDEX idx_order_items_seller ON order_items(seller_id);