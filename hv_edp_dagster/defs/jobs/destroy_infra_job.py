from dagster import AssetSelection, asset, define_asset_job

from hv_edp_dagster.defs.resources import SnowflakeConfig
from hv_edp_dagster.utils import execute_sql

ASSET_GROUP_NAME = "destroy_infra"
ASSET_KINDS = {"python", "snowflake"}


@asset(kinds=ASSET_KINDS, group_name=ASSET_GROUP_NAME)
def destroy_db(snowflake_config: SnowflakeConfig) -> None:
    execute_sql(
        snowflake_config.snowflake_resource,
        f"DROP DATABASE {snowflake_config.database};",
    )


destroy_infra_job = define_asset_job(
    "destroy_infra", selection=AssetSelection.groups(ASSET_GROUP_NAME)
)
