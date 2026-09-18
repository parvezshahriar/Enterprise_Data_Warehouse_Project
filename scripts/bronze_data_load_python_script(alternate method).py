
import os
import psycopg2
from psycopg2 import sql
import datetime


DB_CONFIG = {
    "dbname": "test",
    "user": "user",
    "password": "password",
    "host": "localhost",
    "port": ****
}


CONFIGS = [
    {
        "dir": "C:/datasets/source_crm",
        "prefix": "cust_info",
        "table": "bronze.crm_cust_info",
        "source_system": "CRM",
        "columns": [
            "cst_id",
            "cst_key",
            "cst_firstname",
            "cst_lastname",
            "cst_material_status",
            "cst_gndr",
            "cst_create_date"
        ]
    },
    {
        "dir": "C:/datasets/source_crm",
        "prefix": "prd_info",
        "table": "bronze.crm_prd_info",
        "source_system": "CRM",
        "columns": [
            "prd_id",
            "prd_key",
            "prd_nm",
            "prd_cost",
            "prd_line",
            "prd_start_dt",
            "prd_end_dt"
        ]
    },
    {
        "dir": "C:/datasets/source_erp",
        "prefix": "CUST_AZ12",
        "table": "bronze.erp_cust_az12",
        "source_system": "ERP",
        "columns": [
            "cid",
            "bdate",
            "gen"
        ]
    }
]


def load_files():

    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()

    try:

        for config in CONFIGS:

            for file_name in os.listdir(config["dir"]):

                if not (
                    file_name.startswith(config["prefix"])
                    and file_name.endswith(".csv")
                ):
                    continue

                # -------------------------------------------------
                # 1. Check whether this file was already processed
                # -------------------------------------------------

                cur.execute(
                    """
                    SELECT 1
                    FROM control.file_processing_log
                    WHERE source_system = %s
                      AND table_name = %s
                      AND file_name = %s
                      AND status = 'SUCCESS'
                    """,
                    (
                        config["source_system"],
                        config["table"],
                        file_name
                    )
                )

                if cur.fetchone():
                    print(f"Skipping already processed file: {file_name}")
                    continue

                print(f"Loading new file: {file_name}")

                full_path = os.path.join(
                    config["dir"],
                    file_name
                )

                # -------------------------------------------------
                # 2. Load CSV into PostgreSQL (WITH FILE_SOURCE)
                # -------------------------------------------------
                
                # Capture the exact time processing started
                start_time = datetime.datetime.now()

                # Create a comma-separated string of the columns for our SQL queries
                column_list_str = ", ".join(config["columns"])

                # A. Create a temporary table that mirrors the target table
                cur.execute(
                    f"CREATE TEMP TABLE temp_load (LIKE {config['table']} EXCLUDING DEFAULTS) ON COMMIT DROP"
                )

                # B. Build the COPY SQL to load the CSV into the TEMP table
                copy_sql = f"""
                    COPY temp_load ({column_list_str})
                    FROM STDIN
                    WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',')
                """

                # Execute the COPY command from the file
                with open(full_path, "r", encoding="utf-8") as f:
                    cur.copy_expert(copy_sql, f)

                # C. Insert from the temp table into the final table, manually appending the file_source
                insert_sql = f"""
                    INSERT INTO {config['table']} ({column_list_str}, file_source, ingestion_timestamp)
                    SELECT {column_list_str}, %s, NOW()
                    FROM temp_load
                """
                
                # Execute the insert, passing the file_name as a parameter
                cur.execute(insert_sql, (file_name,))
                
                # Capture how many rows were just inserted
                rows_loaded = cur.rowcount
                
                # D. Clean up the temp table for the next file
                cur.execute("DROP TABLE temp_load")

                # -------------------------------------------------
                # 3. Log successful processing with metrics
                # -------------------------------------------------
                
                # Capture the exact time processing finished
                end_time = datetime.datetime.now()

                cur.execute(
                    """
                    INSERT INTO control.file_processing_log
                    (
                        source_system,
                        table_name,
                        file_name,
                        status,
                        started_at,
                        completed_at,
                        rows_loaded
                    )
                    VALUES (%s, %s, %s, 'SUCCESS', %s, %s, %s)
                    """,
                    (
                        config["source_system"],
                        config["table"],
                        file_name,
                        start_time,
                        end_time,
                        rows_loaded
                    )
                )

                # -------------------------------------------------
                # 4. Commit file transaction
                # -------------------------------------------------

                conn.commit()

                print(f"Successfully loaded: {file_name}")

    except Exception as e:

        conn.rollback()

        print("ERROR:", e)

        raise

    finally:

        cur.close()
        conn.close()


if __name__ == "__main__":
    load_files()
