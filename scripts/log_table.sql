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
