# Data Warehouse Naming Conventions

## 1. Purpose

This document defines the standard naming conventions for objects within the data warehouse.

The objective is to ensure that database objects are:

- Consistent across all data warehouse layers
- Easy to understand and discover
- Business-friendly where appropriate
- Technically predictable
- Easy to maintain and scale
- Consistent across development, testing, and production environments

These standards apply to schemas, tables, views, columns, keys, technical metadata, stored procedures, and other commonly used database objects.

---

# 2. Naming Standards at a Glance

| Object | Standard | Example |
|---|---|---|
| Schema | `<layer>` | `bronze`, `silver`, `gold` |
| Bronze Table | `<source>_<entity>` | `crm_cust_info` |
| Silver Table | `<source>_<entity>` | `crm_cust_info` |
| Gold Dimension | `dim_<entity>` | `dim_customers` |
| Gold Fact | `fact_<business_process>` | `fact_sales` |
| Gold Report | `report_<subject>` | `report_sales_monthly` |
| Surrogate Key | `<entity>_key` | `customer_key` |
| Business Key | `<entity>_id` / `<entity>_number` | `customer_id` |
| Technical Column | `dwh_<attribute>` | `dwh_load_date` |
| Stored Procedure | `load_<layer>` | `load_bronze` |
| View | `<purpose>_<subject>` | `report_sales_monthly` |

---

# 3. General Naming Principles

All data warehouse objects should follow the principles below.

## 3.1 Use `snake_case`

Use lowercase letters with underscores separating individual words.

**Preferred:**

```text
customer_id
product_number
order_date
sales_amount
load_bronze
```

**Avoid:**

```text
CustomerID
customerId
CUSTOMER_ID
Customer_Id
```

---

## 3.2 Use English

All database object names should use clear and consistent English terminology.

**Preferred:**

```text
customer
product
sales
order_date
```

**Avoid:**

```text
grahak
pdt
verkauf
```

---

## 3.3 Use Meaningful Names

Names should clearly communicate the business or technical purpose of the object.

**Preferred:**

```text
customer_key
shipping_date
sales_amount
```

**Avoid:**

```text
key1
date1
value
data
```

---

## 3.4 Avoid Unnecessary Abbreviations

Use abbreviations only when they are widely understood and consistently used throughout the warehouse.

**Preferred:**

```text
customer_number
product_number
```

**Avoid:**

```text
cust_num
prod_no
```

Source-system abbreviations may be preserved in the Bronze and Silver layers when required to maintain source traceability.

---

## 3.5 Avoid SQL Reserved Words

Database object names should not use SQL reserved words.

For example, avoid names such as:

```text
user
order
group
select
date
```

Use more descriptive alternatives where necessary:

```text
customer_order
order_date
customer_group
```

---

## 3.6 Avoid Special Characters

Object names should contain only:

- Lowercase letters (`a-z`)
- Numbers (`0-9`) where appropriate
- Underscores (`_`)

Avoid:

```text
customer-name
customer.name
customer/name
customer@data
```

Use:

```text
customer_name
```

---

## 3.7 Maintain Consistency

The same business concept should use the same name throughout the warehouse.

For example, if the warehouse uses:

```text
customer_key
```

for the customer surrogate key, do not use:

```text
cust_key
customer_sk
customer_surrogate_id
```

for the same concept in another table.

---

# 4. Schema Naming Conventions

Schemas represent the major layers of the data warehouse.

| Schema | Purpose |
|---|---|
| `bronze` | Raw or source-aligned data |
| `silver` | Cleaned, standardized, and transformed data |
| `gold` | Business-ready analytical data |

### Standard

```text
<layer>
```

### Examples

```text
bronze
silver
gold
```

Schema names should remain short, lowercase, and consistent across environments.

---

# 5. Table Naming Conventions

Table names depend on the data warehouse layer because each layer has a different responsibility.

---

## 5.1 Bronze Layer

### Purpose

The Bronze Layer stores data as close as possible to its original source representation.

The primary objective is **source-system traceability**.

### Naming Pattern

```text
<sourcesystem>_<entity>
```

Where:

- `<sourcesystem>` identifies the originating system.
- `<entity>` represents the original source table or entity name.

### Examples

```text
crm_cust_info
crm_prd_info
crm_sales_details

erp_cust_az12
erp_loc_a101
erp_px_cat_g1v2
```

### Rules

1. Preserve the source-system prefix.
2. Preserve the original source table naming where practical.
3. Do not rename source attributes merely for business readability.
4. Avoid introducing business-specific naming into the Bronze layer.
5. Keep source traceability as the primary concern.

### Example

If the source system contains:

```text
CRM.cust_info
```

the Bronze table should be:

```text
bronze.crm_cust_info
```

---

# 6. Silver Layer

## Purpose

The Silver Layer contains cleaned, standardized, validated, and integrated data.

Although the data is transformed, source traceability should still be maintained where appropriate.

### Naming Pattern

```text
<sourcesystem>_<entity>
```

### Examples

```text
crm_cust_info
crm_prd_info
crm_sales_details

erp_cust_az12
erp_loc_a101
```

### Rules

1. Retain the source-system prefix.
2. Maintain the source entity name where practical.
3. Standardize data types and values within the table.
4. Apply consistent column naming standards.
5. Preserve source traceability.
6. Do not introduce `dim_` or `fact_` prefixes at the Silver layer unless there is a specific architectural reason.

### Example

```text
silver.crm_cust_info
silver.crm_prd_info
silver.crm_sales_details
```

---

# 7. Gold Layer

## Purpose

The Gold Layer represents the **business-facing analytical model**.

Unlike Bronze and Silver, Gold objects should use names based on business concepts rather than source-system terminology.

The Gold Layer primarily follows a dimensional modeling approach.

### Naming Pattern

```text
<category>_<business_entity>
```

Where `<category>` identifies the role of the object.

### Examples

```text
dim_customers
dim_products
fact_sales
```

---

## 7.1 Dimension Tables

### Naming Pattern

```text
dim_<entity>
```

### Examples

```text
dim_customers
dim_products
dim_date
dim_location
```

### Rules

- Use `dim_` as the prefix.
- Use plural nouns for entity names.
- Use clear business terminology.
- Avoid source-system abbreviations.
- Keep names consistent with the business domain.

### Example

```text
gold.dim_customers
gold.dim_products
```

---

## 7.2 Fact Tables

### Naming Pattern

```text
fact_<business_process>
```

### Examples

```text
fact_sales
fact_orders
fact_payments
fact_inventory
```

Fact names should describe the **business process or measurable event** represented by the table.

### Example

```text
gold.fact_sales
```

represents sales transactions and their associated measures.

---

## 7.3 Reporting / Semantic Tables

Tables specifically designed to support reporting may use:

```text
report_<subject>
```

### Examples

```text
report_sales_monthly
report_customer_sales
report_product_performance
```

Use this prefix only for objects that are intentionally designed for reporting or presentation purposes.

---

# 8. Table Category Prefixes

The following prefixes are standardized for Gold Layer objects.

| Prefix | Object Type | Purpose | Example |
|---|---|---|---|
| `dim_` | Dimension | Descriptive business attributes | `dim_customers` |
| `fact_` | Fact | Business events and measurements | `fact_sales` |
| `report_` | Reporting | Reporting-specific dataset | `report_sales_monthly` |

### General Pattern

```text
<category>_<business_entity>
```

---

# 9. Column Naming Conventions

Columns should follow the same general naming principles as tables.

### Standard Pattern

```text
<business_attribute>
```

Examples:

```text
customer_id
first_name
last_name
birthdate
order_date
sales_amount
quantity
```

---

## 9.1 Primary Keys

Primary keys should clearly identify the record represented by the table.

For dimension surrogate keys, use:

```text
<entity>_key
```

Examples:

```text
customer_key
product_key
date_key
```

---

# 10. Surrogate Key Standards

Surrogate keys are warehouse-generated identifiers used primarily for dimension tables.

### Naming Pattern

```text
<entity>_key
```

### Examples

```text
customer_key
product_key
```

### Rules

1. Use the `_key` suffix.
2. Use the singular business entity name.
3. Do not use `_id` for surrogate keys.
4. Surrogate keys should be system-generated rather than copied from the source system.

### Example

```text
gold.dim_customers

customer_key
```

The `customer_key` uniquely identifies the customer record within the Gold dimension.

---

# 11. Business Key Standards

Business keys originate from the source system or represent identifiers recognized by the business.

Common naming patterns include:

```text
<entity>_id
<entity>_number
<entity>_code
```

### Examples

```text
customer_id
customer_number
product_id
product_number
category_id
```

### Distinction

| Key Type | Example | Purpose |
|---|---|---|
| Surrogate Key | `customer_key` | Warehouse-generated identifier |
| Business Key | `customer_id` | Source/business identifier |
| Business Identifier | `customer_number` | Human/business-facing identifier |

This distinction should be maintained consistently throughout the warehouse.

---

# 12. Foreign Key Standards

Foreign keys referencing dimension tables should use the same name as the corresponding dimension's surrogate key.

### Pattern

```text
<entity>_key
```

### Example

The customer dimension contains:

```text
customer_key
```

Therefore, the sales fact should reference it using:

```text
customer_key
```

Similarly:

```text
dim_products.product_key
        ↓
fact_sales.product_key
```

### Example

```text
gold.fact_sales

customer_key
product_key
```

---

# 13. Date Column Standards

Date-related columns should clearly describe the business event associated with the date.

### Preferred Pattern

```text
<event>_date
```

### Examples

```text
order_date
shipping_date
due_date
birthdate
start_date
create_date
```

Avoid generic names such as:

```text
date1
date_value
dt
date_field
```

---

# 14. Measure / Metric Naming

Measures should clearly communicate what is being measured.

### Common Patterns

| Pattern | Example | Meaning |
|---|---|---|
| `<entity>_amount` | `sales_amount` | Monetary value |
| `<entity>_cost` | `product_cost` | Cost |
| `<entity>_price` | `unit_price` | Price |
| `<entity>_quantity` | `sales_quantity` | Number of units |
| `<entity>_count` | `customer_count` | Number of records/entities |

### Examples

```text
sales_amount
quantity
price
cost
```

Avoid ambiguous names:

```text
value
amount1
num
metric
```

---

# 15. Technical Columns

Technical columns contain system-generated metadata rather than business information.

All technical columns should begin with:

```text
dwh_
```

### Naming Pattern

```text
dwh_<attribute>
```

### Examples

```text
dwh_load_date
dwh_load_timestamp
dwh_source
dwh_batch_id
dwh_created_at
dwh_updated_at
```

### Common Technical Columns

| Column | Purpose |
|---|---|
| `dwh_load_date` | Date on which the record was loaded into the warehouse |
| `dwh_load_timestamp` | Timestamp of the warehouse load |
| `dwh_source` | Source system associated with the record |
| `dwh_batch_id` | Identifier of the load batch |
| `dwh_created_at` | Timestamp when the warehouse record was created |
| `dwh_updated_at` | Timestamp when the warehouse record was last updated |

### Rules

- Always use the `dwh_` prefix.
- Use technical metadata only for system-level information.
- Do not use `dwh_` for business attributes.
- Keep technical column names consistent across layers.

---

# 16. View Naming Conventions

Views should follow the purpose of the data they expose.

### Standard Pattern

```text
<category>_<subject>
```

For reporting-oriented views:

```text
report_<subject>
```

### Examples

```text
report_sales_monthly
report_customer_sales
report_product_performance
```

For analytical views that are not specifically reporting datasets, a descriptive business name may be used according to the project's architecture.

---

# 17. Stored Procedure Naming Conventions

Stored procedures responsible for loading warehouse layers should follow a consistent naming pattern.

### Standard Pattern

```text
load_<layer>
```

### Examples

```text
load_bronze
load_silver
load_gold
```

### Purpose

| Procedure | Responsibility |
|---|---|
| `load_bronze` | Load source data into the Bronze Layer |
| `load_silver` | Transform and load data into the Silver Layer |
| `load_gold` | Build or refresh business-ready Gold Layer objects |

---

## 17.1 Procedure Naming for Specific Processes

When multiple procedures are required within a layer, use:

```text
load_<layer>_<process>
```

### Examples

```text
load_bronze_crm
load_bronze_erp
load_silver_customers
load_silver_products
load_gold_sales
```

This approach allows the warehouse to scale without creating ambiguous procedure names.

---

# 18. Naming Patterns by Layer

The complete naming strategy can be summarized as follows:

```text
                    DATA WAREHOUSE
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
      BRONZE            SILVER             GOLD
        │                 │                 │
        ▼                 ▼                 ▼
 <source>_<entity>  <source>_<entity>  <category>_<entity>
        │                 │                 │
        │                 │          ┌──────┼──────┐
        │                 │          │      │      │
        │                 │        dim_   fact_  report_
        │                 │          │      │      │
        ▼                 ▼          ▼      ▼      ▼
 crm_cust_info       crm_cust_info  dim_  fact_  report_
```

---

# 19. Complete Example

A typical customer and sales data flow may follow these conventions:

### Bronze

```text
bronze.crm_cust_info
bronze.crm_prd_info
bronze.crm_sales_details
```

### Silver

```text
silver.crm_cust_info
silver.crm_prd_info
silver.crm_sales_details
```

### Gold

```text
gold.dim_customers
gold.dim_products
gold.fact_sales
```

### Gold Relationships

```text
gold.dim_customers
        │
        │ customer_key
        ▼
gold.fact_sales
        ▲
        │ product_key
        │
gold.dim_products
```

---

# 20. Naming Decision Rules

When creating a new object, apply the following decision process:

### Step 1 — Identify the Layer

```text
Bronze → Source-oriented
Silver → Standardized/source-aligned
Gold   → Business-oriented
```

### Step 2 — Identify the Object Type

```text
Dimension → dim_
Fact      → fact_
Report    → report_
```

### Step 3 — Identify the Business Entity

Use a clear and meaningful business term.

```text
customer
product
sales
```

### Step 4 — Apply the Standard Pattern

```text
dim_customers
fact_sales
report_sales_monthly
```

### Step 5 — Validate the Name

Before creating the object, confirm that it:

- Uses lowercase `snake_case`
- Uses English
- Is meaningful and unambiguous
- Does not contain unnecessary abbreviations
- Does not use reserved SQL keywords
- Follows the appropriate layer convention
- Is consistent with existing warehouse terminology

---

# 21. Quick Reference

| Object | Naming Pattern | Example |
|---|---|---|
| Schema | `<layer>` | `gold` |
| Bronze table | `<source>_<entity>` | `crm_cust_info` |
| Silver table | `<source>_<entity>` | `crm_cust_info` |
| Dimension | `dim_<entity>` | `dim_customers` |
| Fact | `fact_<process>` | `fact_sales` |
| Report | `report_<subject>` | `report_sales_monthly` |
| Surrogate key | `<entity>_key` | `customer_key` |
| Business key | `<entity>_id` | `customer_id` |
| Business number | `<entity>_number` | `customer_number` |
| Technical column | `dwh_<attribute>` | `dwh_load_date` |
| Load procedure | `load_<layer>` | `load_gold` |
| Specific load procedure | `load_<layer>_<process>` | `load_gold_sales` |

---

# 22. Standard to Follow

The following rules should be treated as the baseline naming standard for the data warehouse:

```text
1. Use lowercase snake_case.
2. Use English terminology.
3. Avoid SQL reserved words.
4. Avoid unnecessary abbreviations.
5. Preserve source naming in Bronze and Silver.
6. Use business-oriented naming in Gold.
7. Prefix Gold dimensions with dim_.
8. Prefix Gold facts with fact_.
9. Prefix reporting objects with report_.
10. Use <entity>_key for surrogate keys.
11. Use <entity>_id / <entity>_number for business identifiers.
12. Use dwh_ for technical metadata columns.
13. Use load_<layer> for layer-level loading procedures.
14. Use load_<layer>_<process> for process-specific loading procedures.
15. Keep terminology consistent across the entire warehouse.
```

> **Principle:** Names should be predictable, meaningful, and consistent enough that a developer or analyst can understand the purpose of an object without inspecting its implementation.
"""

from pathlib import Path
path = Path("/mnt/data/data_warehouse_naming_conventions.md")
path.write_text(md, encoding="utf-8")
print(path)
