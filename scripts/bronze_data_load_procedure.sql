CREATE OR REPLACE PROCEDURE bronze.load_single_table_incremental(
    p_dir TEXT,
    p_file_pattern TEXT,
    p_target_table TEXT,
    p_columns TEXT,
    p_source_system TEXT
)
LANGUAGE plpgsql AS $$
DECLARE
    f_rec RECORD;
    v_full_path TEXT;
    v_sql TEXT;
BEGIN
    -- Loop through all files matching the pattern in the given directory
    FOR f_rec IN 
        SELECT file_name FROM pg_ls_dir(p_dir) AS file_name 
        WHERE file_name LIKE p_file_pattern
    LOOP
        -- Check if file has already been successfully processed
        IF NOT EXISTS (
            SELECT 1
            FROM control.file_processing_log
            WHERE source_system = p_source_system
              AND table_name = p_target_table
              AND file_name = f_rec.file_name
              AND status = 'SUCCESS'
        ) THEN

            RAISE NOTICE
                'Loading new % file: % into %',
                p_source_system,
                f_rec.file_name,
                p_target_table;

            v_full_path := p_dir || '/' || f_rec.file_name;

            -- Safety check: drop temp table if it already exists from a previously failed transaction
            DROP TABLE IF EXISTS temp_load_table;

            -- 1. Create a dynamic temp table based on the target table's structure
            EXECUTE format('CREATE TEMP TABLE temp_load_table (LIKE %s EXCLUDING DEFAULTS) ON COMMIT DROP', p_target_table);

            -- 2. Dynamically COPY data from the CSV into the temp table
            v_sql := format('COPY temp_load_table(%s) FROM %L WITH (FORMAT CSV, HEADER TRUE, DELIMITER '','')', p_columns, v_full_path);
            EXECUTE v_sql;

            -- 3. Insert into the target table, appending the metadata (file source and current timestamp)
            v_sql := format('INSERT INTO %s (%s, file_source, ingestion_timestamp) SELECT %s, %L, NOW() FROM temp_load_table', 
                            p_target_table, p_columns, p_columns, f_rec.file_name);
            EXECUTE v_sql;

            -- 4. Log the successful run in the control table (Updated to include status)
            INSERT INTO control.file_processing_log (source_system, table_name, file_name, status)
            VALUES (p_source_system, p_target_table, f_rec.file_name, 'SUCCESS');
            
            -- 5. Drop the temp table to ensure a clean slate for the next file in the loop
            DROP TABLE temp_load_table;

        END IF; -- This is the ONLY "END IF" you need
    END LOOP;
END;
$$;

CREATE OR REPLACE PROCEDURE bronze.load_bronze_incremental_all()
LANGUAGE plpgsql AS $$
DECLARE
    v_crm_dir TEXT :='C:/datasets/source_crm';
    v_erp_dir TEXT :='C:/datasets/source_erp';

BEGIN   ------ Fixed typo here (was BEIGIN)
  RAISE NOTICE 'Starting incremental load...';

  CALL bronze.load_single_table_incremental(
        v_crm_dir, 'cust_info%.csv', 'bronze.crm_cust_info', 
        'cst_id, cst_key, cst_firstname, cst_lastname, cst_material_status, cst_gndr, cst_create_date', 'CRM'
    );
    
  CALL bronze.load_single_table_incremental(
        v_crm_dir, 'prd_info%.csv', 'bronze.crm_prd_info', 
        'prd_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt', 'CRM'
    );
    
  CALL bronze.load_single_table_incremental(
        v_crm_dir, 'sales_details%.csv', 'bronze.crm_sales_details', 
        'sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt, sls_sales, sls_quantity, sls_price', 'CRM'
    );
    -- Load ERP Tables
  CALL bronze.load_single_table_incremental(
        v_erp_dir, 'CUST_AZ12%.csv', 'bronze.erp_cust_az12', 
        'cid, bdate, gen', 'ERP'
    );
    
  CALL bronze.load_single_table_incremental(
        v_erp_dir, 'LOC_A101%.csv', 'bronze.erp_loc_a101', 
        'cid, cntry', 'ERP'
    );
    
  CALL bronze.load_single_table_incremental(
        v_erp_dir, 'PX_CAT_G1V2%.csv', 'bronze.erp_px_cat_g1v2', 
        'id, cat, subcat, maintainance', 'ERP'
    );
  RAISE NOTICE 'All bronze incremental csv files loaded successfully';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '===================================================';
        RAISE NOTICE 'ERROR OCCURRED DURING INCREMENTAL BRONZE LOAD';
        RAISE NOTICE 'Error Message: %', SQLERRM;
        RAISE NOTICE 'SQLSTATE: %', SQLSTATE;
        RAISE;
END;
$$;
