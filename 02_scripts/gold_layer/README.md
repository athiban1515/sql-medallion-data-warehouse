# Gold Layer

The Gold layer is the **business-ready presentation layer** of the data warehouse.

It takes the cleansed and standardized data from the Silver layer and organizes it into a **Star Schema** consisting of customer and product dimensions and a sales fact.

The Gold layer is designed for analytics, reporting, and BI use cases.

---

## 1. Purpose

The Gold layer is designed to:

* Provide business-ready datasets.
* Organize data using a Star Schema.
* Create customer and product dimensions.
* Create a sales fact.
* Combine related data from different Silver tables.
* Generate surrogate keys for dimensions.
* Apply final business rules and filtering.
* Provide simplified column names for reporting and analytics.

---

## 2. Source Layer

The Gold layer reads data from the `silver_layer` schema.

```text
Silver Layer
     |
     | Combine
     | Enrich
     | Apply Business Rules
     | Create Dimensions & Fact
     v
Gold Layer
     |
     v
Analytics / Reporting / BI
```

The Gold layer currently uses the following Silver data:

### CRM

* Customer information
* Product information
* Sales transactions

### ERP

* Customer demographic information
* Customer location information
* Product category information

---

## 3. Gold Views

The Gold layer currently contains three views.

| Type      | View                       | Purpose                           |
| --------- | -------------------------- | --------------------------------- |
| Dimension | `gold_layer.dim_customers` | Business-ready customer dimension |
| Dimension | `gold_layer.dim_products`  | Business-ready product dimension  |
| Fact      | `gold_layer.fact_sales`    | Sales transaction fact            |

These views form the current Star Schema.

```text
                 dim_customers
                      |
                      |
                      v
                 fact_sales
                      ^
                      |
                      |
                 dim_products
```

---

## 4. Customer Dimension

### `gold_layer.dim_customers`

The customer dimension combines customer information from CRM with additional customer information from ERP.

### Source Tables

```text
silver_layer.crm_cust_info
          +
silver_layer.erp_cust_az12
          +
silver_layer.erp_loc_a101
          |
          v
gold_layer.dim_customers
```

### Transformations

The customer dimension:

* Creates a surrogate `customer_key`.
* Provides business-friendly column names.
* Combines customer demographic information from ERP.
* Adds customer country from ERP.
* Uses CRM gender as the primary source.
* Uses ERP gender as a fallback when CRM gender is `n/a`.

### Gender Business Rule

```text
CRM Gender
    |
    | Valid value?
    |
   Yes -----------------> Use CRM Gender
    |
    No
    |
    v
ERP Gender
    |
    | No valid value?
    |
    v
   n/a
```

The customer dimension also retains the original customer ID and customer number for reference.

---

## 5. Product Dimension

### `gold_layer.dim_products`

The product dimension combines CRM product information with ERP product category information.

### Source Tables

```text
silver_layer.crm_prd_info
          +
silver_layer.erp_px_cat_g1v2
          |
          v
gold_layer.dim_products
```

### Transformations

The product dimension:

* Creates a surrogate `product_key`.
* Provides business-friendly column names.
* Adds category information.
* Adds subcategory information.
* Adds maintenance information.
* Includes product cost and product line.
* Includes the product start date.

### Current Product Filtering

The Gold layer keeps only the current version of each product.

```sql
WHERE prd_end_dt IS NULL
```

Product records with an end date represent historical versions and are therefore excluded from the current product dimension.

---

## 6. Sales Fact

### `gold_layer.fact_sales`

The sales fact is the central dataset of the Gold-layer Star Schema.

It combines Silver sales transactions with the Gold customer and product dimensions.

### Source Tables

```text
silver_layer.crm_sales_details
             |
             +------------------+
             |                  |
             v                  v
    dim_products        dim_customers
             |                  |
             +--------+---------+
                      |
                      v
                fact_sales
```

### Transformations

The sales fact:

* Retains the sales order number.
* Replaces the source product identifier with the Gold `product_key`.
* Replaces the source customer identifier with the Gold `customer_key`.
* Includes order, shipping, and due dates.
* Includes sales amount.
* Includes quantity.
* Includes price.

This creates the relationships between sales transactions and their corresponding dimensions.

---

## 7. Loading Strategy

Unlike the Bronze and Silver layers, the current Gold layer is implemented using **views rather than physical tables**.

The views are created using:

```sql
CREATE VIEW
```

The existing views are dropped and recreated when the DDL script is executed.

```text
Silver Tables
      |
      v
Gold Views
      |
      v
BI / Reporting / Analytics
```

The data is generated when the views are queried.

---

## 08. SQL Concepts Used

This layer demonstrates the following SQL Server concepts:

* `CREATE VIEW`
* `DROP VIEW`
* `IF OBJECT_ID()`
* `SELECT`
* `LEFT JOIN`
* `CASE`
* `COALESCE`
* `ROW_NUMBER()`
* `OVER`
* `ORDER BY`
* `WHERE`
* Column aliases
* Star Schema design
* Surrogate keys
* Dimension tables
* Fact tables

---

## 09. Key Design Decisions

### Star Schema

The Gold layer follows a Star Schema consisting of:

```text
dim_customers
       |
       |
       v
   fact_sales
       ^
       |
       |
dim_products
```

This structure is designed to make analytical queries and reporting easier.

### Views Instead of Physical Tables

The current Gold layer uses SQL views rather than storing another physical copy of the data.

The views retrieve and combine data from the Silver layer when queried.

### Surrogate Keys

Customer and product dimensions use generated surrogate keys.

These keys are used by the fact table to establish relationships with the dimensions.

### Current Products Only

Historical product versions are excluded from `dim_products` using:

```sql
WHERE prd_end_dt IS NULL
```

---

## 10. Outcome

The Gold layer provides a **business-ready Star Schema** built from the cleansed Silver data.

The current warehouse flow is:

```text
Source CSV Files
       ↓
Bronze Layer
       ↓
Raw Data Ingestion
       ↓
Silver Layer
       ↓
Clean / Standardize / Validate
       ↓
Gold Layer
       ↓
Dimensions + Fact
       ↓
Analytics / Reporting / BI
```

The current Gold layer provides:

* `dim_customers`
* `dim_products`
* `fact_sales`

These views form the foundation for downstream analytics and reporting.
