from hv_edp_dagster.constants import ASSET_KINDS, AssetGroups
from hv_edp_dagster.defs.assets.asset_factory import AssetFactory
from hv_edp_dagster.snowflake_infra import ALL_TABLES

asset_factory = AssetFactory(AssetGroups.raw, ASSET_KINDS)

raw_table_assets = asset_factory.generate_raw_table_assets(ALL_TABLES)
