"""
Tests for utility functions.
"""
import pytest

from hv_edp_dagster.utils import get_dbt_project_dir, get_project_root


class TestUtils:
    """Test utility functions."""

    def test_get_project_root(self):
        """Test get_project_root returns correct path."""
        root = get_project_root()
        assert root.exists()
        assert root.name == "hv_test" or "hv_edp" in str(root)

    def test_get_dbt_project_dir(self):
        """Test get_dbt_project_dir returns correct path."""
        dbt_dir = get_dbt_project_dir()
        assert dbt_dir.exists()
        assert dbt_dir.name == "hv_edp_dbt"
        assert (dbt_dir / "dbt_project.yml").exists()
