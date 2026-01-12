from dagster import (
    AssetExecutionContext,
    AssetSpec,
    MaterializeResult,
    asset,
    multi_asset,
)

from hv_edp_dagster.constants import (
    ASSET_KINDS,
    AssetGroups,
    AssetTags,
    Environments,
    SnowflakeEnv,
)
from hv_edp_dagster.defs.resources import SnowflakeConfig
from hv_edp_dagster.snowflake_infra import (
    ALL_FILE_FORMATS,
)
from hv_edp_dagster.utils import execute_sql


@asset(
    kinds=ASSET_KINDS,
    group_name=AssetGroups.provision_infra,
    tags={AssetTags.environment: Environments.PERSONAL_DEV},
)
def snowflake_db(snowflake_config: SnowflakeConfig) -> None:
    execute_sql(
        snowflake_config,
        f"CREATE DATABASE IF NOT EXISTS {snowflake_config.database};",
    )


@asset(
    kinds=ASSET_KINDS,
    deps=[snowflake_db] if SnowflakeEnv.IS_LOCAL_ENVIRONMENT else [],
    group_name=AssetGroups.provision_infra,
)
def snowflake_schema(snowflake_config: SnowflakeConfig) -> None:
    execute_sql(
        snowflake_config,
        f"CREATE SCHEMA IF NOT EXISTS {snowflake_config.schema_raw};",
    )


@multi_asset(
    specs=[
        AssetSpec(
            key=f"snowflake_file_format_{file_format.name}",
            kinds=ASSET_KINDS,
            deps=[snowflake_schema],
        )
        for file_format in ALL_FILE_FORMATS
    ],
    can_subset=True,
    group_name=AssetGroups.provision_infra,
)
def file_formats(context: AssetExecutionContext, snowflake_config: SnowflakeConfig):
    for file_format in ALL_FILE_FORMATS:
        execute_sql(snowflake_config, file_format.create_sql())
    for key in context.selected_asset_keys:
        yield MaterializeResult(key)


@asset(kinds=ASSET_KINDS, group_name=AssetGroups.destroy_infra)
def snowflake_destroy_db(snowflake_config: SnowflakeConfig) -> None:
    execute_sql(
        snowflake_config,
        f"DROP DATABASE {snowflake_config.database};",
    )
