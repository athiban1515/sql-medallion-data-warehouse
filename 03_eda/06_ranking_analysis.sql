
/*
===============================================================================
   Ranking Analysis
===============================================================================

   Purpose:
       - Rank products and customers based on sales performance.
       - Identify the highest- and lowest-performing products.
       - Identify customers with the highest revenue and fewest orders.

   Tables explored:
       - gold_layer.fact_sales
       - gold_layer.dim_products
       - gold_layer.dim_customers

   SQL concepts used:
       - TOP
       - RANK()
       - OVER()
       - SUM()
       - COUNT()
       - COUNT(DISTINCT)
       - GROUP BY
       - ORDER BY
       - LEFT JOIN
===============================================================================
*/


-- Find the top 5 products by total revenue
SELECT TOP 5
    prod.product_name,
    SUM(sales.sales_amount) AS total_revenue
FROM gold_layer.fact_sales AS sales
LEFT JOIN gold_layer.dim_products AS prod
ON prod.product_key = sales.product_key
GROUP BY prod.product_name
ORDER BY total_revenue DESC;


-- Rank products by total revenue using RANK()
SELECT *
FROM (
    SELECT
        prod.product_name,
        SUM(sales.sales_amount) AS total_revenue,
        RANK() OVER (
            ORDER BY SUM(sales.sales_amount) DESC
        ) AS product_rank
    FROM gold_layer.fact_sales AS sales
    LEFT JOIN gold_layer.dim_products AS prod
    ON prod.product_key = sales.product_key
    GROUP BY prod.product_name
) AS ranked_products
WHERE product_rank <= 5
ORDER BY product_rank;


-- Find the 5 products with the lowest total revenue
SELECT TOP 5
    prod.product_name,
    SUM(sales.sales_amount) AS total_revenue
FROM gold_layer.fact_sales AS sales
LEFT JOIN gold_layer.dim_products AS prod
ON prod.product_key = sales.product_key
GROUP BY prod.product_name
ORDER BY total_revenue;


-- Find the top 10 customers by total revenue
SELECT TOP 10
    cust.customer_key,
    cust.first_name,
    cust.last_name,
    SUM(sales.sales_amount) AS total_revenue
FROM gold_layer.fact_sales AS sales
LEFT JOIN gold_layer.dim_customers AS cust
ON cust.customer_key = sales.customer_key
GROUP BY
    cust.customer_key,
    cust.first_name,
    cust.last_name
ORDER BY total_revenue DESC;


-- Find the 3 customers with the fewest orders
SELECT TOP 3
    cust.customer_key,
    cust.first_name,
    cust.last_name,
    COUNT(DISTINCT sales.order_number) AS total_orders
FROM gold_layer.fact_sales AS sales
LEFT JOIN gold_layer.dim_customers AS cust
ON cust.customer_key = sales.customer_key
GROUP BY
    cust.customer_key,
    cust.first_name,
    cust.last_name
ORDER BY total_orders;

