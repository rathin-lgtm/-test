from dagster import define_asset_job

from hv_edp_dagster.constants import AssetGroups
from hv_edp_dagster.utils import select_assets_by_group

provision_infra_job = define_asset_job(
    "provision_infra", selection=select_assets_by_group(group_name=AssetGroups.provision_infra)
)

destroy_infra_job = define_asset_job(
    "destroy_infra", selection=select_assets_by_group(AssetGroups.destroy_infra)
)
