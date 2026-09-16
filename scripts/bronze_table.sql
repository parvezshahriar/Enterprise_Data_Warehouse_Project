create table if not exists bronze.crm_cust_info(
 cst_id int,
 cst_key varchar(50),
 cst_firstname varchar(50),
 cst_lastname varchar(50),
 cst_material_status varchar(50),
 cst_gndr varchar(50),
 ingestion_timestamp timestamp default now(),
 file_source varchar(255)	
);

CREATE TABLE if not exists bronze.crm_prd_info(
 prd_id INT,
 prd_key VARCHAR(50),
 prd_nm VARCHAR(50),
 prd_cost INT,
 prd_line VARCHAR(50),
 prd_start_dt TIMESTAMPTZ,
 prd_end_dt TIMESTAMPTZ,
 ingestion_timestamp timestamp default now(),
 file_source varchar(255)
);

CREATE TABLE if not exists bronze.crm_sales_details(
 sls_ord_num VARCHAR(50),
 sls_prd_key VARCHAR(50),
 sls_cust_id INT,
 sls_order_dt INT,
 sls_ship_dt INT,
 sls_due_dt INT,
 sls_sales INT,
 sls_quantity INT,
 sls_price INT,
 ingestion_timestamp timestamp default now(),
 file_source varchar(255)
);

CREATE TABLE if not exists bronze.erp_loc_a101(
 cid VARCHAR(50),
 cntry varchar(50),
 ingestion_timestamp timestamp default now(),
 file_source varchar(255)
);

CREATE TABLE if not exists bronze.erp_cust_az12(
 cid VARCHAR(50),
 bdate DATE,
 gen VARCHAR(50),
 ingestion_timestamp timestamp default now(),
 file_source varchar(255)
);

CREATE TABLE if not exists bronze.erp_px_cat_g1v2(
 id VARCHAR(50),
 cat VARCHAR(50),
 subcat VARCHAR(50),
 maintainance VARCHAR(50),
 ingestion_timestamp timestamp default now(),
 file_source varchar(255)
);
