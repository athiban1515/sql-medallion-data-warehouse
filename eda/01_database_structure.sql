
/* =============================================================================== 
   Explore Database Structure
   ===============================================================================

   Purpose:
       - Check the tables available in the data warehouse.
       - Check the columns and basic metadata of the Gold layer tables.

   Tables explored:
       - dim_customers
       - dim_products
       - fact_sales

   Metadata views used:
       - INFORMATION_SCHEMA.TABLES
       - INFORMATION_SCHEMA.COLUMNS
   =============================================================================== */


-- Check the tables available in the database
SELECT 
    TABLE_CATALOG,
    TABLE_SCHEMA,
    TABLE_NAME,
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES;


-- Check columns and data types in dim_customers
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_customers';


-- Check columns and data types in dim_products
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_products';


-- Check columns and data types in fact_sales
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'fact_sales';

