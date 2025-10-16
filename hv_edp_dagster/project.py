import os

from dagster_dbt import DbtProject

from hv_edp_dagster.utils import get_project_root

dbt_project = DbtProject(
    project_dir=get_project_root(),
    packaged_project_dir=os.path.join(get_project_root(), "dbt-project"),
)
dbt_project.prepare_if_dev()
