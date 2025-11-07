from dagster import define_asset_job

from hv_edp_dagster.constants import GoldModels
from hv_edp_dagster.utils import select_gold_asset_with_upstream

JOB_NAME = "portfolio_metrics_etl"

portfolio_metrics_etl_job = define_asset_job(
    name=JOB_NAME, selection=select_gold_asset_with_upstream(GoldModels.portfolio_metrics)
)
