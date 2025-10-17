from dagster import Definitions, load_assets_from_package_module
from dagster_dbt import DbtCliResource

from hv_edp_dagster.constants import (
    ENVIRONMENT,
    IS_LOCAL_ENVIRONMENT,
    SNOWFLAKE_ACCOUNT,
    SNOWFLAKE_CONFIG_DATA,
    SNOWFLAKE_PRIVATE_KEY_PASSPHRASE,
    SNOWFLAKE_PRIVATE_KEY_PATH,
    SNOWFLAKE_ROLE,
    SNOWFLAKE_USER,
    SNOWFLAKE_WAREHOUSE,
    Environments,
)
from hv_edp_dagster.defs import jobs
from hv_edp_dagster.defs.jobs.destroy_infra_job import destroy_infra_job
from hv_edp_dagster.defs.jobs.etl_jobs.etl_funds import (
    etl_job,
)
from hv_edp_dagster.defs.jobs.provision_infra_job import (
    provision_infra_job,
)
from hv_edp_dagster.defs.resources import JobConfig, SnowflakeConfig
from hv_edp_dagster.defs.sensors import new_file_sensors
from hv_edp_dagster.project import dbt_project


def get_snowflake_config():
    if IS_LOCAL_ENVIRONMENT:
        return SnowflakeConfig(
            account=SNOWFLAKE_ACCOUNT,
            user=SNOWFLAKE_USER,
            warehouse=SNOWFLAKE_WAREHOUSE,
            role=SNOWFLAKE_ROLE,
            authenticator="externalbrowser",
            **SNOWFLAKE_CONFIG_DATA[ENVIRONMENT],
        )
    elif ENVIRONMENT in [Environments.SHARED_DEV, Environments.UAT, Environments.PROD]:
        return SnowflakeConfig(
            account=SNOWFLAKE_ACCOUNT,
            user=SNOWFLAKE_USER,
            warehouse=SNOWFLAKE_WAREHOUSE,
            role=SNOWFLAKE_ROLE,
            private_key_path=SNOWFLAKE_PRIVATE_KEY_PATH,
            private_key_password=SNOWFLAKE_PRIVATE_KEY_PASSPHRASE,
            **SNOWFLAKE_CONFIG_DATA[ENVIRONMENT],
        )
    else:
        raise ValueError(f"Invalid environment: {ENVIRONMENT}")


def get_resources():
    return {
        "dbt": DbtCliResource(project_dir=dbt_project, target=ENVIRONMENT),
        "snowflake_config": get_snowflake_config(),
        "etl_job_config": JobConfig(
            full_reload=False,
            use_shared_stage=IS_LOCAL_ENVIRONMENT,
        ),
        "infra_job_config": JobConfig(
            use_shared_stage=IS_LOCAL_ENVIRONMENT,
        ),
    }


defs = Definitions(
    assets=load_assets_from_package_module(package_module=jobs),
    resources=get_resources(),
    jobs=[etl_job, provision_infra_job, destroy_infra_job],
    sensors=new_file_sensors,
)
