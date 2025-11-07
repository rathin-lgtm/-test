from typing import List

from dagster import AssetsDefinition, asset

from hv_edp_dagster.constants import (
    ASSET_KINDS,
    AssetGroups,
    AssetTags,
    Environments,
    SnowflakeEnv,
)
from hv_edp_dagster.defs.assets.asset_factory import AssetFactory
from hv_edp_dagster.defs.resources import SnowflakeConfig
from hv_edp_dagster.snowflake_infra import (
    ALL_FILE_FORMATS,
    ALL_TABLES,
    DATA_LANDING_STAGE,
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
        f"CREATE SCHEMA IF NOT EXISTS {snowflake_config.schema_bronze};",
    )


@asset(
    kinds=ASSET_KINDS,
    deps=[snowflake_schema],
    group_name=AssetGroups.provision_infra,
    tags={AssetTags.environment: Environments.PERSONAL_DEV},
)
def snowflake_landing_stage(snowflake_config: SnowflakeConfig) -> None:
    execute_sql(
        snowflake_config,
        DATA_LANDING_STAGE.create_sql(snowflake_config.database, snowflake_config.schema_bronze),
    )


provision_infra_asset_factory = AssetFactory(AssetGroups.provision_infra, ASSET_KINDS)
snowflake_file_format_assets: List[AssetsDefinition] = (
    provision_infra_asset_factory.generate_snowflake_file_format_assets(
        ALL_FILE_FORMATS, [snowflake_schema]
    )
)
snowflake_table_assets: List[AssetsDefinition] = (
    provision_infra_asset_factory.generate_snowflake_table_assets(
        ALL_TABLES, [snowflake_landing_stage] + snowflake_file_format_assets
    )
)


@asset(kinds=ASSET_KINDS, group_name=AssetGroups.destroy_infra)
def snowflake_destroy_db(snowflake_config: SnowflakeConfig) -> None:
    execute_sql(
        snowflake_config,
        f"DROP DATABASE {snowflake_config.database};",
    )
