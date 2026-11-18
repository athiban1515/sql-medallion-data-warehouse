/*
=============================================================================================================================================
DDL Script: Create Gold Layer Views
=============================================================================================================================================
Script Purpose:
    This script creates business-ready views in the 'gold_layer' schema.

    The Gold layer represents the final presentation layer of the data warehouse and follows a Star Schema design consisting of:

        - Dimension: dim_customers
        - Dimension: dim_products
        - Fact:      fact_sales

    The views combine and enrich data from the Silver layer to provide datasets that are easier to use for analytics, reporting, and BI.

    The Gold layer focuses on:
        - Business-friendly column names.
        - Combining related Silver-layer data.
        - Creating surrogate keys for dimensions.
        - Applying business rules.
        - Filtering historical product records.
        - Connecting fact data to dimension keys.

    Note:
        These are SQL views rather than physical tables. The data is generated when the views are queried.

Usage:
    These views can be queried directly for analytics and reporting.

Example:
    SELECT * FROM gold_layer.dim_customers;
    SELECT * FROM gold_layer.dim_products;
    SELECT * FROM gold_layer.fact_sales;
=============================================================================================================================================
*/

-- ==========================================================================================================================================
-- Create Dimension: gold_layer.dim_customers
-- ==========================================================================================================================================
-- Purpose:
--     Creates the customer dimension by combining CRM customer information
--     with ERP demographic and location information.
--
--     CRM is treated as the primary source for customer and gender information,
--     while ERP provides additional attributes such as birthdate and country.
-- ==========================================================================================================================================

IF OBJECT_ID('gold_layer.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold_layer.dim_customers;
GO

CREATE VIEW gold_layer.dim_customers AS
SELECT

    ROW_NUMBER() OVER (ORDER BY cust.cst_id) AS customer_key,  
  -- Generate a surrogate key for the customer dimension.(This key is used by the Gold-layer fact table instead of relying 
  -- directly on the source-system customer ID.) The source customer ID determines the ordering of the generated keys
    cust.cst_id                          AS customer_id,
    cust.cst_key                         AS customer_number,   -- Business/source-system customer identifiers
	
    cust.cst_firstname                   AS first_name,
    cust.cst_lastname                    AS last_name,         -- Customer descriptive attributes
	
    cust_loc.cntry                           AS country,       -- Customer location comes from the ERP location source.
	
    cust.cst_marital_status              AS marital_status, 
    CASE 
        WHEN cust.cst_gndr != 'n/a'                            -- CRM is the primary source for gender.
            THEN cust.cst_gndr                                 -- If CRM contains 'n/a', use the ERP gender value instead.

        ELSE COALESCE(cust_demo.gen, 'n/a')                    -- COALESCE provides 'n/a' if both sources do not contain a valid value.
    END                                AS gender,
	
    cust_demo.bdate                           AS birthdate,    -- Additional customer demographic information from ERP
    cust.cst_create_date                 AS create_date        -- Original customer creation date from CRM

FROM silver_layer.crm_cust_info AS cust
LEFT JOIN silver_layer.erp_cust_az12 AS cust_demo              -- LEFT JOIN keeps every CRM customer even if a matching ERP record does not exist
    ON cust.cst_key = cust_demo.cid
LEFT JOIN silver_layer.erp_loc_a101 AS cust_loc                -- LEFT JOIN ensures that missing location data does not remove the customer from the dimension.
    ON cust.cst_key = cust_loc.cid;
GO


-- ==========================================================================================================================================
-- Create Dimension: gold_layer.dim_products
-- ==========================================================================================================================================
-- Purpose:
--     Creates the product dimension by combining CRM product information
--     with ERP product category information.
--
--     Only the current version of each product is included.
--     Historical product versions are excluded using prd_end_dt.
-- ==========================================================================================================================================

IF OBJECT_ID('gold_layer.dim_products', 'V') IS NOT NULL
    DROP VIEW gold_layer.dim_products;
GO

CREATE VIEW gold_layer.dim_products AS
SELECT

    
    
    ROW_NUMBER() OVER (
        ORDER BY prod_info.prd_start_dt, prod_info.prd_key
    ) AS product_key,                           
  -- Generate a surrogate key for the product dimension. The ordering determines how the surrogate key values are assigned.

    prod_info.prd_id       AS product_id,
    prod_info.prd_key      AS product_number,          -- Product identifiers

    prod_info.prd_nm       AS product_name,            -- Product descriptive attributes

    prod_info.cat_id       AS category_id,             -- Category information
    prod_cat.cat          AS category,
    prod_cat.subcat       AS subcategory,
    prod_cat.maintenance  AS maintenance,

    prod_info.prd_cost     AS cost,                    -- Product business attributes
    prod_info.prd_line     AS product_line,
    prod_info.prd_start_dt AS start_date

FROM silver_layer.crm_prd_info AS prod_info
 
LEFT JOIN silver_layer.erp_px_cat_g1v2 AS prod_cat    -- Add category, subcategory, and maintenance information from the ERP product-category source.
    ON prod_info.cat_id = prod_cat.id
WHERE prod_info.prd_end_dt IS NULL;                   -- Keep only the current version of each product. Records with an end date represent historical product versions
GO


-- ==========================================================================================================================================
-- Create Fact: gold_layer.fact_sales
-- ==========================================================================================================================================
-- Purpose:
--     Creates the sales fact view by combining sales transaction data
--     from Silver with the customer and product dimension keys from Gold.
--
--     This creates the central fact table of the Star Schema.
--
--     Each row represents a sales transaction and contains:
--         - Dimension keys
--         - Dates
--         - Sales measures
-- ==========================================================================================================================================

IF OBJECT_ID('gold_layer.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold_layer.fact_sales;
GO

CREATE VIEW gold_layer.fact_sales AS
SELECT

    sales.sls_ord_num  AS order_number,       -- Sales transaction identifier
        
    prod_dim.product_key  AS product_key,        -- Replace the source product key with the Gold product surrogate key. This connects the fact table to dim_products. 

    cust_dim.customer_key AS customer_key,       -- Replace the source customer ID with the Gold customer surrogate key. This connects the fact table to dim_customers.

    sales.sls_order_dt AS order_date,         -- Sales transaction dates
    sales.sls_ship_dt  AS shipping_date,
    sales.sls_due_dt   AS due_date,

    sales.sls_sales    AS sales_amount,       -- Sales measures
    sales.sls_quantity AS quantity,
    sales.sls_price    AS price

FROM silver_layer.crm_sales_details AS sales

LEFT JOIN gold_layer.dim_products AS prod_dim        -- Connect each sales transaction to the product dimension.
    ON sales.sls_prd_key = prod_dim.product_number

LEFT JOIN gold_layer.dim_customers AS cust_dim       -- Connect each sales transaction to the customer dimension.
    ON sales.sls_cust_id = cust_dim.customer_id;
GO
