from pathlib import Path
from typing import Any

from dagster import AssetSelection, get_dagster_logger
from dagster_snowflake import SnowflakeResource

from hv_edp_dagster.constants import IS_LOCAL_ENVIRONMENT, AssetTags, Environments


def get_project_root() -> Path:
    return Path(__file__).parent.parent


def execute_sql(
    snowflake_resource: SnowflakeResource, sql: str, fetch_results: bool = False
) -> list[tuple[Any, ...]] | list[dict[Any, Any]] | Any:
    logger = get_dagster_logger()
    if not sql.strip():
        raise ValueError("SQL statement cannot be empty")
    try:
        logger.info(f"Executing SQL: '{sql}'")
        with snowflake_resource.get_connection() as connection:
            cursor = connection.cursor()
            cursor.execute(sql)
            if fetch_results:
                results = cursor.fetchall()
                return results
            return None
    except Exception as e:
        raise type(e)(f"Failed executing SQL: '{sql}': {str(e)}") from e


def select_assets(group_name: str) -> AssetSelection:
    asset_selection = AssetSelection.groups(group_name)
    if IS_LOCAL_ENVIRONMENT:
        return asset_selection
    return asset_selection - AssetSelection.tag(
        key=AssetTags.environment, value=Environments.PERSONAL_DEV
    )
