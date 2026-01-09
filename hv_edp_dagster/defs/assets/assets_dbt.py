import json

from dagster import (
    AssetExecutionContext,
    AssetSpec,
    MaterializeResult,
    Output,
    multi_asset,
)
from dagster_dbt import DagsterDbtTranslator, DbtCliResource, dbt_assets

from hv_edp_dagster.constants import AssetGroups, DbtArguments
from hv_edp_dagster.defs.resources import JobConfig
from hv_edp_dagster.project import dbt_project


def dbt_source_assets():
    manifest = json.loads(dbt_project.manifest_path.read_text())
    translator = DagsterDbtTranslator()
    return [
        AssetSpec(
            key=translator.get_asset_key(source),
        )
        for source in manifest["sources"].values()
    ]


@multi_asset(specs=dbt_source_assets(), can_subset=True, group_name=AssetGroups.raw)
def dbt_sources_external_tables(
    context: AssetExecutionContext, dbt: DbtCliResource, etl_job_config: JobConfig
):
    vars = json.dumps({"stage_location": etl_job_config.stage_location, "ext_full_refresh": True})
    dbt_args = [
        DbtArguments.run_operation,
        DbtArguments.stage_external_sources,
        DbtArguments.args,
        DbtArguments.select.format(
            " ".join([".".join(key.path) for key in context.selected_asset_keys])
        ),
        DbtArguments.vars,
        vars,
    ]

    dbt.cli(
        dbt_args,
        manifest=dbt_project.manifest_path,
    ).wait()
    for key in context.selected_asset_keys:
        yield MaterializeResult(asset_key=key)


@dbt_assets(manifest=dbt_project.manifest_path)
def dbt_project_dbt_assets(
    context: AssetExecutionContext, dbt: DbtCliResource, etl_job_config: JobConfig
):
    dbt_build_args = [DbtArguments.build]
    filters = {}
    if etl_job_config.filtered_fund_ids:
        filters["filtered_fund_ids"] = etl_job_config.filtered_fund_ids
    if etl_job_config.filtered_investor_ids:
        filters["filtered_investor_ids"] = etl_job_config.filtered_investor_ids
    dbt_build_args.extend([DbtArguments.vars, json.dumps(filters)])
    if etl_job_config.full_reload:
        dbt_build_args.append(DbtArguments.full_reload)
    context.log.info(f"Running dbt with args: {dbt_build_args}")
    try:
        invocation = dbt.cli(dbt_build_args, context=context)
        dagster_events = list(invocation.stream())
        try:
            run_results = invocation.get_artifact("run_results.json")
            compiled_code_by_unique_id = {
                result["unique_id"]: result.get("compiled_code")
                for result in run_results["results"]
            }
        except Exception as e:
            context.log.error(f"Failed to get run_results.json: {e}")
        for dagster_event in dagster_events:
            try:
                if isinstance(dagster_event, Output):
                    compiled_code = compiled_code_by_unique_id.get(
                        dagster_event.metadata["unique_id"].text, "No compiled code available"
                    )
                    context.log.info(f"Compiled code: {compiled_code}")
            except Exception as e:
                context.log.error(f"Failed to log compiled code: {e}")
            yield dagster_event
        context.log.info("Dbt build completed successfully")
    except Exception as e:
        context.log.error(f"Dbt build failed: {e}")
        raise e
