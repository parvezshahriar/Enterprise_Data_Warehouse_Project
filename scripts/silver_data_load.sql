CREATE OR REPLACE PROCEDURE silver.load_silver_all()
LANGUAGE plpgsql AS $$
DECLARE
    v_last_wm TIMESTAMP;
	v_new_wm TIMESTAMP;
BEGIN
    RAISE NOTICE 'Starting incremetal load for silver layer....';
	
	-- 1. Incremental Load: silver.crm_cust_info
	RAISE NOTICE 'loading silver.crm_cust_info....';
	SELECT last_loaded_timestamp INTO v_last_wm FROM comtrol.etl_watermark WHERE table_name='silver.crm_cust_info';
	v_last_wm :=COALESCE(v_last_wm, '1900-01-01'::TIMESTAMP);

	MERGE INTO silver.crm_cust_info target
	USING (
	   SELECT DISTINCT ON (cst_id)
       cst_id, cst_key, TRIM(cst_firstname) AS cst_firstname, TRIM(cst_lastname) AS cst_lastname,
            CASE WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'Single'
                 WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'Married'
                 ELSE 'n/a' END AS cst_material_status,
            CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                 WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                 ELSE 'n/a' END AS cst_gndr,
            cst_create_date
        FROM bronze.crm_cust_info
        WHERE ingestion_timestamp > v_last_wm
        ORDER BY cst_id, cst_create_date DESC
	) source
	ON target.cst_id=source.cst_id
	WHEN MATCHED THEN
	  UPDATE SET cst_key = source.cst_key, cst_firstname = source.cst_firstname, cst_lastname = source.cst_lastname,
                   cst_material_status = source.cst_material_status, cst_gndr = source.cst_gndr, dwh_create_date = v_new_wm
    WHEN NOT MATCHED THEN
        INSERT (cst_id, cst_key, cst_firstname, cst_lastname, cst_material_status, cst_gndr, cst_create_date, dwh_create_date)
        VALUES (source.cst_id, source.cst_key, source.cst_firstname, source.cst_lastname, source.cst_material_status, source.cst_gndr, source.cst_create_date, v_new_wm);
	
    INSERT INTO control.etl_watermark (table_name, last_loaded_timestamp) 
    VALUES ('silver.crm_cust_info', v_new_wm)
    ON CONFLICT (table_name) DO UPDATE SET last_loaded_timestamp = EXCLUDED.last_loaded_timestamp;	
	

    -- 2. Incremental Load: silver.crm_prd_info
	
    RAISE NOTICE 'Loading silver.crm_prd_info...';
    
    SELECT last_loaded_timestamp INTO v_last_wm FROM control.etl_watermark WHERE table_name = 'silver.crm_prd_info';
    v_last_wm := COALESCE(v_last_wm, '1900-01-01'::TIMESTAMP);

    MERGE INTO silver.crm_prd_info target
    USING (
        SELECT 
            prd_id,
            REPLACE(SUBSTRING(prd_key FROM 1 FOR 5), '-', '_') AS cat_id,
            SUBSTRING(prd_key FROM 7) AS prd_key,
            prd_nm,
            COALESCE(prd_cost, 0) AS prd_cost,
            CASE UPPER(TRIM(prd_line))
                 WHEN 'M' THEN 'Mountain' WHEN 'R' THEN 'Road' WHEN 'S' THEN 'Other Sales' WHEN 'T' THEN 'Touring' ELSE 'n/a' END AS prd_line,
            CAST(prd_start_dt AS DATE) AS prd_start_dt,
            CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - INTERVAL '1 day' AS DATE) AS prd_end_dt
        FROM bronze.crm_prd_info
        WHERE ingestion_timestamp > v_last_wm
    ) source
    ON target.prd_id = source.prd_id
    WHEN MATCHED THEN
        UPDATE SET prd_nm = source.prd_nm, prd_cost = source.prd_cost, prd_line = source.prd_line, prd_end_dt = source.prd_end_dt, dwh_create_date = v_new_wm
    WHEN NOT MATCHED THEN
        INSERT (prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt, dwh_create_date)
        VALUES (source.prd_id, source.cat_id, source.prd_key, source.prd_nm, source.prd_cost, source.prd_line, source.prd_start_dt, source.prd_end_dt, v_new_wm);

    INSERT INTO control.etl_watermark (table_name, last_loaded_timestamp) 
    VALUES ('silver.crm_prd_info', v_new_wm)
    ON CONFLICT (table_name) DO UPDATE SET last_loaded_timestamp = EXCLUDED.last_loaded_timestamp;


    -- 3. Incremental Load: silver.crm_sales_details
   
    RAISE NOTICE 'Loading silver.crm_sales_details...';
    
    SELECT last_loaded_timestamp INTO v_last_wm FROM control.etl_watermark WHERE table_name = 'silver.crm_sales_details';
    v_last_wm := COALESCE(v_last_wm, '1900-01-01'::TIMESTAMP);

    MERGE INTO silver.crm_sales_details target
    USING (
        SELECT 
            sls_ord_num, sls_prd_key, sls_cust_id,
            CASE WHEN sls_order_dt = 0 OR LENGTH(CAST(sls_order_dt AS VARCHAR)) != 8 THEN NULL ELSE TO_DATE(CAST(sls_order_dt AS VARCHAR), 'YYYYMMDD') END AS sls_order_dt,
            CASE WHEN sls_ship_dt = 0 OR LENGTH(CAST(sls_ship_dt AS VARCHAR)) != 8 THEN NULL ELSE TO_DATE(CAST(sls_ship_dt AS VARCHAR), 'YYYYMMDD') END AS sls_ship_dt,
            CASE WHEN sls_due_dt = 0 OR LENGTH(CAST(sls_due_dt AS VARCHAR)) != 8 THEN NULL ELSE TO_DATE(CAST(sls_due_dt AS VARCHAR), 'YYYYMMDD') END AS sls_due_dt,
            CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != (sls_quantity * ABS(sls_price)) THEN sls_quantity * ABS(sls_price) ELSE sls_sales END AS sls_sales,
            sls_quantity, sls_price
        FROM bronze.crm_sales_details
        WHERE ingestion_timestamp > v_last_wm
    ) source
    ON target.sls_ord_num = source.sls_ord_num AND target.sls_prd_key = source.sls_prd_key
    WHEN MATCHED THEN
        UPDATE SET sls_cust_id = source.sls_cust_id, sls_sales = source.sls_sales, sls_quantity = source.sls_quantity, sls_price = source.sls_price, dwh_create_date = v_new_wm
    WHEN NOT MATCHED THEN
        INSERT (sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt, sls_sales, sls_quantity, sls_price, dwh_create_date)
        VALUES (source.sls_ord_num, source.sls_prd_key, source.sls_cust_id, source.sls_order_dt, source.sls_ship_dt, source.sls_due_dt, source.sls_sales, source.sls_quantity, source.sls_price, v_new_wm);

    INSERT INTO control.etl_watermark (table_name, last_loaded_timestamp) 
    VALUES ('silver.crm_sales_details', v_new_wm)
    ON CONFLICT (table_name) DO UPDATE SET last_loaded_timestamp = EXCLUDED.last_loaded_timestamp;


    -- 4. Incremental Load: silver.erp_cust_az12

    RAISE NOTICE 'Loading silver.erp_cust_az12...';
    
    SELECT last_loaded_timestamp INTO v_last_wm FROM control.etl_watermark WHERE table_name = 'silver.erp_cust_az12';
    v_last_wm := COALESCE(v_last_wm, '1900-01-01'::TIMESTAMP);

    MERGE INTO silver.erp_cust_az12 target
    USING (
        SELECT DISTINCT
            CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid FROM 4) ELSE cid END AS cid,
            CASE WHEN bdate > NOW() THEN NULL ELSE bdate END AS bdate,
            CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female' WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male' ELSE 'n/a' END AS gen
        FROM bronze.erp_cust_az12
        WHERE ingestion_timestamp > v_last_wm
    ) source
    ON target.cid = source.cid
    WHEN MATCHED THEN
        -- FIXED: Added dwh_create_date
        UPDATE SET bdate = source.bdate, gen = source.gen, dwh_create_date = v_new_wm 
    WHEN NOT MATCHED THEN
        -- FIXED: Added dwh_create_date
        INSERT (cid, bdate, gen, dwh_create_date) VALUES (source.cid, source.bdate, source.gen, v_new_wm);

    INSERT INTO control.etl_watermark (table_name, last_loaded_timestamp) 
    VALUES ('silver.erp_cust_az12', v_new_wm)
    ON CONFLICT (table_name) DO UPDATE SET last_loaded_timestamp = EXCLUDED.last_loaded_timestamp;


    -- 5. Incremental Load: silver.erp_loc_a101

    RAISE NOTICE 'Loading silver.erp_loc_a101...';
    
    SELECT last_loaded_timestamp INTO v_last_wm FROM control.etl_watermark WHERE table_name = 'silver.erp_loc_a101';
    v_last_wm := COALESCE(v_last_wm, '1900-01-01'::TIMESTAMP);

    MERGE INTO silver.erp_loc_a101 target
    USING (
        SELECT 
            REPLACE(CAST(cid AS VARCHAR), '-', '') AS cid,
            CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany' WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States' WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a' ELSE TRIM(cntry) END AS cntry
        FROM bronze.erp_loc_a101
        WHERE ingestion_timestamp > v_last_wm
    ) source
    ON target.cid = source.cid
    WHEN MATCHED THEN
        UPDATE SET cntry = source.cntry, dwh_create_date = v_new_wm
    WHEN NOT MATCHED THEN
        INSERT (cid, cntry, dwh_create_date) VALUES (source.cid, source.cntry, v_new_wm);

    INSERT INTO control.etl_watermark (table_name, last_loaded_timestamp) 
    VALUES ('silver.erp_loc_a101', v_new_wm)
    ON CONFLICT (table_name) DO UPDATE SET last_loaded_timestamp = EXCLUDED.last_loaded_timestamp;


    -- 6. Incremental Load: silver.erp_px_cat_g1v2

    RAISE NOTICE 'Loading silver.erp_px_cat_g1v2...';
    
    SELECT last_loaded_timestamp INTO v_last_wm FROM control.etl_watermark WHERE table_name = 'silver.erp_px_cat_g1v2';
    v_last_wm := COALESCE(v_last_wm, '1900-01-01'::TIMESTAMP);

    MERGE INTO silver.erp_px_cat_g1v2 target
    USING (
        SELECT id, cat, subcat, maintainance
        FROM bronze.erp_px_cat_g1v2
        WHERE ingestion_timestamp > v_last_wm
    ) source
    ON target.id = source.id
    WHEN MATCHED THEN
        UPDATE SET cat = source.cat, subcat = source.subcat, maintainance = source.maintainance, dwh_create_date = v_new_wm
    WHEN NOT MATCHED THEN
        INSERT (id, cat, subcat, maintainance, dwh_create_date) VALUES (source.id, source.cat, source.subcat, source.maintainance, v_new_wm);

    INSERT INTO control.etl_watermark (table_name, last_loaded_timestamp) 
    VALUES ('silver.erp_px_cat_g1v2', v_new_wm)
    ON CONFLICT (table_name) DO UPDATE SET last_loaded_timestamp = EXCLUDED.last_loaded_timestamp;

    RAISE NOTICE 'Silver layer loaded successfully.';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '===================================================';
        RAISE NOTICE 'ERROR OCCURRED DURING INCREMENTAL SILVER LOAD';
        RAISE NOTICE 'Error Message: %', SQLERRM;
        RAISE NOTICE 'SQLSTATE: %', SQLSTATE;
        RAISE;
END;
$$;

