from dagster import asset

from hv_edp_dagster.constants import AssetGroups
from hv_edp_dagster.defs.jobs.etl_jobs.common import ASSET_KINDS, clean_table_sql
from hv_edp_dagster.defs.resources import JobConfig, SnowflakeConfig
from hv_edp_dagster.snowflake_infra import BRONZE_DIM_FUNDS_TABLE
from hv_edp_dagster.utils import execute_sql


@asset(kinds=ASSET_KINDS, group_name=AssetGroups.funds)
def clean_bronze_funds(snowflake_config: SnowflakeConfig, job_config: JobConfig) -> None:
    if job_config.full_reload:
        execute_sql(snowflake_config.snowflake_resource, clean_table_sql(BRONZE_DIM_FUNDS_TABLE))
