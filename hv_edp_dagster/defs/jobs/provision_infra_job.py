from typing import List

from dagster import AssetsDefinition, asset, define_asset_job

from hv_edp_dagster.constants import IS_LOCAL_ENVIRONMENT, AssetTags, Environments
from hv_edp_dagster.defs.resources import SnowflakeConfig
from hv_edp_dagster.snowflake_infra import (
    ALL_TABLES,
    CSV_FILE_FORMAT,
    DATA_LANDING_STAGE,
    Table,
)
from hv_edp_dagster.utils import execute_sql, select_assets

ASSET_GROUP_NAME = "infra"
ASSET_KINDS = {"python", "snowflake"}


@asset(
    kinds=ASSET_KINDS,
    group_name=ASSET_GROUP_NAME,
    tags={AssetTags.environment: Environments.PERSONAL_DEV},
)
def prepare_db(snowflake_config: SnowflakeConfig) -> None:
    execute_sql(
        snowflake_config.snowflake_resource,
        f"CREATE DATABASE IF NOT EXISTS {snowflake_config.database};",
    )


@asset(
    kinds=ASSET_KINDS,
    deps=[prepare_db] if IS_LOCAL_ENVIRONMENT else [],
    group_name=ASSET_GROUP_NAME,
)
def prepare_schema(snowflake_config: SnowflakeConfig) -> None:
    execute_sql(
        snowflake_config.snowflake_resource,
        f"CREATE SCHEMA IF NOT EXISTS {snowflake_config.schema_bronze};",
    )


@asset(kinds=ASSET_KINDS, deps=[prepare_schema], group_name=ASSET_GROUP_NAME)
def prepare_file_format(snowflake_config: SnowflakeConfig) -> None:
    execute_sql(snowflake_config.snowflake_resource, CSV_FILE_FORMAT.create_sql())


@asset(
    kinds=ASSET_KINDS,
    deps=[prepare_schema],
    group_name=ASSET_GROUP_NAME,
    tags={AssetTags.environment: Environments.PERSONAL_DEV},
)
def prepare_landing_stage(snowflake_config: SnowflakeConfig) -> None:
    execute_sql(
        snowflake_config.snowflake_resource,
        DATA_LANDING_STAGE.create_sql(snowflake_config.database, snowflake_config.schema_bronze),
    )


def generate_prepare_table_assets() -> List[AssetsDefinition]:
    def create_table_asset(table_obj: Table) -> AssetsDefinition:
        @asset(
            name=f"prepare_table_{table_obj.name}",
            kinds=ASSET_KINDS,
            deps=[prepare_schema],
            group_name=ASSET_GROUP_NAME,
        )
        def _table(snowflake_config: SnowflakeConfig) -> None:
            execute_sql(
                snowflake_config.snowflake_resource,
                table_obj.create_sql(snowflake_config.database, snowflake_config.schema_bronze),
            )

        return _table

    return [create_table_asset(table) for table in ALL_TABLES]


prepare_table_assets: List[AssetsDefinition] = generate_prepare_table_assets()

provision_infra_job = define_asset_job(
    "provision_infra", selection=select_assets(group_name=ASSET_GROUP_NAME)
)
