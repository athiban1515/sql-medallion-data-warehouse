
# EDA Insights

This document contains the main observations and learnings from each exploratory analysis performed on the Gold layer.

---

## 01. Database Exploration

### What I explored

I first looked at the structure of the Gold layer to understand:

- What objects are available.
- What schema they belong to.
- What columns and data types they contain.
- How the dimension and fact views are related.

### What I found

- The Gold layer contains three views:
  - `dim_customers`
  - `dim_products`
  - `fact_sales`
- The customer dimension connects to the sales fact through `customer_key`.
- The product dimension connects to the sales fact through `product_key`.
- The metadata shows the columns as nullable, so NULL values should be considered during analysis.

### What I learned

Understanding the database structure and relationships is the first step before starting any analysis.

`INFORMATION_SCHEMA.TABLES` and `INFORMATION_SCHEMA.COLUMNS` provide a simple way to understand the database structure.

---

## 02. Dimension Exploration

### What I explored

I looked at the unique customer countries and the product hierarchy of category, subcategory, and product.

### What I found

- There are **6 unique countries**.
- There are **4 major product categories**.
- There are **36 subcategories**.
- There are **295 individual products**.
- Some customers do not have a country.
- 7 products do not have a category or subcategory.

### What I learned

Looking at unique values helps me understand the **cardinality and granularity** of each dimension.

Country, category, and other attributes can later be used to compare customers, sales, and product performance.

---

## 03. Date Range Exploration

### What I explored

I checked the available sales period and the age range of customers.

### What I found

- First order date: **2010-12-09**
- Last order date: **2014-01-28**
- The data covers approximately **3 years and 1 month**.
- The customer age range is approximately **40 to 110 years** based on the current calculation.

### What I learned

The available time period needs to be considered when interpreting trends and business performance.

The lack of younger customers is also something worth investigating to determine whether it is expected or represents a data limitation.

---

## 04. Key Measures

### What I explored

I calculated the main overall business metrics.

### What I found

| Metric | Value |
|---|---:|
| Total Sales | 29,356,250 |
| Total Quantity | 60,423 |
| Average Price | 486.04 |
| Total Orders | 27,659 |
| Total Products | 295 |
| Total Customers | 18,484 |

### What I learned

These metrics provide a quick overview of the **overall scale of the business data**.

They also provide baseline numbers that can be used when interpreting the more detailed analysis that follows.

---

## 05. Magnitude Analysis

### What I explored

I compared customers, products, revenue, and quantity across different dimensions such as country, gender, and product category.

### What I found

- The **USA** has the highest number of customers.
- Male and female customers are relatively balanced.
- **Components** has the highest number of products.
- **Bikes** have the highest average product cost.
- Bikes also generate the highest revenue among the categories.
- Revenue can be compared at an individual customer level to identify high-value customers.

### What I learned

Grouping metrics by different dimensions helps me understand **where the business is concentrated**.

For example, product count, product cost, and revenue provide different perspectives on product categories.

---

## 06. Ranking Analysis

### What I explored

I ranked products and customers based on revenue and order activity.

### What I found

The analysis identifies:

- Top-performing products by revenue.
- Lowest-revenue products.
- Top customers by revenue.
- Customers with the fewest orders.

### What I learned

Ranking is useful for focusing analysis on the most important or least-performing areas.

I also observed that `TOP` and ranking functions can produce different results:

- `TOP` directly limits the result to a specific number of rows.
- `RANK()` assigns a rank based on the ordering.
- Ties can cause a ranking query to return more rows than the requested rank.

This is important when deciding how to define "top N" or "bottom N" analysis.

---

# Overall Learnings

The first six EDA steps helped me move from understanding the **structure of the data** to understanding its **scale, characteristics, distribution, and rankings**.

The main observations so far are:

- The Gold layer provides three connected views for analysis.
- The data covers approximately 3 years of sales.
- There are 18,484 customers, 295 products, and 27,659 orders.
- Customer data is concentrated in a small number of countries.
- Product categories differ significantly in size, cost, and revenue.
- Bikes are currently the strongest category by revenue and average cost.
- Some missing country and product category information needs to be considered.
- Customer age data shows a noticeable lack of younger customers.
- Ranking helps identify high and low performing products and customers.

These findings provide a starting point for the next stage of analysis, where I can investigate **trends, customer behavior, product performance, and relationships between different metrics**.

