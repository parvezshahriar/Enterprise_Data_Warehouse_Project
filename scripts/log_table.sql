CREATE TABLE control.file_processing_log (
    log_id BIGSERIAL PRIMARY KEY,
    source_system TEXT NOT NULL,
    table_name TEXT NOT NULL,
    file_name TEXT NOT NULL,
    status TEXT NOT NULL,
    started_at TIMESTAMP NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMP,
    rows_loaded BIGINT,
    error_message TEXT,
    CONSTRAINT uq_file_processing
        UNIQUE (source_system, table_name, file_name)
);

CREATE TABLE control.etl_watermark (
    table_name VARCHAR(100) PRIMARY KEY,
    last_loaded_timestamp TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO control.etl_watermark (table_name, last_loaded_timestamp)
VALUES 
    ('silver.crm_cust_info', '1900-01-01 00:00:00'),
    ('silver.crm_prd_info', '1900-01-01 00:00:00'),
    ('silver.crm_sales_details', '1900-01-01 00:00:00'),
    ('silver.erp_cust_az12', '1900-01-01 00:00:00'),
    ('silver.erp_loc_a101', '1900-01-01 00:00:00'),
    ('silver.erp_px_cat_g1v2', '1900-01-01 00:00:00');
