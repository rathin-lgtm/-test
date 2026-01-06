import os
from enum import Enum

ASSET_KINDS = {"python", "snowflake"}


class Environments:
    PERSONAL_DEV = "personal_dev"
    SHARED_DEV = "shared_dev"
    UAT = "uat"
    PROD = "prod"


class DbtArguments:
    build = "build"
    full_reload = "--full-refresh"
    run_operation = "run-operation"
    stage_external_sources = "stage_external_sources"
    vars = "--vars"
    args = "--args"
    select = "select: {}"


class AssetTags:
    environment = "environment"


class Sources(Enum):
    HARBOURVIEW_EDW = "HARBOURVIEW_EDW"


class FileTypes:
    CSV = "CSV"
    PARQUET = "PARQUET"


class AssetGroups:
    provision_infra = "provision_infra"
    destroy_infra = "destroy_infra"
    raw = "raw"


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
        "database": f"HV_EDP_{SnowflakeEnv.SNOWFLAKE_USER.split('@')[0]}_DEV",
        "schema_raw": "PERSONAL_DEV_RAW",
        "stage": "LANDING",
    },
    Environments.SHARED_DEV: {
        "database": "HV_EDP_DEV",
        "schema_raw": "DEV_RAW",
        "stage": "STG_EXT_DMZ_KRTSYSNP_EDP",
    },
    Environments.UAT: {
        "database": "HV_EDP_UAT",
        "schema_raw": "UAT_RAW",
        "stage": "STG_EXT_DMZ_KRTSYSNP_EDP",
    },
    Environments.PROD: {
        "database": "HV_EDP_PRD",
        "schema_raw": "PRD_RAW",
        "stage": "STG_EXT_DMZ_KRTSYSNP_EDP",
    },
}

SHARED_DEV_CONFIG_DATA = SNOWFLAKE_CONFIG_DATA[Environments.SHARED_DEV]
SHARED_DEV_STAGE_PATH = (
    f"@{SHARED_DEV_CONFIG_DATA['database']}."
    f"{SHARED_DEV_CONFIG_DATA['schema_raw']}."
    f"{SHARED_DEV_CONFIG_DATA['stage']}"
)

FILTERED_FUND_IDS = (
    os.getenv("FILTERED_FUND_IDS", "").split(",") if os.getenv("FILTERED_FUND_IDS") else []
)
