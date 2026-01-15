# Operations Runbook

## Daily Operations

### Monitoring

1. **Check Dagster Dashboard**
   - View run history at http://dagster-host:3000
   - Look for failed runs
   - Check sensor status

2. **Review dbt Tests**
   - Test results in run artifacts
   - Focus on data quality failures

### Common Issues

#### 1. Sensor Not Detecting Files

**Symptoms:**
- No new runs triggered
- Files present in stage

**Resolution:**
```sql
-- Check files in stage
LIST @DATABASE.SCHEMA.STAGE/path/;

-- Verify file naming pattern
-- Files should match: .*.parquet$
```

#### 2. dbt Model Failure

**Symptoms:**
- Run fails during dbt execution
- Error in compiled SQL

**Resolution:**
1. Check Dagster logs for compiled SQL
2. Run locally to debug:
   ```bash
   dbt run --select model_name --target personal_dev
   ```
3. Check for upstream data issues

#### 3. IRR Calculation Errors

**Symptoms:**
- NULL IRR values
- IRR UDF errors

**Resolution:**
- Verify `create_xirr_udf` pre-hook ran
- Check for invalid cashflow data (all zeros, missing dates)
- UDF requires at least one negative and one positive cashflow

## Manual Operations

### Full Data Reload

```bash
# Via Dagster
# 1. Open job launchpad
# 2. Set full_reload: true
# 3. Launch job

# Via dbt CLI
dbt run --full-refresh --project-dir hv_edp_dbt --target shared_dev
```

### Backfill Specific Date Range

```sql
-- Manually insert records for backfill
-- Then run incremental models
```

### Schema Changes

1. Update dbt model
2. Run `dbt compile` to validate
3. For breaking changes:
   - Coordinate with downstream consumers
   - Consider blue-green deployment

## Personal Dev Environment

### Setup
```bash
# Start Dagster
dagster dev

# Run provision_infra job
# Creates: HV_EDP_{username}_DEV database
```

### Teardown
```bash
# Run destroy_infra job
# Drops personal database
```

### Filtered Runs
```bash
# Set in .env for faster testing
FILTERED_FUND_IDS=28885567,2216520
FILTERED_INVESTOR_IDS=58256296,2215327
```

## Emergency Procedures

### Rollback Production

1. **Identify last good state**
   ```sql
   -- Check metadata tables for last successful run
   ```

2. **Revert code**
   ```bash
   git revert <commit>
   git push origin main
   ```

3. **Full refresh if needed**
   - Set `full_reload: true`
   - Re-run pipeline

### Data Corruption

1. **Isolate affected tables**
2. **Restore from backup (if available)**
3. **Or full refresh from source**

### Performance Issues

1. **Check Snowflake warehouse**
   ```sql
   SHOW WAREHOUSES;
   -- Scale up if needed
   ALTER WAREHOUSE wh_name SET WAREHOUSE_SIZE = 'XLARGE';
   ```

2. **Review query history**
   ```sql
   SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
   WHERE START_TIME > DATEADD(hour, -1, CURRENT_TIMESTAMP())
   ORDER BY TOTAL_ELAPSED_TIME DESC
   LIMIT 20;
   ```

## Contacts

| Role | Contact |
|------|---------|
| Data Engineering | data-engineering@company.com |
| On-Call | PagerDuty rotation |
| Snowflake Admin | snowflake-admin@company.com |

## Maintenance Windows

- **Snowflake**: Sundays 2-4 AM UTC (automatic)
- **Dagster**: Monthly updates (coordinated)
- **Code Deployments**: Business hours with notification
