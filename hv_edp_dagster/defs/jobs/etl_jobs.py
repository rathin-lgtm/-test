from dagster import define_asset_job

from hv_edp_dagster.constants import ETLJobs, GoldModels
from hv_edp_dagster.utils import select_gold_asset_with_upstream

fund_metrics_etl_job = define_asset_job(
    name=ETLJobs.fund_metrics, selection=select_gold_asset_with_upstream(GoldModels.fund_metrics)
)

portfolio_metrics_etl_job = define_asset_job(
    name=ETLJobs.portfolio_metrics,
    selection=select_gold_asset_with_upstream(GoldModels.portfolio_metrics),
)

company_metrics_etl_job = define_asset_job(
    name=ETLJobs.company_metrics,
    selection=select_gold_asset_with_upstream(GoldModels.company_metrics),
)
