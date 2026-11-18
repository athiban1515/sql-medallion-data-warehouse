
/*
===============================================================================
   Explore Key Measures
===============================================================================

   Purpose:
       - Calculate overall sales and business metrics.
       - Understand the number of orders, products, and customers.
       - Compare total customers with customers who placed orders.
       - Create a summary of the main business metrics.

   Tables explored:
       - gold_layer.fact_sales
       - gold_layer.dim_products
       - gold_layer.dim_customers

   SQL concepts used:
       - SUM()
       - AVG()
       - COUNT()
       - COUNT(DISTINCT)
       - UNION ALL
===============================================================================
*/


-- Find the total sales amount
SELECT
    SUM(sales_amount) AS total_sales
FROM gold_layer.fact_sales;


-- Find the total quantity sold
SELECT
    SUM(quantity) AS total_quantity
FROM gold_layer.fact_sales;


-- Find the average selling price
SELECT
    AVG(price) AS avg_price
FROM gold_layer.fact_sales;


-- Count the total number of orders
SELECT
    COUNT(DISTINCT order_number) AS total_orders
FROM gold_layer.fact_sales;


-- Count the total number of products
SELECT
    COUNT(product_key) AS total_products
FROM gold_layer.dim_products;


-- Count the total number of customers
SELECT
    COUNT(customer_key) AS total_customers
FROM gold_layer.dim_customers;


-- Count the customers who have placed at least one order
SELECT
    COUNT(DISTINCT customer_key) AS customers_with_orders
FROM gold_layer.fact_sales;


-- Generate a summary of the main business metrics
SELECT
    'Total Sales' AS measure_name,
    SUM(sales_amount) AS measure_value
FROM gold_layer.fact_sales

UNION ALL

SELECT
    'Total Quantity',
    SUM(quantity)
FROM gold_layer.fact_sales

UNION ALL

SELECT
    'Average Price',
    AVG(CAST(price AS DECIMAL(18,2)))
FROM gold_layer.fact_sales

UNION ALL

SELECT
    'Total Orders',
    COUNT(DISTINCT order_number)
FROM gold_layer.fact_sales

UNION ALL

SELECT
    'Total Products',
    COUNT(product_key)
FROM gold_layer.dim_products

UNION ALL

SELECT
    'Total Customers',
    COUNT(customer_key)
FROM gold_layer.dim_customers;

