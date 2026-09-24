# Medallion Data Warehouse

A modern scalable data warehouse built on SQL Server using the Medallion Architecture.

## Architecture Layers
* **Bronze (`bronze_layer`):** Raw, unrefined source data landing zone.
* **Silver (`silver_layer`):** Cleansed, validated, and transformed operational models.
* **Gold (`gold_layer`):** Aggregated, business-ready models optimized for BI & reporting.
