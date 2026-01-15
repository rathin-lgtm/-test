# Testing Guide - HV EDP

## Overview

This document describes the testing infrastructure and practices for the HV EDP platform.

---

## Testing Stack

| Tool | Purpose | Scope |
|------|---------|-------|
| **pytest** | Python unit/integration tests | Dagster code |
| **dbt test** | Data quality tests | SQL models |
| **SQLFluff** | SQL linting/formatting | SQL files |
| **pre-commit** | Pre-commit hooks | All files |

---

## 1. SQL Testing (dbt)

### Built-in Tests

dbt provides built-in tests defined in YAML files:

```yaml
# models/silver/silver.yml
models:
  - name: hub_fund
    columns:
      - name: hk_fund
        data_tests:
          - not_null
          - unique
      - name: fund_id
        data_tests:
          - not_null
          - unique
```

**Common Tests:**
- `not_null` - Column cannot be NULL
- `unique` - Column values must be unique
- `relationships` - Foreign key relationships
- `accepted_values` - Column values in allowed list

### Custom Singular Tests

Custom SQL tests in `tests/` directory:

```sql
-- tests/vault/assert_hub_has_records.sql
SELECT 
    'hub_fund' as hub_name,
    COUNT(*) as record_count
FROM {{ ref('hub_fund') }}
HAVING COUNT(*) = 0
```

**Run tests:**
```bash
# All tests
dbt test --project-dir hv_edp_dbt

# Specific test
dbt test --project-dir hv_edp_dbt --select assert_hub_has_records

# Tests for specific model
dbt test --project-dir hv_edp_dbt --select hub_fund
```

### Test Coverage

**Current test files:**
- `tests/vault/assert_hub_has_records.sql` - Ensures hubs have data
- `tests/marts/assert_gold_metrics_have_data.sql` - Ensures gold layer has recent data

**Recommended additional tests:**
- Referential integrity between hubs and satellites
- Data freshness checks
- Business rule validations
- Metric calculation accuracy

---

## 2. SQL Linting (SQLFluff)

### Configuration

SQLFluff is configured in `.sqlfluff`:

```ini
[sqlfluff]
dialect = snowflake
templater = dbt
```

### Usage

**Lint SQL files:**
```bash
# Lint all models
sqlfluff lint hv_edp_dbt/models/ --dialect=snowflake --templater=dbt

# Lint specific file
sqlfluff lint hv_edp_dbt/models/silver/hub_fund.sql

# Auto-fix issues
sqlfluff fix hv_edp_dbt/models/silver/hub_fund.sql
```

**Pre-commit:**
SQLFluff runs automatically on commit (via pre-commit hooks)

**CI/CD:**
SQLFluff runs in the Validate stage of the pipeline

### Common Rules

| Rule | Description | Fix |
|------|-------------|-----|
| L010 | Keywords must be uppercase | `select` → `SELECT` |
| L014 | Identifiers must be lowercase | `Fund_ID` → `fund_id` |
| L030 | Function names must be uppercase | `count()` → `COUNT()` |
| L003 | Indentation | Auto-fixable |

---

## 3. Python Testing (pytest)

### Test Structure

```
tests/
├── __init__.py
├── conftest.py          # Shared fixtures
├── test_resources.py    # Resource tests
└── test_utils.py        # Utility function tests
```

### Running Tests

```bash
# All tests
pytest

# Specific test file
pytest tests/test_resources.py

# With coverage
pytest --cov=hv_edp_dagster --cov-report=html

# Verbose output
pytest -v
```

### Fixtures

Common fixtures in `conftest.py`:
- `test_snowflake_config` - Mock Snowflake config
- `test_job_config` - Mock job config
- `dbt_project_dir` - Path to dbt project
- `mock_dagster_context` - Mock Dagster context

### Example Test

```python
def test_snowflake_config_creation(test_snowflake_config):
    """Test that SnowflakeConfig can be created."""
    assert test_snowflake_config.account == "TEST_ACCOUNT"
    assert test_snowflake_config.database == "TEST_DB"
```

---

## 4. Pre-commit Hooks

### Setup

```bash
# Install hooks
pre-commit install

# Run manually
pre-commit run --all-files
```

### Hooks Enabled

1. **General:**
   - Trailing whitespace removal
   - End of file fixer
   - YAML validation
   - Large file detection
   - Merge conflict detection
   - Private key detection

2. **Python:**
   - `black` - Code formatting
   - `isort` - Import sorting
   - `flake8` - Linting

3. **SQL:**
   - `sqlfluff-lint` - SQL linting
   - `sqlfluff-fix` - SQL auto-fix

4. **Security:**
   - `detect-secrets` - Secret detection

---

## 5. CI/CD Testing

### Validate Stage

The CI/CD pipeline runs:

1. **Python Linting:**
   ```bash
   black --check hv_edp_dagster/
   flake8 hv_edp_dagster/
   isort --check-only hv_edp_dagster/
   ```

2. **SQL Validation:**
   ```bash
   dbt compile --project-dir hv_edp_dbt
   sqlfluff lint hv_edp_dbt/models/
   ```

3. **Python Tests:**
   ```bash
   pytest tests/ -v --cov=hv_edp_dagster
   ```

4. **dbt Tests:**
   ```bash
   dbt test --project-dir hv_edp_dbt
   ```

### Deployment Stages

Each deployment stage (Dev, UAT, Prod) runs:
- `dbt run` - Execute models
- `dbt test` - Run data quality tests

---

## 6. Test Best Practices

### SQL Tests

1. **Test Data Quality:**
   - NULL checks on required fields
   - Uniqueness constraints
   - Referential integrity

2. **Test Business Rules:**
   - Metric calculations
   - Data relationships
   - Data freshness

3. **Test Edge Cases:**
   - Empty tables
   - Boundary values
   - Data type validation

### Python Tests

1. **Unit Tests:**
   - Test individual functions
   - Mock external dependencies
   - Fast execution

2. **Integration Tests:**
   - Test component interactions
   - Use test database
   - Slower but more realistic

3. **Test Coverage:**
   - Aim for >80% coverage
   - Focus on critical paths
   - Don't test framework code

---

## 7. Running Tests Locally

### Full Test Suite

```bash
# Install dependencies
pip install -r requirements.txt

# Run all tests
pytest
dbt test --project-dir hv_edp_dbt

# Run with coverage
pytest --cov=hv_edp_dagster --cov-report=html
```

### Quick Checks

```bash
# Python linting
black --check hv_edp_dagster/
flake8 hv_edp_dagster/

# SQL linting
sqlfluff lint hv_edp_dbt/models/

# dbt compile (syntax check)
dbt compile --project-dir hv_edp_dbt
```

---

## 8. Adding New Tests

### SQL Test

1. Create file in `tests/` directory:
   ```sql
   -- tests/vault/test_hub_integrity.sql
   SELECT hk_fund
   FROM {{ ref('hub_fund') }}
   WHERE hk_fund IS NULL
   ```

2. Run test:
   ```bash
   dbt test --select test_hub_integrity
   ```

### Python Test

1. Create test file:
   ```python
   # tests/test_new_feature.py
   def test_new_feature():
       assert True
   ```

2. Run test:
   ```bash
   pytest tests/test_new_feature.py
   ```

---

## 9. Troubleshooting

### SQLFluff Errors

**Issue:** "Template rendering failed"
**Solution:** Ensure dbt project is configured correctly:
```bash
dbt deps --project-dir hv_edp_dbt
```

**Issue:** "Dialect not found"
**Solution:** Install SQLFluff with Snowflake dialect:
```bash
pip install sqlfluff[snowflake]
```

### pytest Errors

**Issue:** "Module not found"
**Solution:** Install in development mode:
```bash
pip install -e .
```

**Issue:** "Fixture not found"
**Solution:** Ensure `conftest.py` is in `tests/` directory

---

## 10. Test Metrics

### Coverage Goals

- **Python:** >80% code coverage
- **SQL:** All critical models tested
- **Data Quality:** All hubs, links, satellites have tests

### Monitoring

- CI/CD pipeline shows test results
- Coverage reports in `htmlcov/` directory
- dbt test results in `target/` directory

---

## References

- [pytest Documentation](https://docs.pytest.org/)
- [dbt Testing](https://docs.getdbt.com/docs/build/tests)
- [SQLFluff Documentation](https://docs.sqlfluff.com/)
- [Pre-commit Hooks](https://pre-commit.com/)
