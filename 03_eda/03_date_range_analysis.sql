
/*
===============================================================================
   Explore Date Ranges
===============================================================================

   Purpose:
       - Understand the time period covered by the sales data.
       - Identify the oldest and youngest customers based on birthdate.
       - Understand the age range of the customers.

   Tables explored:
       - gold_layer.fact_sales
       - gold_layer.dim_customers

   SQL concepts used:
       - MIN()
       - MAX()
       - DATEDIFF()
       - GETDATE()
===============================================================================
*/

-- Find the first and last order dates and the total sales period in months
SELECT
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date,
    DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS order_range_months
FROM gold_layer.fact_sales;


-- Find the oldest and youngest customers based on birthdate
SELECT
    MIN(birthdate) AS oldest_birthdate,
    DATEDIFF(YEAR, MIN(birthdate), GETDATE()) AS oldest_age,
    MAX(birthdate) AS youngest_birthdate,
    DATEDIFF(YEAR, MAX(birthdate), GETDATE()) AS youngest_age
FROM gold_layer.dim_customers;

