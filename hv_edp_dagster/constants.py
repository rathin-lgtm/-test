import os
from enum import Enum

ASSET_KINDS = {"python", "snowflake"}


class Environments():
    PERSONAL_DEV = "personal_dev"
    SHARED_DEV = "shared_dev"
    UAT = "uat"
    PROD = "prod"


class DbtArguments:
    build = "build"
    full_reload = "--full-refresh"
    project_dir = "hv_edp_dbt"

class AssetTags:
    environment = "environment"


class Sources(Enum):
    harbourview_edw = "HARBOURVIEW_EDW"


class FileTypes():
    csv = "CSV"
    parquet = "PARQUET"


class GoldAssets:
    funds = "gold_fund_metrics"

class SnowflakeEnv:
    ENVIRONMENT = os.getenv("ENVIRONMENT")
    IS_LOCAL_ENVIRONMENT = ENVIRONMENT == Environments.PERSONAL_DEV
    SNOWFLAKE_ACCOUNT = os.getenv("SNOWFLAKE_ACCOUNT")
    SNOWFLAKE_WAREHOUSE = os.getenv("SNOWFLAKE_WH")
    SNOWFLAKE_ROLE = os.getenv("SNOWFLAKE_ROLE")
    SNOWFLAKE_USER = os.getenv("SNOWFLAKE_USER", "")
    SNOWFLAKE_PRIVATE_KEY_PATH = os.getenv("SNOWFLAKE_PRIVATE_KEY_PATH")
    SNOWFLAKE_PRIVATE_KEY_PASSPHRASE = os.getenv("SNOWFLAKE_PRIVATE_KEY_PASSPHRASE")

    SNOWFLAKE_CONFIG_DATA = {
        Environments.PERSONAL_DEV: {
            "database": f"HV_EDP_{SNOWFLAKE_USER.split('@')[0]}_DEV",
            "schema_bronze": "PERSONAL_DEV_BRONZE",
        },
        Environments.SHARED_DEV: {
            "database": "HV_EDP_DEV",
            "schema_bronze": "DEV_BRONZE",
        },
        Environments.UAT: {
            "database": "HV_EDP_UAT",
            "schema_bronze": "UAT_BRONZE",
        },
        Environments.PROD: {
            "database": "HV_EDP_PRD",
            "schema_bronze": "PRD_BRONZE",
        },
    }

    SHARED_DEV_BRONZE_PATH = (
        f'{SNOWFLAKE_CONFIG_DATA[Environments.SHARED_DEV]["database"]}.'
        f'{SNOWFLAKE_CONFIG_DATA[Environments.SHARED_DEV]["schema_bronze"]}'
    )

