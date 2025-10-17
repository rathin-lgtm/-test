from dagster import AssetExecutionContext
from dagster_dbt import DbtCliResource, dbt_assets

from hv_edp_dagster.constants import DbtArguments
from hv_edp_dagster.defs.resources import JobConfig
from hv_edp_dagster.project import dbt_project


@dbt_assets(manifest=dbt_project.manifest_path)
def dbt_project_dbt_assets(
    context: AssetExecutionContext, dbt: DbtCliResource, etl_job_config: JobConfig
):
    dbt_build_args = [DbtArguments.build]
    if etl_job_config.full_reload:
        dbt_build_args.append(DbtArguments.full_reload)
    context.log.info(f"Running dbt with args: {dbt_build_args}")
    try:
        yield from dbt.cli(dbt_build_args, context=context).stream()
        context.log.info("Dbt build completed successfully")
    except Exception as e:
        context.log.error(f"Dbt build failed: {e}")
        raise e
