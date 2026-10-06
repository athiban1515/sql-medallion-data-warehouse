# Silver Layer

The Silver layer is the **cleansed and transformed data layer** of the data warehouse.

It takes raw data from the Bronze layer, applies data cleansing, standardization, validation, and basic business rules, and stores the prepared data for downstream use in the Gold layer.

---

## 1. Purpose

The Silver layer is designed to:

* Clean and standardize raw Bronze data.
* Handle missing and invalid values.
* Remove duplicate customer records.
* Convert source-specific codes into readable values.
* Standardize identifiers across source systems.
* Apply basic data validation and business rules.
* Prepare consistent data for the Gold layer.

---

## 2. Source Layer

The Silver layer reads data from the `bronze_layer` schema.

```text
Bronze Layer
     |
     |  Cleanse
     |  Standardize
     |  Validate
     |  Transform
     v
Silver Layer
     |
     v
Gold Layer
```

The current implementation uses data from two source systems:

### CRM

* Customer information
* Product information
* Sales transactions

### ERP

* Customer demographic information
* Customer location information
* Product category information

---

## 3. Silver Tables

The following tables have been created under the `silver_layer` schema.

| Source | Silver Table        | Purpose                                       |
| ------ | ------------------- | --------------------------------------------- |
| CRM    | `crm_cust_info`     | Cleansed customer information                 |
| CRM    | `crm_prd_info`      | Cleansed and standardized product information |
| CRM    | `crm_sales_details` | Cleansed sales transaction information        |
| ERP    | `erp_cust_az12`     | Cleansed customer demographic information     |
| ERP    | `erp_loc_a101`      | Standardized customer location information    |
| ERP    | `erp_px_cat_g1v2`   | Product category and maintenance information  |

Each table also contains:

```sql
dwh_create_date DATETIME2 DEFAULT GETDATE()
```

This records when the record was loaded into the data warehouse.

---

## 4. Data Loading

The Silver layer is loaded using the stored procedure:

```sql
silver_layer.load_silver
```

To execute the load:

```sql
EXEC silver_layer.load_silver;
```

The procedure uses a **full-refresh approach**.

For each Silver table:

```text
TRUNCATE TABLE
       |
       v
Read Bronze Data
       |
       v
Clean / Transform
       |
       v
INSERT INTO Silver
```

The procedure also records the load duration for each table and the total Silver-layer load.

---

## 5. CRM Customer Transformation

### `crm_cust_info`

The customer data is cleansed and standardized before being loaded into Silver.

### Transformations

* Leading and trailing spaces are removed from first and last names.
* Marital-status codes are converted into readable values.
* Gender codes are converted into readable values.
* Records without a customer ID are excluded.
* Duplicate customer records are handled using `ROW_NUMBER()`.

### Duplicate Handling

Customers are partitioned by `cst_id` and ordered by `cst_create_date` in descending order.

```sql
ROW_NUMBER() OVER (
    PARTITION BY cst_id
    ORDER BY cst_create_date DESC
)
```

Only:

```sql
WHERE flag_last = 1
```

is retained.

This keeps the **most recent record for each customer**.

---

## 6. CRM Product Transformation

### `crm_prd_info`

Product data is transformed to make product and category information easier to use downstream.

### Transformations

* Category ID is extracted from the original product key.
* Product key is separated from the original composite key.
* Missing product cost is replaced with `0`.
* Product-line codes are converted into descriptive values.
* Product start dates are converted to the `DATE` data type.
* Product end dates are derived using `LEAD()`.

### Product Line Standardization

| Code  | Silver Value |
| ----- | ------------ |
| `M`   | Mountain     |
| `R`   | Road         |
| `S`   | Other Sales  |
| `T`   | Touring      |
| Other | `n/a`        |

### Product End Date

`LEAD()` is used to identify the next start date for the same product.

The end date is then calculated as:

```text
Next Product Start Date - 1 Day
```

This creates a valid date range for each product version.

---

## 7. CRM Sales Transformation

### `crm_sales_details`

The sales data is validated and converted into a consistent structure.

### Date Transformation

Source dates are stored in `YYYYMMDD` format.

They are converted into SQL Server `DATE` values.

Invalid values such as:

```text
0
Incorrect date length
```

are converted to `NULL`.

The following dates are processed:

* Order date
* Ship date
* Due date

### Sales Validation

The sales amount is validated against:

```text
Quantity × Price
```

If the original sales value is:

* `NULL`
* Less than or equal to `0`
* Inconsistent with quantity × price

the sales amount is recalculated.

### Price Validation

If the source price is missing or invalid, it is derived using:

```text
Sales ÷ Quantity
```

`NULLIF()` is used to prevent division-by-zero errors.

---

## 8. ERP Customer Transformation

### `erp_cust_az12`

Customer demographic data is standardized before loading into Silver.

### Transformations

* The `NAS` prefix is removed from customer IDs where present.
* Future birthdates are replaced with `NULL`.
* Gender values are standardized.

### Gender Standardization

| Source Value   | Silver Value |
| -------------- | ------------ |
| `F` / `FEMALE` | Female       |
| `M` / `MALE`   | Male         |
| Other          | `n/a`        |

This creates a consistent representation of gender values.

---

## 9. ERP Location Transformation

### `erp_loc_a101`

Customer location data is standardized.

### Transformations

* Hyphens are removed from customer IDs.
* Country codes are converted into readable country names.
* Blank and missing country values are converted to `n/a`.

### Country Standardization

| Source Value | Silver Value         |
| ------------ | -------------------- |
| `DE`         | Germany              |
| `US` / `USA` | United States        |
| Blank / NULL | `n/a`                |
| Other        | Trimmed source value |

---

## 10. ERP Product Category Transformation

### `erp_px_cat_g1v2`

Currently, no transformation is required for this table.

The data is loaded directly from Bronze into Silver because the source structure is already suitable for the current Silver-layer requirements.

```text
Bronze
  |
  v
ERP Product Category
  |
  v
Silver
```

Future transformations can be added if data-quality or business requirements are identified.

---

## 11. Data Quality & Standardization

The Silver layer currently performs the following data-quality operations:

* Remove leading and trailing spaces.
* Standardize categorical values.
* Replace missing values where appropriate.
* Convert invalid dates to `NULL`.
* Remove duplicate customer records.
* Validate sales and price values.
* Standardize customer identifiers.
* Standardize country values.
* Convert source data types into appropriate SQL Server types.

The goal is to create **consistent and reliable data while keeping the data at a detailed, non-aggregated level**.

---

## 12. Loading Strategy

The current Silver loading process uses a **full-refresh approach**.

```text
Existing Silver Data
        |
        v
TRUNCATE TABLE
        |
        v
Read Bronze Data
        |
        v
Transform & Clean
        |
        v
Fresh Silver Data
```

This approach keeps the current ETL process simple and reproducible.

---

## 13. Load Monitoring

The Silver loading procedure tracks:

* Individual table load duration.
* Total Silver-layer load duration.

The following SQL Server functions are used:

```sql
GETDATE()
DATEDIFF()
```

This provides basic monitoring of ETL execution time.

---

## 14. Error Handling

The loading procedure uses:

```sql
TRY...CATCH
```

to handle errors during the Silver-layer loading process.

When an error occurs, the procedure reports:

* Error message
* Error number
* Error state

This provides basic visibility into ETL failures.

---

## 15. SQL Concepts Used

This layer demonstrates the following SQL Server concepts:

* `CREATE TABLE`
* `CREATE OR ALTER PROCEDURE`
* `TRUNCATE TABLE`
* `INSERT INTO ... SELECT`
* `CASE`
* `TRIM`
* `UPPER`
* `ISNULL`
* `REPLACE`
* `SUBSTRING`
* `LEN`
* `ROW_NUMBER()`
* `LEAD()`
* `PARTITION BY`
* `ORDER BY`
* `CAST`
* `ABS`
* `NULLIF`
* `TRY...CATCH`
* `GETDATE()`
* `DATEDIFF()`
* Variables

---

## 16. Key Design Decisions

### Clean Before Business Reporting

The Silver layer focuses on cleansing, standardization, validation, and detailed-level transformations.

Business-level aggregations and reporting models will be handled in the Gold layer.

### Full Refresh

The current implementation uses:

```sql
TRUNCATE TABLE
```

followed by a fresh load from Bronze.

### Source Preservation

The Silver layer retains the detailed source-level records while improving their quality and consistency.

### No Aggregation

The current Silver layer does not perform business aggregations such as:

* Total sales by customer
* Total sales by product
* Sales by country
* Monthly revenue

These types of business-ready transformations belong in the Gold layer.

---

## 17. Outcome

The Silver layer converts the raw Bronze data into a **cleaned, standardized, and validated dataset**.

The current pipeline is:

```text
CRM / ERP Source Files
          ↓
     Bronze Layer
          ↓
  Clean / Standardize
          ↓
     Silver Layer
          ↓
      Gold Layer
```

The Silver layer now provides the prepared foundation for building business-ready Gold-layer models.
