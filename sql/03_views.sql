-- View 1: Products with English category names, NULL categories become 'Uncategorized'

CREATE OR REPLACE VIEW vw_products AS
SELECT
    p.product_id,
    COALESCE(t.product_category_name_english, 'Uncategorized') AS category,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM products p
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name;

-- Confirm that no products were dropped by the join (should match products table: 32,951)

SELECT COUNT(*) FROM vw_products;

-- Check that categories show up in English, largest categories first

SELECT category, COUNT(*) AS product_count
FROM vw_products
GROUP BY category
ORDER BY product_count DESC
LIMIT 10;

-- Confirm that the 610 NULL category products now show up as 'Uncategorized'

SELECT category, COUNT(*) AS product_count
FROM vw_products
WHERE category = 'Uncategorized'
GROUP BY category;

-- Look at delivered vs. estimated dates side by side

SELECT order_delivered_customer_date, order_estimated_delivery_date
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;

/* Delivered dates have real times but estimated dates are always 00:00:00.
Comparing full timestamps would mark same-day deliveries as late. Checking how many: */

-- Count orders delivered on the estimated date that a timestamp comparison would call late

SELECT COUNT(*)
FROM orders
WHERE order_delivered_customer_date > order_estimated_delivery_date
  AND order_delivered_customer_date::date = order_estimated_delivery_date::date;

/* 1292 orders would have been incorrectly counted as late. My decision: only compare dates, 
not times, so ::date */

-- View 2: one row per order, with real customer ID, location, and delivery performance

CREATE OR REPLACE VIEW vw_orders AS
SELECT
    o.order_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    o.order_delivered_customer_date::date - o.order_purchase_timestamp::date AS delivery_days,
    CASE
        WHEN o.order_delivered_customer_date IS NULL THEN NULL
        WHEN o.order_delivered_customer_date::date <= o.order_estimated_delivery_date::date THEN 'On time'
        ELSE 'Late'
    END AS delivery_status
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id;

-- Confirm that no orders were dropped by the join (should be 99,441)

SELECT COUNT(*) FROM vw_orders;

-- Check orders across delivery statuses

SELECT delivery_status, COUNT(*) AS order_count
FROM vw_orders
GROUP BY delivery_status;

-- Results: 6535 late orders, 89,941 orders on time, 2965 NULL 

-- On-time delivery rate among delivered orders 

SELECT ROUND(100.0 * COUNT(*) FILTER (WHERE delivery_status = 'On time')
       / COUNT(delivery_status), 2) AS on_time_rate
FROM vw_orders;

-- Results: on_time_rate = 93.23%