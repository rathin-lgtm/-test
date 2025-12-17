from datetime import datetime

from dagster import (
    DagsterRunStatus,
    DefaultSensorStatus,
    RunRequest,
    SkipReason,
    run_status_sensor,
    sensor,
)

from hv_edp_dagster.constants import SnowflakeEnv
from hv_edp_dagster.defs.resources import SnowflakeConfig
from hv_edp_dagster.snowflake_infra import ALL_TABLES, Table
from hv_edp_dagster.utils import execute_sql, select_assets_by_group


def get_todays_folder_path() -> str:
    return datetime.now().strftime("%Y/%m/%d")


def get_files_from_folder(snowflake_config: SnowflakeConfig, table_name: str) -> list[str]:
    full_stage_path = (
        f"{snowflake_config.database}.{snowflake_config.schema_raw}.{snowflake_config.stage}"
    )
    list_sql = f"LIST @{table_name}/{full_stage_path}/{get_todays_folder_path()};"
    results = execute_sql(snowflake_config, list_sql, fetch_results=True)
    if results is None:
        return []
    return [str(row[0].removeprefix(f"{snowflake_config.stage.lower()}/")) for row in results]


def get_processed_files(snowflake_config: SnowflakeConfig, table_name: str) -> list[str]:
    sql = f"""SELECT FILE_NAME FROM
    {snowflake_config.database}.{snowflake_config.schema_raw}.{table_name}
    where FILE_DATE=TO_DATE('{get_todays_folder_path()}', 'YYYY/MM/DD');"""
    results = execute_sql(snowflake_config, sql, fetch_results=True)
    if results is None:
        return []
    return [str(row[0]) for row in results]


def get_unprocessed_files_data(stage_content: list[str], files_processed: list[str]) -> list[str]:
    return [file for file in stage_content if file not in set(files_processed)]


def create_file_sensor_for_table(tables: list[Table]):
    sensors = []
    for table in tables:

        @sensor(
            name=f"{table.name.lower()}_file_sensor",
            minimum_interval_seconds=30,
            default_status=(
                DefaultSensorStatus.STOPPED
                if SnowflakeEnv.IS_LOCAL_ENVIRONMENT
                else DefaultSensorStatus.RUNNING
            ),
            asset_selection=select_assets_by_group(table.name),
        )
        def table_file_sensor(snowflake_config: SnowflakeConfig):
            all_stage_files = get_files_from_folder(snowflake_config, table.name)
            processed_files = get_processed_files(snowflake_config, table.name)
            unprocessed_files_list = sorted(
                get_unprocessed_files_data(all_stage_files, processed_files)
            )

            if unprocessed_files_list:
                yield RunRequest(
                    run_key=f"{table.name}_{','.join(unprocessed_files_list)}",
                    tags={"table": table.name},
                )
            else:
                yield SkipReason(f"No new files found on stage for {table.name} table")

        sensors.append(table_file_sensor)
    return sensors


def create_cleanup_connection_sensors():
    sensors = []
    if SnowflakeEnv.IS_LOCAL_ENVIRONMENT:
        for status in DagsterRunStatus.FAILURE, DagsterRunStatus.SUCCESS:

            @run_status_sensor(
                name=f"on_any_job_{status.value}_connection_cleanup",
                minimum_interval_seconds=30,
                default_status=DefaultSensorStatus.RUNNING,
                monitor_all_code_locations=True,
                run_status=status,
            )
            def _run_status_sensor(snowflake_config: SnowflakeConfig):
                if snowflake_config.use_shared_connection:
                    snowflake_config.clear_shared_connection()

            sensors.append(_run_status_sensor)
    return sensors


new_file_sensors = create_file_sensor_for_table(ALL_TABLES)
connection_cleanup_sensors = create_cleanup_connection_sensors()
