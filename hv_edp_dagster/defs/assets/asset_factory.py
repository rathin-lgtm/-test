from typing import List

from dagster import AssetsDefinition, asset

from hv_edp_dagster.constants import ASSET_KINDS
from hv_edp_dagster.defs.assets.helper import clear_table_sql, copy_data_from_stage_sql
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

    def generate_snowflake_table_assets(
        self, tables: list[Table], depends_on: List[AssetsDefinition]
    ) -> List[AssetsDefinition]:
        def create_table_asset(table_obj: Table) -> AssetsDefinition:
            @asset(
                name=f"snowflake_table_{table_obj.name}",
                kinds=self.asset_kinds,
                deps=depends_on,
                group_name=self.asset_group,
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

        return [create_table_asset(table) for table in tables]

    def generate_clear_table_assets(self, tables: list[Table]) -> List[AssetsDefinition]:

        def clear_table_assets(table: Table) -> AssetsDefinition:
            @asset(
                name=f"clear_{table.name.lower()}",
                kinds=self.asset_kinds,
                group_name=self.asset_group,
            )
            def _clear_table(snowflake_config: SnowflakeConfig, etl_job_config: JobConfig) -> None:
                if etl_job_config.full_reload:
                    execute_sql(snowflake_config, clear_table_sql(table))

            return _clear_table

        return [clear_table_assets(table) for table in tables]

    def generate_pre_bronze_table_assets(
        self, tables: list[Table], depends_on: List[AssetsDefinition]
    ) -> List[AssetsDefinition]:
        def bronze_table_asset(table: Table, dependancy: AssetsDefinition) -> AssetsDefinition:
            @asset(
                name=f"pre_bronze_{table.name.lower()}",
                kinds=self.asset_kinds,
                deps=[dependancy],
                group_name=self.asset_group,
            )
            def _bronze_table(snowflake_config: SnowflakeConfig, etl_job_config: JobConfig) -> None:
                copy_data_from_stage_sql(snowflake_config, etl_job_config, table)

            return _bronze_table

        return [
            bronze_table_asset(table, dependancy) for table, dependancy in zip(tables, depends_on)
        ]
