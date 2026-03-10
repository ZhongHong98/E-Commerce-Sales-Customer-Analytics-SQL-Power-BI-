-- DROP TABLE IF EXISTS orders;
-- CREATE TABLE orders (
--     order_id VARCHAR PRIMARY KEY,
--     customer_id VARCHAR,
--     order_status VARCHAR,
--     order_purchase_timestamp TIMESTAMP,
--     order_approved_at TIMESTAMP,
--     order_delivered_carrier_date TIMESTAMP,
--     order_delivered_customer_date TIMESTAMP,
--     order_estimated_delivery_date TIMESTAMP
-- );

-- DROP TABLE IF EXISTS customers;
-- CREATE TABLE customers (
--     customer_id VARCHAR PRIMARY KEY,
--     customer_unique_id VARCHAR,
--     customer_zip_code_prefix VARCHAR,
--     customer_city VARCHAR,
--     customer_state VARCHAR
-- );

-- DROP TABLE IF EXISTS order_reviews;
-- CREATE TABLE order_reviews (
--     order_review_id SERIAL PRIMARY KEY,
--     review_id VARCHAR,
--     order_id VARCHAR,
--     review_score INTEGER,
--     review_comment_title TEXT,
--     review_comment_message TEXT,
--     review_creation_date TIMESTAMP,
--     review_answer_timestamp TIMESTAMP
-- );

-- DROP TABLE IF EXISTS geolocation;
-- CREATE TABLE geolocation (
--     geolocation_id SERIAL PRIMARY KEY,
--     geolocation_zip_code_prefix VARCHAR,
--     geolocation_lat DECIMAL (15, 13),
--     geolocation_lng DECIMAL (15,13),
--     geolocation_city VARCHAR,
--     geolocation_state VARCHAR
-- );

-- DROP TABLE IF EXISTS order_items;
-- CREATE TABLE order_items (
--     order_items_serial_id SERIAL PRIMARY KEY,
--     order_id VARCHAR,
--     order_item_id INTEGER,
--     product_id VARCHAR,
--     seller_id VARCHAR,
--     shipping_limit_date TIMESTAMP,
--     price DECIMAL (10,2),
--     freight_value DECIMAL (10,2)
-- );

-- DROP TABLE IF EXISTS order_payments;
-- CREATE TABLE order_payments (
--     order_payments_id SERIAL PRIMARY KEY,
--     order_id VARCHAR,
--     payment_sequential INTEGER,
--     payment_type VARCHAR,
--     payment_installments INTEGER,
--     payment_value DECIMAL (10,2)
-- );

-- DROP TABLE IF EXISTS products;
-- CREATE TABLE products (
--     product_id VARCHAR PRIMARY KEY,
--     product_category_name VARCHAR,
--     product_name_length INTEGER,
--     product_description_length INTEGER,
--     product_photos_qty INTEGER,
--     product_weight_g INTEGER,
--     product_length_cm INTEGER,
--     product_height_cm INTEGER,
--     product_width_cm INTEGER
-- );

-- DROP TABLE IF EXISTS sellers;
-- CREATE TABLE sellers (
--     seller_id VARCHAR PRIMARY KEY,
--     seller_zip_code_prefix VARCHAR,
--     seller_city VARCHAR,
--     seller_state VARCHAR
-- );

-- DROP TABLE IF EXISTS product_category_name_translation;
-- CREATE TABLE product_category_name_translation (
--     product_category_name VARCHAR PRIMARY KEY,
--     product_category_name_english VARCHAR
-- );

-- The table create and data import is done on Neon website

-- -- Create a new table and remove latitude and longitude
-- CREATE TABLE geolocation_cleaned AS
-- SELECT 
--     geolocation_zip_code_prefix,
--     -- Using MAX for city/state picks one valid name if there are typos
--     MAX(geolocation_city) AS city, 
--     MAX(geolocation_state) AS state
-- FROM geolocation
-- GROUP BY geolocation_zip_code_prefix;

-- -- Create a new table remove customer_city and customer_state
-- CREATE TABLE customers_cleaned AS 
-- SELECT 
--     customer_id, 
--     customer_unique_id,
--     customer_zip_code_prefix
-- FROM customers;

-- -- Create the new cleaned seller table remove seller_city and seller_state
-- CREATE TABLE sellers_cleaned AS
-- SELECT 
--     seller_id, 
--     seller_zip_code_prefix
-- FROM sellers;

-- -- Set primary key for each table
-- ALTER TABLE orders
-- ADD PRIMARY KEY (order_id);

-- ALTER TABLE order_reviews
-- ADD COLUMN order_review_id SERIAL PRIMARY KEY;

-- ALTER TABLE order_items
-- ADD COLUMN order_items_serial_id SERIAL PRIMARY KEY;

-- ALTER TABLE order_payments
-- ADD COLUMN order_payments_id SERIAL PRIMARY KEY;

-- ALTER TABLE products
-- ADD PRIMARY KEY (product_id);

-- ALTER TABLE product_category_name_translation
-- ADD PRIMARY KEY (product_category_name);

-- ALTER TABLE geolocation_cleaned 
-- ADD PRIMARY KEY (geolocation_zip_code_prefix);

-- ALTER TABLE customers_cleaned
-- ADD PRIMARY KEY (customer_id);

-- ALTER TABLE sellers_cleaned 
-- ADD PRIMARY KEY (seller_id);

-- -- Add reference to create relationship between each table
-- -- order to cusomters
-- ALTER TABLE orders
-- ADD CONSTRAINT fk_orders_customer
-- FOREIGN KEY (customer_id) REFERENCES customers_cleaned(customer_id);

-- -- order_items to Orders
-- ALTER TABLE order_items
-- ADD CONSTRAINT fk_items_orders
-- FOREIGN KEY (order_id) REFERENCES orders(order_id);

-- -- order_items to Products
-- ALTER TABLE order_items
-- ADD CONSTRAINT fk_items_products
-- FOREIGN KEY (product_id) REFERENCES products(product_id);

-- -- order_items to Sellers
-- ALTER TABLE order_items
-- ADD CONSTRAINT fk_items_sellers
-- FOREIGN KEY (seller_id) REFERENCES sellers_cleaned(seller_id);

-- -- order_payments to orders
-- ALTER TABLE order_payments
-- ADD CONSTRAINT fk_payments_orders
-- FOREIGN KEY (order_id) REFERENCES orders(order_id);

-- -- order_reviews to orders
-- ALTER TABLE order_reviews
-- ADD CONSTRAINT fk_reviews_orders
-- FOREIGN KEY (order_id) REFERENCES orders(order_id);

-- -- Fill in missing zip code and set city and state as unknown
-- INSERT INTO geolocation_cleaned (geolocation_zip_code_prefix, city, state)
-- SELECT DISTINCT c.customer_zip_code_prefix, 'Unknown', 'Unknown'
-- FROM customers_cleaned c
-- LEFT JOIN geolocation_cleaned g ON c.customer_zip_code_prefix = g.geolocation_zip_code_prefix
-- WHERE g.geolocation_zip_code_prefix IS NULL;

-- INSERT INTO geolocation_cleaned (geolocation_zip_code_prefix, city, state)
-- SELECT DISTINCT s.seller_zip_code_prefix, 'Unknown', 'Unknown'
-- FROM sellers_cleaned s
-- LEFT JOIN geolocation_cleaned g ON s.seller_zip_code_prefix = g.geolocation_zip_code_prefix
-- WHERE g.geolocation_zip_code_prefix IS NULL;

-- -- customers to geolocation
-- ALTER TABLE customers_cleaned
-- ADD CONSTRAINT fk_customer_geo
-- FOREIGN KEY (customer_zip_code_prefix) REFERENCES geolocation_cleaned(geolocation_zip_code_prefix);

-- -- sellers to geolocation
-- ALTER TABLE sellers_cleaned
-- ADD CONSTRAINT fk_seller_geo
-- FOREIGN KEY (seller_zip_code_prefix) 
-- REFERENCES geolocation_cleaned(geolocation_zip_code_prefix);

-- Check null value
/* 1. ORDER_ITEMS */
SELECT
    COUNT(*) - COUNT(order_id) AS null_order_id,
    COUNT(*) - COUNT(order_item_id) AS null_order_item,
    COUNT(*) - COUNT(product_id) AS null_product_id,
    COUNT(*) - COUNT(seller_id) AS null_seller_id,
    COUNT(*) - COUNT(shipping_limit_date) AS null_shipping_date,
    COUNT(*) - COUNT(price) AS null_price,
    COUNT(*) - COUNT(freight_value) AS null_freight
FROM order_items;

/* 2. ORDER_PAYMENTS */
SELECT
    COUNT(*) - COUNT(order_id) AS null_order_id,
    COUNT(*) - COUNT(payment_sequential) AS null_payment_seq,
    COUNT(*) - COUNT(payment_type) AS null_payment_type,
    COUNT(*) - COUNT(payment_installments) AS null_installments,
    COUNT(*) - COUNT(payment_value) AS null_value
FROM order_payments;

/* 3. ORDER_REVIEWS */
SELECT
    COUNT(*) - COUNT(review_id) AS null_review_id,
    COUNT(*) - COUNT(order_id) AS null_order_id,
    COUNT(*) - COUNT(review_score) AS null_score,
    COUNT(*) - COUNT(review_comment_title) AS null_title,
    COUNT(*) - COUNT(review_comment_message) AS null_message,
    COUNT(*) - COUNT(review_creation_date) AS null_creation_date,
    COUNT(*) - COUNT(review_answer_timestamp) AS null_answer_time
FROM order_reviews;

-- /* 4. ORDERS */
-- SELECT
--     COUNT(*) - COUNT(order_id) AS null_order_id,
--     COUNT(*) - COUNT(customer_id) AS null_customer_id,
--     COUNT(*) - COUNT(order_status) AS null_status,
--     COUNT(*) - COUNT(order_purchase_timestamp) AS null_purchase_time,
--     COUNT(*) - COUNT(order_approved_at) AS null_approved,
--     COUNT(*) - COUNT(order_delivered_carrier_date) AS null_carrier_date,
--     COUNT(*) - COUNT(order_delivered_customer_date) AS null_customer_date,
--     COUNT(*) - COUNT(order_estimated_delivery_date) AS null_estimated_date
-- FROM orders
-- WHERE order_status = 'delivered';

-- -- Create view to filter delivered and not null value
-- CREATE VIEW orders_cleaned AS
-- SELECT *
-- FROM orders
-- WHERE order_status = 'delivered'
--   AND order_delivered_customer_date IS NOT NULL
--   AND order_delivered_carrier_date IS NOT NULL
--   AND order_approved_at IS NOT NULL;

/* 4. ORDERS_CLEANED */
SELECT
    COUNT(*) - COUNT(order_id) AS null_order_id,
    COUNT(*) - COUNT(customer_id) AS null_customer_id,
    COUNT(*) - COUNT(order_status) AS null_status,
    COUNT(*) - COUNT(order_purchase_timestamp) AS null_purchase_time,
    COUNT(*) - COUNT(order_approved_at) AS null_approved,
    COUNT(*) - COUNT(order_delivered_carrier_date) AS null_carrier_date,
    COUNT(*) - COUNT(order_delivered_customer_date) AS null_customer_date,
    COUNT(*) - COUNT(order_estimated_delivery_date) AS null_estimated_date
FROM orders_cleaned
WHERE order_status = 'delivered';

-- /* 5. PRODUCTS */
-- SELECT
--     COUNT(*) - COUNT(product_id) AS null_id,
--     COUNT(*) - COUNT(product_category_name) AS null_category,
--     COUNT(*) - COUNT(product_name_lenght) AS null_name_len,
--     COUNT(*) - COUNT(product_description_lenght) AS null_desc_len,
--     COUNT(*) - COUNT(product_photos_qty) AS null_photos,
--     COUNT(*) - COUNT(product_weight_g) AS null_weight,
--     COUNT(*) - COUNT(product_length_cm) AS null_length,
--     COUNT(*) - COUNT(product_height_cm) AS null_height,
--     COUNT(*) - COUNT(product_width_cm) AS null_width
-- FROM products;

-- -- Create new view named products_cleaned, replace null product_category_name to others,
-- -- replace null integer value to 0
-- CREATE VIEW products_cleaned AS
-- SELECT 
--     product_id,
--     COALESCE(product_category_name, 'others') AS product_category_name,
--     COALESCE(product_name_lenght, 0) AS product_name_lenght,
--     COALESCE(product_description_lenght, 0) AS product_description_lenght,
--     COALESCE(product_photos_qty, 0) AS product_photos_qty,
--     COALESCE(product_weight_g, 0) AS product_weight_g,
--     COALESCE(product_length_cm, 0) AS product_length_cm,
--     COALESCE(product_height_cm, 0) AS product_height_cm,
--     COALESCE(product_width_cm, 0) AS product_width_cm
-- FROM products;

/* 5. PRODUCTS_CLEANED */
SELECT
    COUNT(*) - COUNT(product_id) AS null_id,
    COUNT(*) - COUNT(product_category_name) AS null_category,
    COUNT(*) - COUNT(product_name_lenght) AS null_name_len,
    COUNT(*) - COUNT(product_description_lenght) AS null_desc_len,
    COUNT(*) - COUNT(product_photos_qty) AS null_photos,
    COUNT(*) - COUNT(product_weight_g) AS null_weight,
    COUNT(*) - COUNT(product_length_cm) AS null_length,
    COUNT(*) - COUNT(product_height_cm) AS null_height,
    COUNT(*) - COUNT(product_width_cm) AS null_width
FROM products_cleaned;

/* 6. PRODUCT_CATEGORY_NAME_TRANSLATION */
SELECT
    COUNT(*) - COUNT(product_category_name) AS null_name,
    COUNT(*) - COUNT(product_category_name_english) AS null_english
FROM product_category_name_translation;

/* 7. CUSTOMERS_CLEANED */
SELECT
    COUNT(*) - COUNT(customer_id) AS null_id,
    COUNT(*) - COUNT(customer_unique_id) AS null_unique_id,
    COUNT(*) - COUNT(customer_zip_code_prefix) AS null_zip
FROM customers_cleaned;

/* 8. GEOLOCATION_CLEANED */
SELECT
    COUNT(*) - COUNT(geolocation_zip_code_prefix) AS null_zip,
    COUNT(*) - COUNT(city) AS null_city,
    COUNT(*) - COUNT(state) AS null_state
FROM geolocation_cleaned;

/* 9. SELLERS_CLEANED */
SELECT
    COUNT(*) - COUNT(seller_id) AS null_id,
    COUNT(*) - COUNT(seller_zip_code_prefix) AS null_zip
FROM sellers_cleaned;

-- Check abnormal price
SELECT *
FROM order_items
WHERE price <= 0;

-- DROP VIEW fact_sales;

-- -- Create fact_sales, and create deleivery_delay_days
-- CREATE VIEW fact_sales AS
-- SELECT 
--     oi.order_id,
--     o.order_purchase_timestamp::date AS order_date,
--     o.customer_id,
--     c.customer_unique_id,
--     g.city AS customer_city,
--     g.state AS customer_state,
--     oi.product_id,
--     oi.seller_id,
--     oi.price,
--     oi.freight_value,
--     (oi.price + oi.freight_value) AS total_value,
--     r.review_score,
--     EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date))::INT AS delivery_delay_days,
--     pc.product_category_name
-- FROM order_items oi
-- LEFT JOIN orders o ON oi.order_id = o.order_id
-- LEFT JOIN order_reviews r ON oi.order_id = r.order_id
-- LEFT JOIN products_cleaned pc ON oi.product_id = pc.product_id
-- LEFT JOIN customers_cleaned c ON o.customer_id = c.customer_id
-- -- Join to Geolocation using the zip code from the customer table
-- LEFT JOIN (
--     SELECT DISTINCT 
--         geolocation_zip_code_prefix, 
--         city, 
--         state 
--     FROM geolocation_cleaned
-- ) g ON c.customer_zip_code_prefix = g.geolocation_zip_code_prefix;

-- Total Revenue
SELECT SUM(total_value) AS total_revenue
FROM fact_sales;

-- Monthly Revenue
SELECT 
    DATE_TRUNC('month', order_date) AS month,
    SUM(total_value) AS revenue
FROM fact_sales
GROUP BY month
ORDER BY month;

-- Average Order Value (AOV)
SELECT 
    SUM(total_value) / COUNT(DISTINCT order_id) AS avg_order_value
FROM fact_sales;

-- Top 5 and Bottom 5 Revenue by Category
SELECT 
    product_category_name,
    SUM(total_value) AS Top_5_Revenue
FROM fact_sales
GROUP BY product_category_name
ORDER BY Top_5_Revenue DESC
LIMIT 5;

SELECT 
    product_category_name,
    SUM(total_value) AS Bottom_5_Revenue
FROM fact_sales
GROUP BY product_category_name
ORDER BY Bottom_5_Revenue ASC
LIMIT 5;

-- Repeat Purchase Rate
WITH customer_orders AS (
    SELECT customer_unique_id, COUNT(DISTINCT order_id) AS order_count
    FROM fact_sales
    GROUP BY customer_unique_id
)

SELECT 
    COUNT(*) FILTER (WHERE order_count > 1) * 100.0 / COUNT(*) AS repeat_rate
FROM customer_orders;

-- Late Delivery %
SELECT 
    COUNT(*) FILTER (WHERE delivery_delay_days > 0) * 100.0 / COUNT(*) AS late_delivery_pct
FROM fact_sales;

-- Review Score vs Delay
SELECT 
    review_score,
    AVG(delivery_delay_days) AS avg_delay
FROM fact_sales
GROUP BY review_score
ORDER BY review_score;

-- Calculate RFM Base Table
WITH rfm_base AS (
    SELECT
        customer_unique_id,
        MAX(order_date) AS last_purchase,
        COUNT(DISTINCT order_id) AS frequency,
        SUM(total_value) AS monetary
    FROM fact_sales
    GROUP BY customer_unique_id
)

SELECT *,
    CURRENT_DATE - last_purchase AS recency
FROM rfm_base
ORDER BY frequency DESC
LIMIT 10;

-- Score Each 1-5 (Using NTILE)
WITH rfm_base AS (
    -- Step 1: Aggregate the data
    SELECT
        customer_unique_id,
        MAX(order_date) AS last_purchase,
        COUNT(DISTINCT order_id) AS frequency,
        SUM(total_value) AS monetary
    FROM fact_sales
    GROUP BY customer_unique_id
),
rfm AS (
    -- Step 2: Calculate Recency and Scores using the data from Step 1
    SELECT *,
        -- Note: Recency is better calculated as (Max Date in Data - last_purchase) 
        -- but here we use your current logic:
        NTILE(5) OVER (ORDER BY (CURRENT_DATE - last_purchase) DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency) AS f_score,
        NTILE(5) OVER (ORDER BY monetary) AS m_score
    FROM rfm_base
)
-- Step 3: Final Output
SELECT *,
    (r_score + f_score + m_score) AS total_score
FROM rfm
ORDER BY total_score DESC
LIMIT 10;

-- Monthly Order
SELECT 
    DATE_TRUNC('month', order_date) AS month,
    COUNT(DISTINCT order_id) AS orders
FROM fact_sales
GROUP BY month
ORDER BY month
LIMIT 10;

-- Category Growth
SELECT 
    DATE_TRUNC('month', order_date) AS month,
    product_category_name,
    SUM(total_value) AS revenue
FROM fact_sales
GROUP BY month, product_category_name
LIMIT 10;

-- Top 10 Products
SELECT 
    product_id,
    SUM(total_value) AS revenue
FROM fact_sales
GROUP BY product_id
ORDER BY revenue DESC
LIMIT 10;

-- Seller Performance
SELECT 
    seller_id,
    SUM(total_value) AS revenue,
    AVG(review_score) AS avg_review
FROM fact_sales
GROUP BY seller_id
ORDER BY revenue DESC
LIMIT 10;
