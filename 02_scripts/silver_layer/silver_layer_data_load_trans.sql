/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.

    The Silver layer is responsible for:
        - Cleaning and standardizing raw Bronze data.
        - Handling invalid or missing values.
        - Removing duplicate customer records.
        - Applying basic business rules and data transformations.
        - Preparing data for the Gold layer.

Actions Performed:
        - Truncates Silver tables before loading.
        - Reads data from Bronze tables.
        - Cleanses and transforms the source data.
        - Inserts the transformed data into Silver tables.
        - Tracks individual table load duration.
        - Tracks total batch load duration.

Parameters:
    None.
    This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC silver_layer.load_silver;
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver_layer.load_silver AS
BEGIN
    DECLARE @start_time DATETIME, 
            @end_time DATETIME, 
            @batch_start_time DATETIME, 
            @batch_end_time DATETIME; 

    BEGIN TRY

        -- Capture the start time of the complete Silver-layer load
        SET @batch_start_time = GETDATE();

        PRINT '================================================';
        PRINT 'Loading Silver Layer';
        PRINT '================================================';

        PRINT '------------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '------------------------------------------------';


        -- ============================================================
        -- Loading silver_layer.crm_cust_info
        -- ============================================================

        SET @start_time = GETDATE();

        -- Silver tables use a full-refresh loading strategy.
        -- Existing data is removed before loading the latest Bronze data.
        PRINT '>> Truncating Table: silver_layer.crm_cust_info';
        TRUNCATE TABLE silver_layer.crm_cust_info;

        PRINT '>> Inserting Data Into: silver_layer.crm_cust_info';

        INSERT INTO silver_layer.crm_cust_info (
            cst_id, 
            cst_key, 
            cst_firstname, 
            cst_lastname, 
            cst_marital_status, 
            cst_gndr,
            cst_create_date
        )
        SELECT
            cst_id,
            cst_key,

            -- Remove leading and trailing spaces from customer names
            TRIM(cst_firstname) AS cst_firstname,
            TRIM(cst_lastname) AS cst_lastname,

            -- Standardize marital-status codes into readable values
            CASE 
                WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
                WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
                ELSE 'n/a'
            END AS cst_marital_status,

            -- Standardize gender codes into readable values
            CASE 
                WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                ELSE 'n/a'
            END AS cst_gndr,

            cst_create_date

        FROM (
            SELECT
                *,

                -- Assign a row number to each customer based on the
                -- customer ID. The newest record receives row number 1.
                ROW_NUMBER() OVER (
                    PARTITION BY cst_id 
                    ORDER BY cst_create_date DESC
                ) AS flag_last

            FROM bronze_layer.crm_cust_info

            -- Customer ID is required to identify a customer.
            -- Records without an ID are excluded.
            WHERE cst_id IS NOT NULL

        ) t

        -- Keep only the most recent record for each customer.
        -- This removes duplicate customer records from the Silver layer.
        WHERE flag_last = 1;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: ' 
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) 
            + ' seconds';

        PRINT '>> -------------';


        -- ============================================================
        -- Loading silver_layer.crm_prd_info
        -- ============================================================

        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver_layer.crm_prd_info';
        TRUNCATE TABLE silver_layer.crm_prd_info;

        PRINT '>> Inserting Data Into: silver_layer.crm_prd_info';

        INSERT INTO silver_layer.crm_prd_info (
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        SELECT
            prd_id,

            -- Extract the category ID from the original product key.
            -- Example: 'AC-HE-HL-U509-R' -> 'AC_HE'
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,

            -- Extract the product key portion from the original key.
            -- Example: 'AC-HE-HL-U509-R' -> 'HL-U509-R'
            SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,

            prd_nm,

            -- Replace missing product cost with 0.
            ISNULL(prd_cost, 0) AS prd_cost,

            -- Convert product-line codes into readable business values.
            CASE 
                WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
                WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
                WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
                WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
                ELSE 'n/a'
            END AS prd_line,

            -- Convert datetime values to DATE because only the date
            -- component is required in the Silver layer.
            CAST(prd_start_dt AS DATE) AS prd_start_dt,

            -- The next start date represents the beginning of the next
            -- version of the same product.
            --
            -- Therefore, subtract one day from the next start date
            -- to determine the current record's end date.
            CAST(
                LEAD(prd_start_dt) OVER (
                    PARTITION BY prd_key 
                    ORDER BY prd_start_dt
                ) - 1 
                AS DATE
            ) AS prd_end_dt

        FROM bronze_layer.crm_prd_info;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: ' 
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) 
            + ' seconds';

        PRINT '>> -------------';


        -- ============================================================
        -- Loading silver_layer.crm_sales_details
        -- ============================================================

        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver_layer.crm_sales_details';
        TRUNCATE TABLE silver_layer.crm_sales_details;

        PRINT '>> Inserting Data Into: silver_layer.crm_sales_details';

        INSERT INTO silver_layer.crm_sales_details (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price
        )
        SELECT 
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,

            -- Convert YYYYMMDD integer/string values into DATE.
            -- Invalid or zero dates are converted to NULL.
            CASE 
                WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 
                    THEN NULL
                ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
            END AS sls_order_dt,

            CASE 
                WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 
                    THEN NULL
                ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
            END AS sls_ship_dt,

            CASE 
                WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 
                    THEN NULL
                ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
            END AS sls_due_dt,

            -- Validate the sales amount.
            --
            -- If sales is missing, zero/negative, or does not match:
            --     quantity * price
            -- then recalculate it using quantity * absolute price.
            CASE 
                WHEN sls_sales IS NULL 
                  OR sls_sales <= 0 
                  OR sls_sales != sls_quantity * ABS(sls_price) 
                    THEN sls_quantity * ABS(sls_price)
                ELSE sls_sales
            END AS sls_sales,

            sls_quantity,

            -- Validate the price.
            --
            -- If price is missing or invalid, derive it from:
            --     sales / quantity
            --
            -- NULLIF prevents division by zero when quantity = 0.
            CASE 
                WHEN sls_price IS NULL OR sls_price <= 0 
                    THEN sls_sales / NULLIF(sls_quantity, 0)
                ELSE sls_price
            END AS sls_price

        FROM bronze_layer.crm_sales_details;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: ' 
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) 
            + ' seconds';

        PRINT '>> -------------';


        -- ============================================================
        -- Loading silver_layer.erp_cust_az12
        -- ============================================================

        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver_layer.erp_cust_az12';
        TRUNCATE TABLE silver_layer.erp_cust_az12;

        PRINT '>> Inserting Data Into: silver_layer.erp_cust_az12';

        INSERT INTO silver_layer.erp_cust_az12 (
            cid,
            bdate,
            gen
        )
        SELECT

            -- Remove the 'NAS' prefix when it exists so that the
            -- customer ID can be standardized with other source systems.
            CASE
                WHEN cid LIKE 'NAS%' 
                    THEN SUBSTRING(cid, 4, LEN(cid))
                ELSE cid
            END AS cid, 

            -- Birthdates cannot logically be in the future.
            -- Invalid future dates are replaced with NULL.
            CASE
                WHEN bdate > GETDATE() 
                    THEN NULL
                ELSE bdate
            END AS bdate,

            -- Standardize different representations of gender.
            CASE
                WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') 
                    THEN 'Female'
                WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') 
                    THEN 'Male'
                ELSE 'n/a'
            END AS gen

        FROM bronze_layer.erp_cust_az12;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: ' 
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) 
            + ' seconds';

        PRINT '>> -------------';


        PRINT '------------------------------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '------------------------------------------------';


        -- ============================================================
        -- Loading silver_layer.erp_loc_a101
        -- ============================================================

        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver_layer.erp_loc_a101';
        TRUNCATE TABLE silver_layer.erp_loc_a101;

        PRINT '>> Inserting Data Into: silver_layer.erp_loc_a101';

        INSERT INTO silver_layer.erp_loc_a101 (
            cid,
            cntry
        )
        SELECT

            -- Remove '-' characters from customer IDs to standardize
            -- the identifier format.
            REPLACE(cid, '-', '') AS cid, 

            -- Standardize country codes and handle missing values.
            CASE
                WHEN TRIM(cntry) = 'DE' 
                    THEN 'Germany'

                WHEN TRIM(cntry) IN ('US', 'USA') 
                    THEN 'United States'

                WHEN TRIM(cntry) = '' OR cntry IS NULL 
                    THEN 'n/a'

                ELSE TRIM(cntry)
            END AS cntry

        FROM bronze_layer.erp_loc_a101;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: ' 
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) 
            + ' seconds';

        PRINT '>> -------------';


        -- ============================================================
        -- Loading silver_layer.erp_px_cat_g1v2
        -- ============================================================

        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver_layer.erp_px_cat_g1v2';
        TRUNCATE TABLE silver_layer.erp_px_cat_g1v2;

        PRINT '>> Inserting Data Into: silver_layer.erp_px_cat_g1v2';

        INSERT INTO silver_layer.erp_px_cat_g1v2 (
            id,
            cat,
            subcat,
            maintenance
        )
        SELECT
            id,
            cat,
            subcat,
            maintenance

        -- No transformation is currently required for this table.
        -- The Bronze data is already in a suitable structure for Silver.
        FROM bronze_layer.erp_px_cat_g1v2;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: ' 
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) 
            + ' seconds';

        PRINT '>> -------------';


        -- ============================================================
        -- Silver Layer Load Completed
        -- ============================================================

        -- Capture the end time of the complete Silver-layer batch.
        SET @batch_end_time = GETDATE();

        PRINT '==========================================';
        PRINT 'Loading Silver Layer is Completed';
        PRINT '   - Total Load Duration: ' 
            + CAST(
                DATEDIFF(
                    SECOND, 
                    @batch_start_time, 
                    @batch_end_time
                ) AS NVARCHAR
              ) 
            + ' seconds';
        PRINT '==========================================';

    END TRY

    BEGIN CATCH

        -- ============================================================
        -- Error Handling
        -- ============================================================

        PRINT '==========================================';
        PRINT 'ERROR OCCURRED DURING LOADING SILVER LAYER';

        -- Display details about the error that occurred.
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR);

        PRINT '==========================================';

    END CATCH
END
