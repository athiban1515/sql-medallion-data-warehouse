
/*
===============================================================================
   Explore Dimensions
===============================================================================

   Purpose:
       - Explore the main attributes available in the customer dimension.
       - Explore the product categories and product hierarchy.
       - Understand the unique values available for further analysis.

   Tables explored:
       - gold_layer.dim_customers
       - gold_layer.dim_products

   SQL concepts used:
       - DISTINCT
       - ORDER BY
===============================================================================
*/


-- Explore the unique countries where customers are located
SELECT DISTINCT
    country
FROM gold_layer.dim_customers
ORDER BY country;


-- Explore the product hierarchy: category, subcategory, and product
SELECT DISTINCT
    category,
    subcategory,
    product_name
FROM gold_layer.dim_products
ORDER BY category, subcategory, product_name;

