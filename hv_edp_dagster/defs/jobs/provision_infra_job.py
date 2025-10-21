from typing import List

from dagster import AssetsDefinition, asset, define_asset_job

from hv_edp_dagster.constants import (
    ASSET_KINDS,
    IS_LOCAL_ENVIRONMENT,
    AssetTags,
    Environments,
)
from hv_edp_dagster.defs.resources import JobConfig, SnowflakeConfig
from hv_edp_dagster.snowflake_infra import (
    ALL_FILE_FORMATS,
    ALL_TABLES,
    DATA_LANDING_STAGE,
    FileFormat,
    Table,
)
from hv_edp_dagster.utils import execute_sql, select_assets

ASSET_GROUP_NAME = "infra"


@asset(
    kinds=ASSET_KINDS,
    group_name=ASSET_GROUP_NAME,
    tags={AssetTags.environment: Environments.PERSONAL_DEV},
)
def prepare_db(snowflake_config: SnowflakeConfig) -> None:
    execute_sql(
        snowflake_config,
        f"CREATE DATABASE IF NOT EXISTS {snowflake_config.database};",
    )


@asset(
    kinds=ASSET_KINDS,
    deps=[prepare_db] if IS_LOCAL_ENVIRONMENT else [],
    group_name=ASSET_GROUP_NAME,
)
def prepare_schema(snowflake_config: SnowflakeConfig) -> None:
    execute_sql(
        snowflake_config,
        f"CREATE SCHEMA IF NOT EXISTS {snowflake_config.schema_bronze};",
    )


def generate_prepare_file_format_assets() -> List[AssetsDefinition]:
    def prepare_file_format(file_format: FileFormat) -> AssetsDefinition:
        @asset(
            kinds=ASSET_KINDS,
            deps=[prepare_schema],
            group_name=ASSET_GROUP_NAME,
            name=f"prepare_file_format_{file_format.name}",
        )
        def _file_format(snowflake_config: SnowflakeConfig) -> None:
            execute_sql(snowflake_config, file_format.create_sql())

        return _file_format

    return [prepare_file_format(file_format) for file_format in ALL_FILE_FORMATS]


@asset(
    kinds=ASSET_KINDS,
    deps=[prepare_schema],
    group_name=ASSET_GROUP_NAME,
    tags={AssetTags.environment: Environments.PERSONAL_DEV},
)
def prepare_landing_stage(snowflake_config: SnowflakeConfig) -> None:
    execute_sql(
        snowflake_config,
        DATA_LANDING_STAGE.create_sql(snowflake_config.database, snowflake_config.schema_bronze),
    )


def generate_prepare_table_assets(
    file_format_assets: List[AssetsDefinition],
) -> List[AssetsDefinition]:
    def create_table_asset(table_obj: Table) -> AssetsDefinition:
        @asset(
            name=f"prepare_table_{table_obj.name}",
            kinds=ASSET_KINDS,
            deps=[*file_format_assets, prepare_landing_stage],
            group_name=ASSET_GROUP_NAME,
        )
        def _table(snowflake_config: SnowflakeConfig, infra_job_config: JobConfig) -> None:
            execute_sql(
                snowflake_config,
                table_obj.create_sql(
                    snowflake_config.database,
                    snowflake_config.schema_bronze,
                    use_shared_stage=infra_job_config.use_shared_stage,
                ),
            )

        return _table

    return [create_table_asset(table) for table in ALL_TABLES]


prepare_file_format_assets: List[AssetsDefinition] = generate_prepare_file_format_assets()
prepare_table_assets: List[AssetsDefinition] = generate_prepare_table_assets(
    prepare_file_format_assets
)

provision_infra_job = define_asset_job(
    "provision_infra", selection=select_assets(group_name=ASSET_GROUP_NAME)
)
