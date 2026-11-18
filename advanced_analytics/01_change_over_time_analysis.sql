
/*
===============================================================================
   Change Over Time Analysis
===============================================================================

   Purpose:
       - Track trends, growth, and changes in key metrics over time.
       - Prepare monthly data for time-series and seasonality analysis.
       - Identify periods of growth or decline.

   Table explored:
       - gold_layer.fact_sales

   SQL concepts used:
       - YEAR()
       - MONTH()
       - DATETRUNC()
       - FORMAT()
       - SUM()
       - COUNT(DISTINCT)
       - GROUP BY
       - ORDER BY
===============================================================================
*/


-- Analyse monthly sales performance using YEAR() and MONTH()
SELECT
    YEAR(order_date) AS order_year,
    MONTH(order_date) AS order_month,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM gold_layer.fact_sales
WHERE order_date IS NOT NULL
GROUP BY
    YEAR(order_date),
    MONTH(order_date)
ORDER BY
    YEAR(order_date),
    MONTH(order_date);


-- Analyse monthly sales performance using DATETRUNC()
SELECT
    DATETRUNC(MONTH, order_date) AS order_month,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM gold_layer.fact_sales
WHERE order_date IS NOT NULL
GROUP BY
    DATETRUNC(MONTH, order_date)
ORDER BY
    DATETRUNC(MONTH, order_date);


-- Analyse monthly sales performance using FORMAT()
SELECT
    FORMAT(order_date, 'yyyy-MMM') AS order_month,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM gold_layer.fact_sales
WHERE order_date IS NOT NULL
GROUP BY
    FORMAT(order_date, 'yyyy-MMM')
ORDER BY
    FORMAT(order_date, 'yyyy-MMM');
