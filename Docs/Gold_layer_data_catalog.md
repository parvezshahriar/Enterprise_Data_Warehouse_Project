# Gold Layer Data Catalog

## 1. Purpose

The **Gold Layer** represents the business-ready data model of the data warehouse.  
It transforms and organizes curated data from the lower layers into structures optimized for:

- Business intelligence and reporting
- Analytical queries
- KPI and metric calculation
- Customer and product analysis
- Sales performance analysis
- Dashboard and visualization workloads

The Gold Layer follows a **dimensional modeling approach**, consisting of:

- **Dimension tables** — descriptive business entities
- **Fact tables** — measurable business events and transactions

---

## 2. Gold Layer Data Model

The current Gold Layer contains three core tables:

| Table | Type | Business Domain | Description |
|---|---|---|---|
| `gold.dim_customers` | Dimension | Customer | Customer identity, demographic, and geographic attributes |
| `gold.dim_products` | Dimension | Product | Product master data and product classification |
| `gold.fact_sales` | Fact | Sales | Sales transactions and associated measures |

### Relationship Overview

```text
                    ┌─────────────────────┐
                    │   gold.dim_customers│
                    │─────────────────────│
                    │ PK customer_key     │
                    │ customer_id         │
                    │ customer_number     │
                    │ customer attributes │
                    └──────────┬──────────┘
                               │
                               │ customer_key
                               │
                               ▼
                    ┌─────────────────────┐
                    │    gold.fact_sales  │
                    │─────────────────────│
                    │ order_number        │
                    │ customer_key        │
                    │ product_key         │
                    │ order_date          │
                    │ shipping_date       │
                    │ due_date            │
                    │ sales_amount        │
                    │ quantity            │
                    │ price               │
                    └──────────┬──────────┘
                               │
                               │ product_key
                               │
                               ▼
                    ┌─────────────────────┐
                    │   gold.dim_products │
                    │─────────────────────│
                    │ PK product_key      │
                    │ product_id          │
                    │ product_number      │
                    │ product attributes  │
                    └─────────────────────┘
```

---

# 3. Dimension Tables

## 3.1 `gold.dim_customers`

### Business Purpose

`gold.dim_customers` is the **customer dimension**. It provides a consolidated, business-friendly view of customers by combining customer identifiers with demographic and geographic attributes.

This table is primarily used to:

- Identify customers
- Segment customers by demographic attributes
- Analyze sales by country
- Analyze customer behavior
- Join customer information to transactional sales data

### Table Classification

| Property | Value |
|---|---|
| Table Type | Dimension |
| Business Domain | Customer |
| Primary Key | `customer_key` |
| Business Identifier | `customer_id` / `customer_number` |
| Referenced By | `gold.fact_sales` |

### Column Dictionary

| Column | Data Type | Key | Description |
|---|---|---|---|
| `customer_key` | `INT` | PK | Surrogate key used to uniquely identify a customer record within the Gold Layer. |
| `customer_id` | `INT` | Business Key | Source-system identifier assigned to the customer. |
| `customer_number` | `NVARCHAR(50)` | Business Identifier | Alphanumeric customer reference used for business tracking and source-system identification. |
| `first_name` | `NVARCHAR(50)` | — | Customer's first name. |
| `last_name` | `NVARCHAR(50)` | — | Customer's last or family name. |
| `country` | `NVARCHAR(50)` | — | Customer's country of residence. |
| `marital_status` | `NVARCHAR(50)` | — | Customer's marital status, such as `Married` or `Single`. |
| `gender` | `NVARCHAR(50)` | — | Customer's recorded gender. |
| `birthdate` | `DATE` | — | Customer's date of birth. |
| `create_date` | `DATE` | — | Date on which the customer record was created in the source system. |

### Common Analytical Use Cases

- Customer segmentation
- Sales by customer
- Sales by country
- Customer demographic analysis
- Customer-level purchase analysis
- Customer profiling

---

## 3.2 `gold.dim_products`

### Business Purpose

`gold.dim_products` is the **product dimension**. It contains descriptive information used to identify, classify, and analyze products across the sales process.

The table provides a standardized product hierarchy, including:

- Product identification
- Product name
- Category
- Subcategory
- Product line
- Cost
- Maintenance requirements
- Product availability

### Table Classification

| Property | Value |
|---|---|
| Table Type | Dimension |
| Business Domain | Product |
| Primary Key | `product_key` |
| Business Identifier | `product_id` / `product_number` |
| Referenced By | `gold.fact_sales` |

### Column Dictionary

| Column | Data Type | Key | Description |
|---|---|---|---|
| `product_key` | `INT` | PK | Surrogate key uniquely identifying the product record in the Gold Layer. |
| `product_id` | `INT` | Business Key | Source-system identifier assigned to the product. |
| `product_number` | `NVARCHAR(50)` | Business Identifier | Alphanumeric product code used to identify and reference the product. |
| `product_name` | `NVARCHAR(50)` | — | Business-friendly name of the product. |
| `category_id` | `NVARCHAR(50)` | Reference | Identifier associated with the product's high-level category. |
| `category` | `NVARCHAR(50)` | — | High-level product classification, such as `Bikes` or `Components`. |
| `subcategory` | `NVARCHAR(50)` | — | More specific classification within the product category. |
| `maintenance_required` | `NVARCHAR(50)` | — | Indicates whether the product requires maintenance, such as `Yes` or `No`. |
| `cost` | `INT` | — | Base cost associated with the product. |
| `product_line` | `NVARCHAR(50)` | — | Product series or line, such as `Road` or `Mountain`. |
| `start_date` | `DATE` | — | Date on which the product became available for sale or use. |

### Product Hierarchy

```text
Product Category
      │
      └── Subcategory
              │
              └── Product Line
                      │
                      └── Product
```

### Common Analytical Use Cases

- Product performance analysis
- Sales by category
- Sales by subcategory
- Sales by product line
- Product profitability analysis
- Product portfolio analysis
- Maintenance-related product analysis

---

# 4. Fact Tables

## 4.1 `gold.fact_sales`

### Business Purpose

`gold.fact_sales` is the primary **sales fact table**. It stores transactional sales information at the sales line-item level and connects sales activity with the customer and product dimensions.

The table is designed to support analysis of:

- Revenue
- Units sold
- Product performance
- Customer purchasing behavior
- Order fulfillment timelines
- Sales trends over time

### Table Classification

| Property | Value |
|---|---|
| Table Type | Fact |
| Business Domain | Sales |
| Grain | One row per sales order line item |
| Foreign Keys | `customer_key`, `product_key` |
| Measures | `sales_amount`, `quantity`, `price` |

> **Grain:** Each row represents a single product line within a sales order.

### Column Dictionary

| Column | Data Type | Key / Role | Description |
|---|---|---|---|
| `order_number` | `NVARCHAR(50)` | Degenerate Dimension / Identifier | Unique sales order identifier associated with the transaction. |
| `product_key` | `INT` | FK | Surrogate key linking the transaction to `gold.dim_products`. |
| `customer_key` | `INT` | FK | Surrogate key linking the transaction to `gold.dim_customers`. |
| `order_date` | `DATE` | Date Attribute | Date on which the sales order was placed. |
| `shipping_date` | `DATE` | Date Attribute | Date on which the order was shipped. |
| `due_date` | `DATE` | Date Attribute | Date associated with the expected payment or order due date. |
| `sales_amount` | `INT` | Measure | Total sales value associated with the sales line item. |
| `quantity` | `INT` | Measure | Number of units of the product included in the sales line item. |
| `price` | `INT` | Measure | Unit selling price associated with the product. |

---

# 5. Fact Table Measures

The primary numerical measures in `gold.fact_sales` can be used to calculate business KPIs.

| Measure | Description | Example Calculation |
|---|---|---|
| `sales_amount` | Monetary value generated by a sales line item. | `SUM(sales_amount)` |
| `quantity` | Number of units sold. | `SUM(quantity)` |
| `price` | Selling price per unit. | `AVG(price)` or weighted calculations |

### Example Business Metrics

**Total Sales**

```sql
SELECT SUM(sales_amount) AS total_sales
FROM gold.fact_sales;
```

**Total Units Sold**

```sql
SELECT SUM(quantity) AS total_units_sold
FROM gold.fact_sales;
```

**Average Selling Price**

```sql
SELECT AVG(price) AS average_price
FROM gold.fact_sales;
```

---

# 6. Key Relationships

The Gold Layer uses surrogate keys to connect transactional data with descriptive dimensions.

| From Table | Column | Relationship | To Table | Column |
|---|---|---|---|---|
| `gold.fact_sales` | `customer_key` | Many-to-One | `gold.dim_customers` | `customer_key` |
| `gold.fact_sales` | `product_key` | Many-to-One | `gold.dim_products` | `product_key` |

### Relationship Model

```text
dim_customers
     │
     │ 1
     │
     │
     │ *
fact_sales
     │
     │ *
     │
     │ 1
dim_products
```

This structure follows a **star-schema pattern**, where the sales fact table sits at the center and connects to descriptive dimension tables.

---

# 7. Data Modeling Conventions

## 7.1 Surrogate Keys

The Gold Layer uses surrogate keys for dimension tables:

- `customer_key`
- `product_key`

These keys provide stable internal identifiers for joining facts with dimensions and separate warehouse relationships from source-system identifiers.

## 7.2 Business Keys

Business/source identifiers are retained alongside surrogate keys:

- `customer_id`
- `customer_number`
- `product_id`
- `product_number`
- `order_number`

This allows analytical users to trace records back to recognizable business identifiers.

## 7.3 Naming Convention

The model follows a consistent naming pattern:

```text
dim_<business_entity>
fact_<business_process>
```

Examples:

```text
gold.dim_customers
gold.dim_products
gold.fact_sales
```

---

# 8. Analytical Query Pattern

A typical Gold Layer analysis combines the sales fact table with customer and product dimensions.

```sql
SELECT
    c.country,
    p.category,
    p.subcategory,
    SUM(f.sales_amount) AS total_sales,
    SUM(f.quantity) AS total_quantity
FROM gold.fact_sales AS f
JOIN gold.dim_customers AS c
    ON f.customer_key = c.customer_key
JOIN gold.dim_products AS p
    ON f.product_key = p.product_key
GROUP BY
    c.country,
    p.category,
    p.subcategory
ORDER BY
    total_sales DESC;
```

This pattern enables analysis of sales performance across both **customer attributes** and **product attributes**.

---

# 9. Data Quality Expectations

The Gold Layer should maintain the following quality principles:

### Dimension Tables

- Surrogate keys should be unique.
- Business identifiers should be populated where available.
- Customer and product records should be standardized.
- Dates should use valid date values.
- Descriptive attributes should use consistent naming and values.

### Fact Table

- `customer_key` should resolve to a valid customer dimension record.
- `product_key` should resolve to a valid product dimension record.
- `quantity` should represent the number of units sold.
- Monetary fields should contain valid numeric values.
- Transaction dates should contain valid dates.
- The defined grain should remain consistent.

---

# 10. Gold Layer Summary

| Table | Role | Grain | Main Analytical Purpose |
|---|---|---|---|
| `gold.dim_customers` | Dimension | One row per customer record | Customer segmentation and demographic analysis |
| `gold.dim_products` | Dimension | One row per product record | Product classification and product analysis |
| `gold.fact_sales` | Fact | One row per sales order line | Sales, revenue, quantity, and transaction analysis |

## Overall Architecture

```text
                    GOLD LAYER
                         │
          ┌──────────────┴──────────────┐
          │                             │
     DIMENSIONS                      FACTS
          │                             │
   ┌──────┴──────┐                      │
   │             │                      │
Customers     Products              Sales
   │             │                      │
   │             └──────────┐           │
   │                        │           │
   └────────────────────────┴───────────┘
                    │
                    ▼
          Business Intelligence
                    │
          ┌─────────┴─────────┐
          │                   │
       Reports            Dashboards
          │                   │
          └─────────┬─────────┘
                    │
                    ▼
              Decision Making
```

---

## 11. Notes

- The Gold Layer is intended for **business consumption**, not raw-source ingestion.
- Dimension tables provide descriptive context for analytical queries.
- The fact table stores measurable business events.
- Surrogate keys are used for warehouse relationships.
- The fact table's declared grain should be preserved when loading or transforming data.
- Data types and business definitions should be validated against the implemented database schema before production documentation is finalized.
