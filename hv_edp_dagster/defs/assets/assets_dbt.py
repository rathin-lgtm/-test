from dagster import AssetExecutionContext, AssetMaterialization
from dagster_dbt import DagsterDbtTranslator, DbtCliResource, dbt_assets

from hv_edp_dagster.constants import DbtArguments
from hv_edp_dagster.defs.resources import JobConfig
from hv_edp_dagster.project import dbt_project

dagster_dbt_translator = DagsterDbtTranslator()


@dbt_assets(manifest=dbt_project.manifest_path)
def dbt_project_dbt_assets(
    context: AssetExecutionContext, dbt: DbtCliResource, etl_job_config: JobConfig
):
    dbt_build_args = [DbtArguments.build]
    if etl_job_config.full_reload:
        dbt_build_args.append(DbtArguments.full_reload)
    context.log.info(f"Running dbt with args: {dbt_build_args}")
    try:
        invocation = dbt.cli(dbt_build_args, context=context)
        dbt_events = list(invocation.stream_raw_events())
        dagster_events = [
            dagster_event
            for dbt_event in dbt_events
            for dagster_event in dbt_event.to_default_asset_events(manifest=invocation.manifest)
        ]
        run_results = invocation.get_artifact("run_results.json")
        manifest = invocation.get_artifact("manifest.json")
        results_by_asset_key = {
            dagster_dbt_translator.get_asset_key(manifest["nodes"][result["unique_id"]]): result
            for result in run_results["results"]
        }
        for dagster_event in dagster_events:
            if isinstance(dagster_event, AssetMaterialization):
                asset_result = results_by_asset_key[dagster_event.asset_key]
                context.log.info(
                    f"Compiled code: {asset_result.get('compiled_code',
                                                       'No compiled code available')}."
                )
            yield dagster_event
        context.log.info("Dbt build completed successfully")
    except Exception as e:
        context.log.error(f"Dbt build failed: {e}")
        raise e
