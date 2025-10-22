from dagster import AssetsDefinition, asset

from hv_edp_dagster.constants import ASSET_KINDS
from hv_edp_dagster.defs.jobs.etl_jobs.common import (
    clean_table_sql,
    copy_data_from_stage,
)
from hv_edp_dagster.defs.resources import JobConfig, SnowflakeConfig
from hv_edp_dagster.snowflake_infra import ALL_TABLES, Table
from hv_edp_dagster.utils import execute_sql


def get_clean_table_asset(table: Table) -> AssetsDefinition:
    @asset(
        kinds=ASSET_KINDS,
        group_name=table.name,
        name=f"clean_{table.name.lower()}",
    )
    def _clean_table(snowflake_config: SnowflakeConfig, etl_job_config: JobConfig) -> None:
        if etl_job_config.full_reload:
            execute_sql(snowflake_config, clean_table_sql(table))

    return _clean_table


def get_bronze_table_asset(clean_table_asset: AssetsDefinition, table: Table) -> AssetsDefinition:
    @asset(
        kinds=ASSET_KINDS,
        deps=[clean_table_asset],
        group_name=table.name,
        name=f"bronze_{table.name.lower()}",
    )
    def _bronze_table(snowflake_config: SnowflakeConfig, etl_job_config: JobConfig) -> None:
        copy_data_from_stage(snowflake_config, etl_job_config, table)

    return _bronze_table


clean_bronze_table_assets = [get_clean_table_asset(table) for table in ALL_TABLES]
bronze_table_assets = [
    get_bronze_table_asset(clean_asset, table)
    for clean_asset, table in zip(clean_bronze_table_assets, ALL_TABLES)
]
