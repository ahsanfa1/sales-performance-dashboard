-- CUSTOMERS
CREATE TABLE customers ( customer_id VARCHAR(50) PRIMARY KEY, customer_unique_id VARCHAR(50), 
 customer_zip_code_prefix VARCHAR(10), customer_city VARCHAR(100), customer_state VARCHAR(2) );

 SELECT * FROM customers LIMIT 10;

-- Sellers
CREATE TABLE sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(10),
    seller_city VARCHAR(50),
    seller_state VARCHAR(2)
);

-- Products
CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(50),
    product_name_length SMALLINT,
    product_description_length SMALLINT,
    product_photos_qty SMALLINT,
    product_weight_g INTEGER,
    product_length_cm SMALLINT,
    product_height_cm SMALLINT,
    product_width_cm SMALLINT
);

-- Product category name translation (Portuguese -> English)
CREATE TABLE product_category_name_translation (
    product_category_name VARCHAR(50) PRIMARY KEY,
    product_category_name_english VARCHAR(50)
);

-- Geolocation (Brazilian zip codes -> lat/lng)
CREATE TABLE geolocation (
    geolocation_zip_code_prefix VARCHAR(10),
    geolocation_lat DOUBLE PRECISION,
    geolocation_lng DOUBLE PRECISION,
    geolocation_city VARCHAR(50),
    geolocation_state VARCHAR(2)
);

-- Orders (the main table)
CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50) REFERENCES customers(customer_id),
    order_status VARCHAR(20),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

-- Order items
CREATE TABLE order_items (
    order_id VARCHAR(50) REFERENCES orders(order_id),
    order_item_id SMALLINT,
    product_id VARCHAR(50) REFERENCES products(product_id),
    seller_id VARCHAR(50) REFERENCES sellers(seller_id),
    shipping_limit_date TIMESTAMP,
    price NUMERIC(10,2),
    freight_value NUMERIC(10,2),
    PRIMARY KEY (order_id, order_item_id)
);

-- Order payments
CREATE TABLE order_payments (
    order_id VARCHAR(50) REFERENCES orders(order_id),
    payment_sequential SMALLINT,
    payment_type VARCHAR(20),
    payment_installments SMALLINT,
    payment_value NUMERIC(10,2),
    PRIMARY KEY (order_id, payment_sequential)
);

-- Order reviews 
CREATE TABLE order_reviews (
    review_id VARCHAR(50),
    order_id VARCHAR(50) REFERENCES orders(order_id),
    review_score SMALLINT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);

SELECT COUNT(*) FROM orders; 
SELECT * FROM order_items LIMIT 5; 
SELECT COUNT(*) FROM geolocation;

SELECT review_id, order_id, COUNT(*)
FROM order_reviews
GROUP BY review_id, order_id
HAVING COUNT(*) > 1;

ALTER TABLE order_reviews ADD PRIMARY KEY (review_id, order_id);