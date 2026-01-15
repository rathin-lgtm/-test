# Data Dictionary

## Overview

This document provides definitions for key business concepts and metrics used in the HV EDP platform.

## Core Entities

### Fund
An investment vehicle managed by a General Partner (GP) that pools capital from Limited Partners (LPs).

| Field | Description |
|-------|-------------|
| `fund_id` | Unique identifier for the fund |
| `fund_name` | Display name of the fund |
| `aiv_fund_group_id` | Parent AIV (Alternative Investment Vehicle) group |
| `currency_id` | Base currency for fund accounting |
| `lock_date` | Date after which transactions are locked |
| `type` | Fund type classification |

### Investor (LP)
A Limited Partner who commits capital to a fund.

| Field | Description |
|-------|-------------|
| `investor_id` | Unique identifier for the investor |
| `investor_name` | Display name |
| `parent_group_id` | Parent investor group (for affiliated LPs) |
| `region` | Geographic region |

### Portfolio
A collection of investments within a fund structure.

| Field | Description |
|-------|-------------|
| `portfolio_id` | Unique identifier |
| `portfolio_name` | Display name |
| `vintage_year` | Year the portfolio was established |
| `type_broad_id` | Broad categorization |

### Company
A portfolio company that receives investment from funds.

| Field | Description |
|-------|-------------|
| `company_id` | Unique identifier |
| `company_name` | Display name |
| `industry_id` | Industry classification |
| `geography_id` | Geographic location |

## Key Metrics

### Performance Ratios

| Metric | Formula | Description |
|--------|---------|-------------|
| **TVPI** | `(NAV + Distributions) / Contributions` | Total Value to Paid-In capital. Measures overall fund performance. |
| **DPI** | `Distributions / Contributions` | Distributions to Paid-In capital. Measures realized returns. |
| **RVPI** | `NAV / Contributions` | Residual Value to Paid-In capital. Measures unrealized value. |

### Internal Rate of Return (IRR)

IRR represents the discount rate that makes the net present value of all cashflows equal to zero.

| Period | Description |
|--------|-------------|
| **IRR (Inception)** | IRR from fund inception to reporting date |
| **IRR 1-Year** | Trailing 1-year IRR |
| **IRR 3-Year** | Trailing 3-year IRR |
| **IRR 5-Year** | Trailing 5-year IRR |
| **IRR 10-Year** | Trailing 10-year IRR |

### Cashflow Types

| Type | Metric IDs | Description |
|------|------------|-------------|
| **Contributions** | 12, 13, 14, 15, 16, 17, 18, 185, 214, 215 | Capital called from LPs |
| **Distributions** | 40-63 | Capital returned to LPs |
| **NAV** | Various (83-177, etc.) | Net Asset Value components |
| **Commitments** | 6, 319, 320, 321 | Total committed capital |

## Transaction Metrics

### Contribution Types
| Metric ID | Name |
|-----------|------|
| 12 | Capital Contribution |
| 13 | Interest Paid |
| 14 | Management Fee |
| 15 | Transfer In |
| 185 | Partnership Expense |
| 214 | Recycled Capital |
| 215 | Recallable Capital |

### Distribution Types
| Metric ID | Name |
|-----------|------|
| 40 | Return of Capital |
| 41 | Gain Distribution |
| 42 | Income Distribution |
| 43 | Return of Capital (FX) |
| 44 | Gain (FX Adjusted) |
| 49 | Carried Interest |

## Data Vault Components

### Hash Keys
All entities use SHA-256 hash keys for:
- Consistent joining across tables
- Handling NULL values
- Case-insensitive matching

Formula: `SHA256(UPPER(TRIM(business_key)))`

### Row Change Detection
Satellites use row-level hashing for change detection:
```sql
HEX_ENCODE(TO_CHAR(HASH(OBJECT_CONSTRUCT_KEEP_NULL(* EXCLUDE (load_dt)))))
```

### Record Source
All Data Vault records track their source file for:
- Data lineage
- Audit trails
- Troubleshooting

## Date Handling

### Date Formats
| Format | Usage |
|--------|-------|
| `YYYYMMDD` | Integer date keys (date_id) |
| `DATE` | Standard SQL DATE type |
| `TIMESTAMP` | Load timestamps (load_dt) |

### Lock Date Logic
- Transactions before lock_date: Include in calculations
- Transactions after lock_date: Excluded or handled specially
- Used for period-end reporting accuracy

## Currency Handling

- All amounts stored in their native currency
- `currency_id` links to currency reference
- Currency code (ISO 4217) for display
- Multi-currency reporting supported via metric_currency_code

## Sub-Perspective Views

Sub-perspectives allow different views of the same fund data:
- **Main View** (`fund_perspective_view_id = 3`): Standard fund view
- Geographic focus
- Investment strategy
- Investment period

## Blocked Funds

Some funds are excluded from reporting via `block_list_fund`:
- Terminated funds
- Test funds
- Funds under restructuring
