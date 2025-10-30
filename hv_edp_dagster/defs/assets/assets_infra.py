from typing import List
from dagster import AssetsDefinition, asset
from hv_edp_dagster.utils import execute_sql
from hv_edp_dagster.defs.assets.asset_factory import AssetFactory

from hv_edp_dagster.constants import (
    ASSET_KINDS,
    SnowflakeEnv,
    AssetTags,
    Environments,
)
from hv_edp_dagster.snowflake_infra import (
    ALL_FILE_FORMATS,
    ALL_TABLES,
    DATA_LANDING_STAGE
)

from hv_edp_dagster.defs.resources import SnowflakeConfig

ASSET_GROUP_NAME = "infra"
asset_factory = AssetFactory(ASSET_GROUP_NAME,ASSET_KINDS)

@asset(
    kinds=ASSET_KINDS,
    group_name=ASSET_GROUP_NAME,
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
    group_name=ASSET_GROUP_NAME,
)
def snowflake_schema(snowflake_config: SnowflakeConfig) -> None:
    execute_sql(
        snowflake_config,
        f"CREATE SCHEMA IF NOT EXISTS {snowflake_config.schema_bronze};",
    )


@asset(
    kinds=ASSET_KINDS,
    deps=[snowflake_schema],
    group_name=ASSET_GROUP_NAME,
    tags={AssetTags.environment: Environments.PERSONAL_DEV},
)
def snowflake_landing_stage(snowflake_config: SnowflakeConfig) -> None:
    execute_sql(
        snowflake_config,
        DATA_LANDING_STAGE.create_sql(snowflake_config.database, snowflake_config.schema_bronze),
    )

snowflake_file_format_assets: List[AssetsDefinition] = asset_factory.generate_snowflake_file_format_assets(
                                                            ALL_FILE_FORMATS,
                                                            [snowflake_schema])

snowflake_table_assets: List[AssetsDefinition] = asset_factory.generate_snowflake_table_assets(
                                                            ALL_TABLES,
                                                            [snowflake_landing_stage] + snowflake_file_format_assets)


ASSET_GROUP_NAME = "destroy_infra"

@asset(kinds=ASSET_KINDS, group_name=ASSET_GROUP_NAME)
def snowflake_destroy_db(snowflake_config: SnowflakeConfig) -> None:
    execute_sql(
        snowflake_config,
        f"DROP DATABASE {snowflake_config.database};",
    )
