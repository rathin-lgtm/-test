from pathlib import Path

import yaml
from dagster import define_asset_job

from hv_edp_dagster.utils import get_dbt_project_dir, select_gold_asset_with_upstream


def load_gold_definitions() -> list[str]:
    try:
        config_path = Path(get_dbt_project_dir(), "models", "gold", "gold.yml")
        with open(config_path) as f:
            config_data = yaml.safe_load(f)
        gold_model_names = [model["name"] for model in config_data["models"]]
        return gold_model_names
    except Exception:
        raise Exception("Error loading gold.yml occured, make sure it has valid data.")


all_etl_jobs = [
    define_asset_job(
        name=f"{model_name}_etl_job",
        selection=select_gold_asset_with_upstream(model_name),
    )
    for model_name in load_gold_definitions()
]
