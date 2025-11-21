with holding_metrics as (
    SELECT
        {{ to_date('transactions_monthly.date_id')}} as as_of_date,
        transactions_monthly.holding_id,
        transactions_monthly.fund_id,
        currency.currency_code,
        {{ holding_commitment('transactions_monthly.metric_id', 'transactions_monthly.running_monthly_amount', 'transactions_monthly.currency_id', 'transactions_monthly.investment_currency_id') }} as holding_commitment_unlevered
    FROM (
        SELECT * FROM {{ source('bronze_from_harborview_edw', 'fact_investment_transactions_fund_hierarchy_monthly') }} WHERE date_flag in ('B', 'E') and holding_id != -1
    ) transactions_monthly
    JOIN {{ source('bronze_from_harborview_edw', 'currency') }} currency
        ON transactions_monthly.currency_id = currency.currency_id
    JOIN {{ source('bronze_from_harborview_edw', 'dim_fund_hierarchy') }} dim_hierarchy
        ON transactions_monthly.fund_hier_id = dim_hierarchy.fund_hier_id and is_excluded = 0
    GROUP BY as_of_date, transactions_monthly.holding_id, currency_code, transactions_monthly.fund_id
),

final_metrics as (
    SELECT
        monthly.as_of_date,
        hub.hk_holding,
        monthly.fund_id,
        monthly.currency_code as metric_currency_code,
        COALESCE(monthly.holding_commitment_unlevered,0) as holding_commitment_unlevered,
        CURRENT_TIMESTAMP() as load_dt
    FROM holding_metrics monthly
    JOIN {{ ref('hub_holding') }} hub
        ON monthly.holding_id = hub.holding_id
    ORDER BY as_of_date
)

{{ append_hk_key_column('final_metrics') }}