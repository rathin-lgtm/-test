from typing import List

from dagster import AssetsDefinition, asset

from hv_edp_dagster.constants import ASSET_KINDS
from hv_edp_dagster.defs.resources import JobConfig, SnowflakeConfig
from hv_edp_dagster.snowflake_infra import FileFormat, Table
from hv_edp_dagster.utils import execute_sql


class AssetFactory:

    def __init__(self, asset_group: str, asset_kinds: set[str] = ASSET_KINDS) -> None:
        self.asset_group = asset_group
        self.asset_kinds = asset_kinds

    def generate_snowflake_file_format_assets(
        self, file_formats: List[FileFormat], depends_on: list[AssetsDefinition]
    ) -> List[AssetsDefinition]:

        def snowflake_file_format(file_format: FileFormat) -> AssetsDefinition:
            @asset(
                kinds=self.asset_kinds,
                deps=depends_on,
                group_name=self.asset_group,
                name=f"snowflake_file_format_{file_format.name}",
            )
            def _file_format(snowflake_config: SnowflakeConfig) -> None:
                execute_sql(snowflake_config, file_format.create_sql())

            return _file_format

        return [snowflake_file_format(file_format) for file_format in file_formats]

    def generate_raw_table_assets(self, tables: list[Table]) -> List[AssetsDefinition]:
        def create_table_asset(table: Table) -> AssetsDefinition:
            @asset(
                name=table.name.lower(),
                kinds=self.asset_kinds,
                group_name=self.asset_group,
                key_prefix="raw_from_harborview_edw",
            )
            def _table(snowflake_config: SnowflakeConfig, infra_job_config: JobConfig) -> None:
                execute_sql(
                    snowflake_config,
                    table.create_sql(
                        snowflake_config.database,
                        snowflake_config.schema_bronze,
                        stage_location=infra_job_config.stage_location,
                    ),
                )

            return _table

        return [create_table_asset(table) for table in tables]
