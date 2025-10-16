from dagster import AssetExecutionContext, define_asset_job
from dagster_dbt import DbtCliResource, dbt_assets

from hv_edp_dagster.constants import AssetGroups
from hv_edp_dagster.defs.jobs.etl_jobs.common import (
    get_dbt_assets,
)
from hv_edp_dagster.defs.resources import JobConfig
from hv_edp_dagster.project import dbt_project_project
from hv_edp_dagster.utils import select_assets

JOB_NAME = "dim_funds_etl"
DBT_MODELS_TO_RUN = "+gold_funds"


@dbt_assets(manifest=dbt_project_project.manifest_path, select=DBT_MODELS_TO_RUN)
def dbt_project_dbt_assets(
    context: AssetExecutionContext, dbt: DbtCliResource, job_config: JobConfig
):
    yield from get_dbt_assets(job_config.full_reload, dbt, context)


etl_job = define_asset_job(name=JOB_NAME, selection=select_assets(group_name=AssetGroups.funds))
