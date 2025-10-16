from dagster import define_asset_job

from hv_edp_dagster.snowflake_infra import BronzeTables
from hv_edp_dagster.utils import select_assets

JOB_NAME = "dim_funds_etl"

etl_job = define_asset_job(
    name=JOB_NAME, selection=select_assets(group_name=BronzeTables.dim_funds.name)
)
