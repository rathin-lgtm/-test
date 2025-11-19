from dagster import (
    Definitions,
    in_process_executor,
    load_assets_from_package_module,
    multiprocess_executor,
)
from dagster_dbt import DbtCliResource

from hv_edp_dagster.constants import SNOWFLAKE_CONFIG_DATA, Environments
from hv_edp_dagster.constants import SnowflakeEnv as sf
from hv_edp_dagster.defs import assets
from hv_edp_dagster.defs.jobs.etl_jobs import all_etl_jobs
from hv_edp_dagster.defs.jobs.infra_jobs import destroy_infra_job, provision_infra_job
from hv_edp_dagster.defs.resources import JobConfig, SnowflakeConfig
from hv_edp_dagster.defs.sensors import connection_cleanup_sensors, new_file_sensors
from hv_edp_dagster.project import dbt_project


def get_snowflake_config():
    if sf.IS_LOCAL_ENVIRONMENT:
        return SnowflakeConfig(
            account=sf.SNOWFLAKE_ACCOUNT,
            user=sf.SNOWFLAKE_USER,
            warehouse=sf.SNOWFLAKE_WAREHOUSE,
            role=sf.SNOWFLAKE_ROLE,
            authenticator="externalbrowser",
            use_shared_connection=True,
            **SNOWFLAKE_CONFIG_DATA[sf.ENVIRONMENT],
        )
    elif sf.ENVIRONMENT in [Environments.SHARED_DEV, Environments.UAT, Environments.PROD]:
        return SnowflakeConfig(
            account=sf.SNOWFLAKE_ACCOUNT,
            user=sf.SNOWFLAKE_USER,
            warehouse=sf.SNOWFLAKE_WAREHOUSE,
            role=sf.SNOWFLAKE_ROLE,
            private_key_path=sf.SNOWFLAKE_PRIVATE_KEY_PATH,
            private_key_password=sf.SNOWFLAKE_PRIVATE_KEY_PASSPHRASE,
            use_shared_connection=False,
            **SNOWFLAKE_CONFIG_DATA[sf.ENVIRONMENT],
        )
    else:
        raise ValueError(f"Invalid environment: {sf.ENVIRONMENT}")


def get_resources():
    return {
        "dbt": DbtCliResource(project_dir=dbt_project, target=sf.ENVIRONMENT),
        "snowflake_config": get_snowflake_config(),
        "etl_job_config": JobConfig(
            full_reload=False,
            use_shared_stage=sf.IS_LOCAL_ENVIRONMENT,
        ),
        "infra_job_config": JobConfig(
            use_shared_stage=sf.IS_LOCAL_ENVIRONMENT,
        ),
    }


defs = Definitions(
    assets=load_assets_from_package_module(package_module=assets),
    resources=get_resources(),
    jobs=[*all_etl_jobs, provision_infra_job, destroy_infra_job],
    sensors=[*new_file_sensors, *connection_cleanup_sensors],
    executor=in_process_executor if sf.IS_LOCAL_ENVIRONMENT else multiprocess_executor,
)
