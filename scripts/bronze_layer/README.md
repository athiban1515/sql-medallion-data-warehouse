# Bronze Layer

The Bronze layer is the **raw data ingestion layer** of the data warehouse.

It is responsible for loading data from the source CRM and ERP CSV files into SQL Server with minimal transformation. The data is kept close to its original source structure so that it can be used as the foundation for downstream processing in the Silver layer.

---

## 1. Purpose

The Bronze layer is designed to:

* Load raw source data into the data warehouse.
* Preserve the structure of the source data.
* Separate data ingestion from data transformation.
* Provide a consistent starting point for the Silver layer.

---

## 2. Source Systems

The current project uses data from two source systems:

### CRM

The CRM source contains:

* Customer information
* Product information
* Sales transactions

### ERP

The ERP source contains:

* Customer location information
* Customer demographic information
* Product category information

---

## 3. Bronze Tables

The following tables have been created under the `bronze_layer` schema.

| Source | Table               | Description                                  |
| ------ | ------------------- | -------------------------------------------- |
| CRM    | `crm_cust_info`     | Customer information                         |
| CRM    | `crm_prd_info`      | Product information                          |
| CRM    | `crm_sales_details` | Sales transaction information                |
| ERP    | `erp_loc_a101`      | Customer location/country information        |
| ERP    | `erp_cust_az12`     | Customer demographic information             |
| ERP    | `erp_px_cat_g1v2`   | Product category and subcategory information |

The Bronze tables are designed to closely reflect the structure of the source CSV files.

---

## 4. Data Flow

```text
CRM / ERP CSV Files
        |
        v
   BULK INSERT
        |
        v
Bronze Layer Tables
```

The Bronze layer currently uses local CSV files as the source.

---

## 5. Data Loading

The Bronze layer is loaded using the stored procedure:

```sql
bronze_layer.load_bronze
```

To execute the load:

```sql
EXEC bronze_layer.load_bronze;
```

The procedure processes each Bronze table individually.

### Loading Process

For each table, the procedure:

1. Records the start time.
2. Truncates the existing table.
3. Loads the CSV file using `BULK INSERT`.
4. Skips the CSV header row.
5. Records the end time.
6. Calculates the table load duration.

After all tables are loaded, the procedure also records the total batch duration.

---

## 6. Loading Strategy

The current Bronze loading process uses a **full-refresh approach**.

```text
Existing Bronze Data
        |
        v
TRUNCATE TABLE
        |
        v
BULK INSERT
        |
        v
Fresh Bronze Data
```

This means that every execution removes the existing Bronze data and reloads it from the current source CSV files.

This approach is being used at the current stage of the project to keep the ingestion process simple and reproducible.

---

## 7. Error Handling

The Bronze loading procedure uses `TRY...CATCH` to handle errors during the loading process.

When an error occurs, the procedure captures information such as:

* Error message
* Error number
* Error state

This provides basic visibility into failures during the ingestion process.

---

## 8. Load Monitoring

Basic execution-time monitoring has been added to the loading procedure.

The procedure records:

* Individual table load duration
* Total Bronze-layer load duration

The following SQL Server functions are used:

```sql
GETDATE()
DATEDIFF()
```

This provides a simple way to observe how long the ingestion process takes.

---

## 9. SQL Concepts Used

This layer demonstrates the following SQL Server concepts:

* Database and schema creation
* Table creation
* Stored procedures
* `CREATE OR ALTER PROCEDURE`
* `BULK INSERT`
* `TRUNCATE TABLE`
* `TRY...CATCH`
* `GETDATE()`
* `DATEDIFF()`
* Variables
* `IF EXISTS`
* `sys.databases`

---

## 10. Important Design Decisions

### Minimal Transformation

No significant data cleansing or business transformation is performed in the Bronze layer.

The objective is to keep the source data as close as possible to its original structure.

Data cleansing, standardization, and business rules will be implemented in the Silver layer.

### Full Refresh

The current implementation uses `TRUNCATE TABLE` followed by `BULK INSERT`.

This makes the Bronze load a full refresh rather than an incremental load.

### Local File Paths

The current `BULK INSERT` statements use local Windows file paths.

When running the project on another machine, these paths need to be updated to match the location of the source CSV files.

---

## 11. Outcome

The Bronze layer provides a raw, source-aligned representation of the CRM and ERP data inside SQL Server.

It establishes the foundation for the next stage of the pipeline:

```text
Source CSV Files
       ↓
Bronze Layer
       ↓
Silver Layer
```

The Silver layer will use this data for cleansing, standardization, and transformation.
