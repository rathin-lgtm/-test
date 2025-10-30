from dagster import define_asset_job,AssetSelection
from hv_edp_dagster.utils import  select_assets_by_group


ASSET_GROUP_NAME = "infra"
provision_infra_job = define_asset_job(
    "provision_infra", selection=select_assets_by_group(group_name=ASSET_GROUP_NAME)
)

ASSET_GROUP_NAME = "destroy_infra"
destroy_infra_job = define_asset_job(
    "destroy_infra", selection=AssetSelection.groups(ASSET_GROUP_NAME)
)
