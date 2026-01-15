"""
Tests for Dagster resources.
"""
import pytest

from hv_edp_dagster.defs.resources import JobConfig, SnowflakeConfig


class TestSnowflakeConfig:
    """Test SnowflakeConfig resource."""

    def test_snowflake_config_creation(self, test_snowflake_config):
        """Test that SnowflakeConfig can be created."""
        assert test_snowflake_config.account == "TEST_ACCOUNT"
        assert test_snowflake_config.database == "TEST_DB"
        assert test_snowflake_config.schema_raw == "TEST_RAW"

    def test_snowflake_config_validation(self):
        """Test that SnowflakeConfig validates required fields."""
        # Should raise error if required field is empty
        with pytest.raises(ValueError):
            SnowflakeConfig(
                account="",
                user="TEST_USER",
                warehouse="TEST_WH",
                role="TEST_ROLE",
                database="TEST_DB",
                schema_raw="TEST_RAW",
                stage="TEST_STAGE",
                authenticator="externalbrowser",
            )

    def test_snowflake_config_get_full_stage_path(self, test_snowflake_config):
        """Test get_full_stage_path method."""
        expected = "@TEST_DB.TEST_RAW.TEST_STAGE"
        assert test_snowflake_config.get_full_stage_path() == expected


class TestJobConfig:
    """Test JobConfig resource."""

    def test_job_config_creation(self, test_job_config):
        """Test that JobConfig can be created."""
        assert test_job_config.full_reload is False
        assert test_job_config.stage_location == "@TEST_DB.TEST_RAW.TEST_STAGE"
        assert test_job_config.filtered_fund_ids == []
        assert test_job_config.filtered_investor_ids == []

    def test_job_config_full_reload(self):
        """Test JobConfig with full_reload enabled."""
        config = JobConfig(
            full_reload=True,
            stage_location="@TEST_DB.TEST_RAW.TEST_STAGE",
            filtered_fund_ids=[],
            filtered_investor_ids=[],
        )
        assert config.full_reload is True
