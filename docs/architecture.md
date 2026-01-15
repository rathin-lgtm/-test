# HV EDP Architecture

## Overview

The HV Enterprise Data Platform (EDP) is a data engineering solution for private equity portfolio analytics. It combines modern data engineering practices with industry-standard methodologies.

## Technology Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Data Warehouse** | Snowflake | Cloud data platform |
| **Transformation** | dbt Core | SQL-based transformations |
| **Orchestration** | Dagster | Pipeline orchestration |
| **Source Data** | Parquet files | External stage ingestion |

## Data Architecture

### Medallion Architecture

The platform implements a three-layer medallion architecture:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│   STAGING (Bronze)          VAULT (Silver)           MARTS (Gold)          │
│   ─────────────────        ──────────────          ───────────────         │
│                                                                             │
│   • External Tables   ──▶  • Hubs (Entities)  ──▶  • Fund Metrics          │
│   • Base Dimensions        • Links (Relations)     • Portfolio Metrics     │
│   • Incremental Facts      • Satellites (Attrs)    • Investor Metrics      │
│                                                    • Company Metrics       │
│                                                                             │
│   Schema: *_RAW           Schema: *_SILVER        Schema: *_GOLD           │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Data Vault 2.0

The Silver layer implements Data Vault 2.0 methodology:

#### Hubs (Business Entities)
- **hub_fund**: Investment funds (main funds, AIVs, fund groups)
- **hub_investor**: Limited Partners/Investors
- **hub_portfolio**: Investment portfolios
- **hub_company**: Portfolio companies
- **hub_holding**: Individual holdings/positions

#### Links (Relationships)
- **link_portfolio_fund**: Portfolio ↔ Fund
- **link_fund_company**: Fund ↔ Company
- **link_investor_fund**: Investor ↔ Fund
- **link_fund_investor_transaction**: Transaction context

#### Satellites (Descriptive Data)
- **sat_*_attributes**: Slowly changing descriptive data
- **sat_*_metrics**: Point-in-time numeric measures

### Hash Key Strategy

All Data Vault components use consistent hashing:
```sql
SHA256(UPPER(TRIM(business_key)))
```

Row-level change detection uses:
```sql
HEX_ENCODE(TO_CHAR(HASH(OBJECT_CONSTRUCT_KEEP_NULL(*))))
```

## Data Flow

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Source EDW     │────▶│  External Stage │────▶│  External Table │
│  (Parquet)      │     │  (Snowflake)    │     │  (Bronze)       │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                        ┌───────────────────────────────┘
                        ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Data Vault     │────▶│  Gold Marts     │────▶│  Reporting      │
│  (Silver)       │     │  (Denormalized) │     │  (BI Tools)     │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

## Key Metrics

### Performance Metrics
| Metric | Description | Formula |
|--------|-------------|---------|
| **TVPI** | Total Value to Paid-In | (NAV + Distributions) / Contributions |
| **DPI** | Distributions to Paid-In | Distributions / Contributions |
| **IRR** | Internal Rate of Return | XIRR of cashflows |
| **MOIC** | Multiple on Invested Capital | Total Value / Invested Capital |

### Time Periods
IRR calculations support multiple lookback periods:
- Inception to Date
- 1-Year Trailing
- 3-Year Trailing
- 5-Year Trailing
- 10-Year Trailing

## Dagster Integration

### Asset Groups
- **raw**: External table staging
- **bronze**: dbt bronze models
- **silver**: dbt silver models
- **gold**: dbt gold models
- **provision_infra**: Infrastructure setup
- **destroy_infra**: Infrastructure cleanup

### Jobs
- **{model}_etl_job**: Per-gold-model ETL pipelines
- **provision_infra**: Create personal dev database
- **destroy_infra**: Drop personal dev database

### Sensors
- **File sensors**: Detect new data files
- **Cleanup sensors**: Connection management

## Environments

| Environment | Database | Deployment |
|-------------|----------|------------|
| `personal_dev` | `HV_EDP_{user}_DEV` | Manual |
| `shared_dev` | `HV_EDP_DEV` | CI/CD (develop) |
| `uat` | `HV_EDP_UAT` | CI/CD (release/*) |
| `prod` | `HV_EDP_PRD` | CI/CD (main) |

## Security

- Snowflake RBAC for access control
- Key-based authentication for service accounts
- Browser-based SSO for local development
- Environment-specific roles and permissions
