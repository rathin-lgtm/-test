from hv_edp_dagster.constants import ASSET_KINDS, AssetGroups
from hv_edp_dagster.defs.assets.asset_factory import AssetFactory
from hv_edp_dagster.snowflake_infra import ALL_TABLES

asset_factory = AssetFactory(AssetGroups.bronze, ASSET_KINDS)

clear_bronze_table_assets = asset_factory.generate_clear_table_assets(ALL_TABLES)

bronze_table_assets = asset_factory.generate_bronze_table_assets(
    ALL_TABLES, clear_bronze_table_assets
)
