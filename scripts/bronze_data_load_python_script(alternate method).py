import os
import psycopg2
from psycopg2 import sql


DB_CONFIG = {
    "dbname": "your_db",
    "user": "user",
    "password": "pwd",
    "host": "localhost"
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
                # 2. Load CSV into PostgreSQL
                # -------------------------------------------------

                column_list = sql.SQL(", ").join(
                    sql.Identifier(column)
                    for column in config["columns"]
                )

                copy_sql = sql.SQL(
                    """
                    COPY {} ({})
                    FROM STDIN
                    WITH (
                        FORMAT CSV,
                        HEADER TRUE,
                        DELIMITER ','
                    )
                    """
                ).format(
                    sql.SQL(config["table"]),
                    column_list
                )

                with open(full_path, "r", encoding="utf-8") as f:
                    cur.copy_expert(copy_sql.as_string(conn), f)

                # -------------------------------------------------
                # 3. Log successful processing
                # -------------------------------------------------

                cur.execute(
                    """
                    INSERT INTO control.file_processing_log
                    (
                        source_system,
                        table_name,
                        file_name,
                        status
                    )
                    VALUES (%s, %s, %s, 'SUCCESS')
                    """,
                    (
                        config["source_system"],
                        config["table"],
                        file_name
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
