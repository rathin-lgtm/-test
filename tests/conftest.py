"""
Pytest configuration and fixtures for HV EDP tests.
"""
import os
from pathlib import Path

import pytest
from dagster import build_op_context
from dagster_dbt import DbtCliResource

from hv_edp_dagster.defs.resources import JobConfig, SnowflakeConfig


@pytest.fixture
def project_root() -> Path:
    """Return the project root directory."""
    return Path(__file__).parent.parent


@pytest.fixture
def dbt_project_dir(project_root: Path) -> Path:
    """Return the dbt project directory."""
    return project_root / "hv_edp_dbt"


@pytest.fixture
def test_snowflake_config() -> SnowflakeConfig:
    """Create a test Snowflake configuration."""
    return SnowflakeConfig(
        account=os.getenv("SNOWFLAKE_ACCOUNT", "TEST_ACCOUNT"),
        user=os.getenv("SNOWFLAKE_USER", "TEST_USER"),
        warehouse=os.getenv("SNOWFLAKE_WH", "TEST_WH"),
        role=os.getenv("SNOWFLAKE_ROLE", "TEST_ROLE"),
        database="TEST_DB",
        schema_raw="TEST_RAW",
        stage="TEST_STAGE",
        authenticator="externalbrowser",
        use_shared_connection=False,
    )


@pytest.fixture
def test_job_config() -> JobConfig:
    """Create a test job configuration."""
    return JobConfig(
        full_reload=False,
        stage_location="@TEST_DB.TEST_RAW.TEST_STAGE",
        filtered_fund_ids=[],
        filtered_investor_ids=[],
    )


@pytest.fixture
def mock_dbt_cli_resource(dbt_project_dir: Path):
    """Create a mock dbt CLI resource for testing."""
    return DbtCliResource(project_dir=dbt_project_dir, target="personal_dev")


@pytest.fixture
def mock_dagster_context():
    """Create a mock Dagster context for testing."""
    return build_op_context()
