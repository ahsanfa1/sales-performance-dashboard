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