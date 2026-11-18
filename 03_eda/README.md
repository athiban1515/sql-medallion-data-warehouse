
# Exploratory Data Analysis

This section contains the exploratory analysis performed on the **Gold layer** of the Data Warehouse.

The goal is to understand the structure, scale, characteristics, and patterns in the data before performing deeper analysis.

## Data Used

The analysis is performed on the following Gold layer views:

- `gold_layer.dim_customers`
- `gold_layer.dim_products`
- `gold_layer.fact_sales`

## EDA Approach

The analysis is performed step by step, starting with a basic understanding of the data and gradually moving toward more detailed analysis.

| # | Analysis | Purpose |
|---|---|---|
| 01 | Database Exploration | Understand the database structure, tables, columns, and relationships |
| 02 | Dimension Exploration | Understand customer and product attributes and their unique values |
| 03 | Date Range Exploration | Understand the time period and customer age range |
| 04 | Key Measures | Calculate overall business metrics |
| 05 | Magnitude Analysis | Understand how data is distributed across different dimensions |
| 06 | Ranking Analysis | Identify top and bottom performing products and customers |

## Analysis Flow

```text
Database Structure
        ↓
Dimensions
        ↓
Date Ranges
        ↓
Key Measures
        ↓
Magnitude Analysis
        ↓
Ranking Analysis
        ↓
Deeper Analysis & Business Insights
````

## SQL Concepts Used

The EDA currently uses:

* `INFORMATION_SCHEMA.TABLES`
* `INFORMATION_SCHEMA.COLUMNS`
* `DISTINCT`
* `MIN()`
* `MAX()`
* `DATEDIFF()`
* `COUNT()`
* `COUNT(DISTINCT)`
* `SUM()`
* `AVG()`
* `GROUP BY`
* `ORDER BY`
* `TOP`
* `RANK()`
* `LEFT JOIN`
* `UNION ALL`

## Purpose of the EDA

The main objective is not only to calculate numbers, but to understand what the data is telling us and identify areas that may require further investigation.

The observations from each analysis are documented in [`insights.md`](insights.md).

