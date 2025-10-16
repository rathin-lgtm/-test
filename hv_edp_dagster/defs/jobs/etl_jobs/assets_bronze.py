from dagster import asset

from hv_edp_dagster.constants import AssetGroups
from hv_edp_dagster.defs.jobs.etl_jobs.assets_clean_bronze import clean_bronze_funds
from hv_edp_dagster.defs.jobs.etl_jobs.common import ASSET_KINDS, copy_data_from_stage
from hv_edp_dagster.defs.resources import JobConfig, SnowflakeConfig
from hv_edp_dagster.snowflake_infra import BRONZE_DIM_FUNDS_TABLE


@asset(kinds=ASSET_KINDS, deps=[clean_bronze_funds], group_name=AssetGroups.funds)
def bronze_funds(snowflake_config: SnowflakeConfig, job_config: JobConfig) -> None:
    copy_data_from_stage(snowflake_config, job_config, BRONZE_DIM_FUNDS_TABLE)
