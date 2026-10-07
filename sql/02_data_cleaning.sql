/*

DATA CLEANING RESULTS:

1. 6 out of 9 tables: no missing values

2. products: 610 rows with missing values for category, name_length, description_length, 
and photos_qty. Confirmed that same 610 rows have missing values for all 4 columns. Leaving
NULL values as they are, to not distort data. 2 rows missing all physical measurements.
Confirmed same 2 rows. Left as they are, since this is a very small number relative to our dataset.

3. orders: Assumption made that orders missing delivery dates were probably just never delivered. Confirmed
that missing delivery dates mostly match orders that were never delivered (canceled, unavailable, etc.).
Exception: 8 orders with status "delivered" are still missing a delivery date. This was a real anomaly, not explained by 
status.
- order_reviews: 88% missing title, 59% missing comment message. Expected, as most reviewers 
just leave a star rating without text. 

4. Checking for any translation issues: product_category_name_translation - Found 2 product 
categories in "products" with no matching English translation
(portateis_cozinha_e_preparadores_de_alimentos, pc_gamer). Added both directly via INSERT, 
since these were real categories in the table. Re-ran the check, 0 unmatched categories.

5. Repeat customers (customers with more than one order): customer_id is unique per order, 
not per customer. So repeat customers get new id each order. customer_unique_id identifies 
distinct customers. 

6. Confirmed 99,441 customer_id rows vs. 96,096 customer_unique_id rows (confirms customer_id 
inflates the number of customers). 

7. Confirmed 2,997 customers (customer_unique_id) placed more than one order. 
Highest # of orders for 1 customer: 17

8. Calculated repeat purchase rate using customer_unique_id: 3.12% (2,997 of 96,096 
unique customers ordered more than once).
*/

-- Check for missing values in each table

-- Customers
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(customer_unique_id) AS missing_unique_id, -- Total # of Rows - # of Rows where this column is NOT null
    COUNT(*) - COUNT(customer_zip_code_prefix) AS missing_zip,
    COUNT(*) - COUNT(customer_city) AS missing_city,
    COUNT(*) - COUNT(customer_state) AS missing_state
FROM customers;

-- Sellers
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(seller_zip_code_prefix) AS missing_zip,
    COUNT(*) - COUNT(seller_city) AS missing_city,
    COUNT(*) - COUNT(seller_state) AS missing_state
FROM sellers;

-- Products

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(product_category_name) AS missing_category,
    COUNT(*) - COUNT(product_name_length) AS missing_name_length,
    COUNT(*) - COUNT(product_description_length) AS missing_description_length,
    COUNT(*) - COUNT(product_photos_qty) AS missing_photos_qty,
    COUNT(*) - COUNT(product_weight_g) AS missing_weight,
    COUNT(*) - COUNT(product_length_cm) AS missing_length_cm,
    COUNT(*) - COUNT(product_height_cm) AS missing_height_cm,
    COUNT(*) - COUNT(product_width_cm) AS missing_width_cm
FROM products;

/* After running this, there were 610 rows with missing values for category, name_length, 
description_length, and photos_qty. To check that they were the same 610 rows: */

-- Look directly at the products missing all 4 fields together, to confirm if they were the 
-- same rows
SELECT product_id, product_category_name, product_name_length, product_description_length,
product_photos_qty
FROM products
WHERE product_category_name IS NULL;

-- Analyze 2 rows with missing physical dimensions
SELECT product_id, product_weight_g, product_length_cm, product_height_cm, product_width_cm
FROM products
WHERE product_weight_g IS NULL;

-- Product category name translation
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(product_category_name_english) AS missing_english_translation
FROM product_category_name_translation;

-- Geolocation
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(geolocation_zip_code_prefix) AS missing_zip,
    COUNT(*) - COUNT(geolocation_lat) AS missing_lat,
    COUNT(*) - COUNT(geolocation_lng) AS missing_lng,
    COUNT(*) - COUNT(geolocation_city) AS missing_city,
    COUNT(*) - COUNT(geolocation_state) AS missing_state
FROM geolocation;

-- Orders
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(order_approved_at) AS missing_approved_at,
    COUNT(*) - COUNT(order_delivered_carrier_date) AS missing_carrier_date,
    COUNT(*) - COUNT(order_delivered_customer_date) AS missing_delivered_date
FROM orders;

-- Count how many orders for each status
SELECT order_status, COUNT(*)
FROM orders
GROUP BY order_status
ORDER BY COUNT(*) DESC;

/* Testing hypothesis: orders missing a delivery date are simply orders that were never delivered
(could be canceled, unavailable, etc.), not a data error. Filter to only orders with no delivery 
date, then group by status. */
SELECT order_status, COUNT(*)
FROM orders
WHERE order_delivered_customer_date IS NULL
GROUP BY order_status
ORDER BY COUNT(*) DESC;

/* After running this, the data showed that the number of orders with delivery status other 
than "delivered" that had missing delivery dates was equal to the number of orders with missing_delivered_date from
two blocks of code above. However, there were 8 delivered orders with missing delivery dates. */

-- Investigate those 8 rows:
SELECT order_id, customer_id, order_status, order_purchase_timestamp,
       order_approved_at, order_delivered_carrier_date,
       order_delivered_customer_date, order_estimated_delivery_date
FROM orders
WHERE order_status = 'delivered' AND order_delivered_customer_date IS NULL;

-- Check whether these 8 "delivered but no date" orders have a customer review on file.

SELECT o.order_id, o.order_delivered_carrier_date, r.review_score, r.review_creation_date
FROM orders o
LEFT JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NULL;

/* 7 out of 8 have order_delivered_carrier_date, meaning they got shipped. All have customer 
review scores. These deliveries were probably just not logged correctly. */ 

SELECT o.order_id, o.order_purchase_timestamp, o.order_approved_at, r.review_score, r.review_comment_message
FROM orders o
LEFT JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered' 
  AND o.order_delivered_customer_date IS NULL
  AND o.order_delivered_carrier_date IS NULL;

/* Of the 8 "delivered but no date" orders, 1 is also missing its carrier date entirely.
Still has a 5-star review with no complaint, so it was probably delivered. Most likely a 
logging mistake rather than an anomaly. */

SELECT o.order_id, r.review_score, r.review_comment_message
FROM orders o
LEFT JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered' 
  AND o.order_delivered_customer_date IS NULL
  AND o.order_delivered_carrier_date IS NOT NULL;

-- Order items
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(product_id) AS missing_product_id,
    COUNT(*) - COUNT(seller_id) AS missing_seller_id,
    COUNT(*) - COUNT(shipping_limit_date) AS missing_shipping_limit_date,
    COUNT(*) - COUNT(price) AS missing_price,
    COUNT(*) - COUNT(freight_value) AS missing_freight_value
FROM order_items;

-- Order payments
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(payment_type) AS missing_payment_type,
    COUNT(*) - COUNT(payment_installments) AS missing_installments,
    COUNT(*) - COUNT(payment_value) AS missing_payment_value
FROM order_payments;

-- Order reviews
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(review_comment_title) AS missing_title,
    COUNT(*) - COUNT(review_comment_message) AS missing_message
FROM order_reviews;

/* Missing title/message is expected, not an error: most people leave a rating without 
writing anything. Leaving as-is, no further investigation needed. */

/* Checking for translation issues: 
- any product categories that exist in "products" but have no matching row in the 
translation table. */

SELECT DISTINCT p.product_category_name
FROM products p
LEFT JOIN product_category_name_translation t 
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL 
    AND t.product_category_name IS NULL;

-- Add the 2 missing category translations directly to the table

INSERT INTO product_category_name_translation (product_category_name, 
product_category_name_english)
VALUES
    ('portateis_cozinha_e_preparadores_de_alimentos', 'portable_kitchen_and_food_preparers'),
    ('pc_gamer', 'gaming_pc');

-- Repeat Customers:

-- Compare raw customer_id count vs distinct customer_unique_id count 

SELECT 
    COUNT(customer_id) AS customer_id_count,
    COUNT(DISTINCT customer_unique_id) AS unique_customer_count
FROM customers;

-- Find customers who placed more than one order

SELECT customer_unique_id, COUNT(*) AS order_count
FROM customers
GROUP BY customer_unique_id
HAVING COUNT(*) > 1
ORDER BY order_count DESC;

-- Calculate Repeat Purchase Rate: % of unique customers who ordered more than once

WITH customer_order_counts AS (
    SELECT customer_unique_id, COUNT(*) AS order_count
    FROM customers
    GROUP BY customer_unique_id
)
SELECT
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (WHERE order_count > 1) AS repeat_customers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE order_count > 1) / COUNT(*), 2) AS repeat_customer_pct
FROM customer_order_counts;