# HV Enterprise Data Platform (EDP)

A data engineering platform for private equity portfolio analytics, built with **dbt** and **Dagster** on **Snowflake**.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           HARBOURVIEW EDP                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌──────────────┐    ┌──────────────┐    ┌──────────────┐                 │
│   │   STAGING    │    │    VAULT     │    │    MARTS     │                 │
│   │   (Bronze)   │───▶│   (Silver)   │───▶│    (Gold)    │                 │
│   │              │    │              │    │              │                 │
│   │ • External   │    │ • Hubs       │    │ • Finance    │                 │
│   │   Tables     │    │ • Links      │    │ • Reporting  │                 │
│   │ • Base dims  │    │ • Satellites │    │              │                 │
│   │ • Incr facts │    │              │    │              │                 │
│   └──────────────┘    └──────────────┘    └──────────────┘                 │
│         ▲                                                                   │
│         │                                                                   │
│   ┌─────┴────────────────────────────────────────────────┐                 │
│   │              Snowflake External Stage                │                 │
│   │         (Parquet files from EDW)                     │                 │
│   └──────────────────────────────────────────────────────┘                 │
│                                                                             │
│   ┌──────────────────────────────────────────────────────┐                 │
│   │                    DAGSTER                           │                 │
│   │  • Asset orchestration                               │                 │
│   │  • File sensors                                      │                 │
│   │  • Infrastructure provisioning                       │                 │
│   └──────────────────────────────────────────────────────┘                 │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Data Layers

| Layer | Schema | Description |
|-------|--------|-------------|
| **Staging** | `*_RAW` | Raw data from external sources. Minimal transformation. |
| **Vault** | `*_SILVER` | Data Vault 2.0 model (Hubs, Links, Satellites) |
| **Marts** | `*_GOLD` | Business-ready analytics tables |

## Quick Start

### Prerequisites

- Python 3.12+
- Access to Snowflake with appropriate roles
- Git

### Setup

1. **Clone the repository**
   ```bash
   git clone <repo-url>
   cd hv_edp
   ```

2. **Create virtual environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # Linux/Mac
   # OR
   .\venv\Scripts\activate   # Windows PowerShell
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your credentials
   ```

5. **Install dbt packages**
   ```bash
   dbt deps --project-dir dbt
   ```

6. **Install pre-commit hooks**
   ```bash
   pre-commit install
   ```

### Environment Variables

Create a `.env` file in the root directory:

```env
# Snowflake Connection
SNOWFLAKE_ACCOUNT=HVPLP-ACCTCDPNP
SNOWFLAKE_USER=your.email@company.com
SNOWFLAKE_WH=KRTSYSNP_WAREHOUSE
SNOWFLAKE_ROLE=_OKTA-SF_JAMLABS_DEV

# Environment (personal_dev | shared_dev | uat | prod)
ENVIRONMENT=personal_dev

# Dagster
DAGSTER_HOME=/path/to/repo

# Optional: Filter for faster local runs
FILTERED_FUND_IDS=28885567,2216520
FILTERED_INVESTOR_IDS=58256296,2215327
```

## Running Locally

### Start Dagster UI

```bash
dagster dev
```

Access at: http://127.0.0.1:3000

### Running dbt Directly

```bash
# Run all models
dbt run --project-dir dbt

# Run specific layer
dbt run --project-dir dbt --select staging.*
dbt run --project-dir dbt --select vault.*
dbt run --project-dir dbt --select marts.*

# Run tests
dbt test --project-dir dbt

# Generate docs
dbt docs generate --project-dir dbt
dbt docs serve --project-dir dbt
```

## Development Workflow

### Personal Development Environment

1. Start Dagster: `dagster dev`
2. Run **provision_infra** job to create your personal database
3. Run ETL jobs to load data
4. When done, run **destroy_infra** job to clean up

### Job Configuration

ETL jobs support these options (via Dagster launchpad):

| Option | Default | Description |
|--------|---------|-------------|
| `full_reload` | `false` | Full refresh all tables |
| `stage_location` | auto | Override stage path |
| `filtered_fund_ids` | from env | Filter funds for faster runs |
| `filtered_investor_ids` | from env | Filter investors for faster runs |

## Project Structure

```
hv_edp/
├── dagster/              # Dagster orchestration
│   ├── assets/           # Asset definitions
│   ├── jobs/             # Job definitions
│   ├── resources/        # Resource configurations
│   └── sensors/          # File and run sensors
│
├── dbt/                  # dbt project
│   ├── models/
│   │   ├── staging/      # Bronze layer (raw data)
│   │   ├── vault/        # Silver layer (Data Vault)
│   │   └── marts/        # Gold layer (business marts)
│   ├── macros/           # Reusable SQL logic
│   ├── tests/            # Data quality tests
│   └── seeds/            # Static reference data
│
├── tests/                # Python unit tests
└── docs/                 # Documentation
```

## Data Vault Model

### Entities (Hubs)
- `hub_fund` - Investment funds
- `hub_investor` - Investors/LPs
- `hub_portfolio` - Portfolios
- `hub_company` - Portfolio companies
- `hub_holding` - Holdings

### Relationships (Links)
- `link_portfolio_fund` - Portfolio ↔ Fund
- `link_fund_company` - Fund ↔ Company
- `link_investor_fund` - Investor ↔ Fund
- `link_fund_investor_transaction` - Transaction relationships

### Descriptors (Satellites)
- `sat_*_attributes` - Slowly changing descriptive data
- `sat_*_metrics` - Point-in-time metrics

## Testing

### dbt Tests
```bash
# Run all tests
dbt test --project-dir dbt

# Run tests for specific model
dbt test --project-dir dbt --select hub_fund
```

### Python Tests
```bash
pytest tests/
```

## Deployment

| Environment | Database | Trigger |
|-------------|----------|---------|
| `personal_dev` | `HV_EDP_{username}_DEV` | Manual |
| `shared_dev` | `HV_EDP_DEV` | PR merge to `develop` |
| `uat` | `HV_EDP_UAT` | PR merge to `release/*` |
| `prod` | `HV_EDP_PRD` | PR merge to `main` |

## Contributing

1. Create feature branch from `develop`
2. Make changes
3. Run tests locally
4. Submit PR
5. Ensure CI passes
6. Get code review

## Support

For questions or issues, contact the Data Engineering team.
