from hv_edp_dagster.constants import (
    IS_LOCAL_ENVIRONMENT,
    SHARED_DEV_BRONZE_PATH,
)
from hv_edp_dagster.defs.resources import JobConfig, SnowflakeConfig
from hv_edp_dagster.snowflake_infra import (
    CSV_FILE_FORMAT,
    DATA_LANDING_STAGE,
    FileFormat,
    Table,
)
from hv_edp_dagster.utils import execute_sql

ASSET_KINDS = {"python", "snowflake"}
# Regex to extract the date from the file name, file name format is YYYY/MM/DD/some_name.csv
DATE_REGEX = r"(\\d{4}/\\d{2}/\\d{2})"


def copy_from_stage_sql(
    table: Table,
    snowflake_config: SnowflakeConfig,
    full_reload: bool | None = False,
    use_shared_stage: bool = True,
    file_format: FileFormat = CSV_FILE_FORMAT,
) -> str:
    location = (
        SHARED_DEV_BRONZE_PATH
        if use_shared_stage and IS_LOCAL_ENVIRONMENT
        else f"{snowflake_config.database}.{snowflake_config.schema_bronze}"
    )
    return f"""COPY INTO {table.name}
        FROM @{location}.{DATA_LANDING_STAGE.name}/{table.source}/{table.name}/
        FILE_FORMAT = (FORMAT_NAME = {file_format.name}, ERROR_ON_COLUMN_COUNT_MISMATCH = False)
        MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
        INCLUDE_METADATA = (
          INGEST_TIME = METADATA$START_SCAN_TIME,
          FILE_NAME = METADATA$FILENAME
        )
        FORCE={full_reload};"""


def add_file_date_sql(table: Table) -> str:
    return f"""UPDATE {table.name}
            SET FILE_DATE = TO_DATE(REGEXP_SUBSTR(FILE_NAME, '{DATE_REGEX}'), 'YYYY/MM/DD')
            WHERE FILE_DATE IS NULL"""


def copy_data_from_stage(
    snowflake_config: SnowflakeConfig, etl_job_config: JobConfig, table: Table
) -> None:
    sql = copy_from_stage_sql(
        table,
        snowflake_config=snowflake_config,
        full_reload=etl_job_config.full_reload,
        use_shared_stage=etl_job_config.use_shared_stage,
    )
    update_file_date_sql = add_file_date_sql(table)
    for sql in (sql, update_file_date_sql):
        execute_sql(snowflake_config, sql)


def clean_table_sql(table: Table) -> str:
    return f"delete from {table.name}"
