with investor_performance_metrics as (
    SELECT 
        {{ to_date('investor_transactions.date_id') }} as as_of_date,
        investor_transactions.investor_name_id as investor_id,
        investor_transactions.fund_id,
        {{ safe_division(
            [
                investor_capital_called_excludes_total_transfers_transaction('investor_transactions.metric_id', 'investor_transactions.amount')
            ],
            [
                investor_contribution_cap_components('investor_transactions.metric_id', 'investor_transactions.amount'), 
                investor_transaction_unfunded('investor_transactions.metric_id', 'investor_transactions.amount')
            ]
            ) 
        }} as called_pct,
        {{ safe_division(
            [
                investor_distribution('investor_transactions.metric_id', 'investor_transactions.amount')
            ],
            [
                investor_contribution_total('investor_transactions.metric_id', 'investor_transactions.amount'),
                investor_contribution_adjustment_transaction('investor_transactions.metric_id', 'investor_transactions.amount')
            ]
            ) 
        }} as distributed_pct,
        {{ safe_division(
            [
                investor_nav('investor_transactions.metric_id', 'investor_transactions.amount'),
                investor_transfers('investor_transactions.metric_id', 'investor_transactions.amount', 'investor_transactions.is_transfered', 'investor_transactions.date_id', 'fund.lock_date_eqt'),
                investor_distribution('investor_transactions.metric_id', 'investor_transactions.amount')
            ],
            [
                investor_contribution_total('investor_transactions.metric_id', 'investor_transactions.amount'),
                investor_distribution_adjustment_transaction('investor_transactions.metric_id', 'investor_transactions.amount'),
                investor_transfer_of_interest_nav_total('investor_transactions.metric_id', 'investor_transactions.amount', 'investor_transactions.is_transfered', 'investor_transactions.is_transfer_within_group')
            ]
            ) 
        }} as tvf_sales_rt,
        {{ safe_division(
            [
                investor_nav_in_lock_date('investor_transactions.metric_id', 'investor_transactions.amount', 'investor_transactions.date_id', 'fund.lock_date_eqt'),
                investor_distribution('investor_transactions.metric_id', 'investor_transactions.amount')
            ],
            [
                investor_contribution_cap_components('investor_transactions.metric_id', 'investor_transactions.amount'),
                investor_contribution_adjustment('investor_transactions.metric_id', 'investor_transactions.amount')
            ]
            ) 
        }} as tvpi_rt,
        {{ investor_contribution_commitment_fund_currency('investor_transactions.metric_id', 'investor_transactions.amount') }} +
        {{ investor_contribution_cap_components('investor_transactions.metric_id', 'investor_transactions.amount') }} as unfunded,
    FROM (
        SELECT * FROM {{ ref('fact_investor_transactions') }} WHERE exclude_transaction = 0
    ) investor_transactions
    JOIN {{ ref('dim_fund') }} fund
        ON investor_transactions.fund_id = fund.fund_id and fund.type <> 'Third Party Investor'
    GROUP BY as_of_date, investor_transactions.investor_name_id, investor_transactions.fund_id
),

final_metrics as (
    SELECT
    as_of_date,
    hk_link,
    {{ investor_rollup('called_pct') }} as called_pct,
    {{ investor_rollup('distributed_pct') }} as distributed_pct,
    {{ investor_rollup('tvf_sales_rt') }} as tvf_sales_rt,
    {{ investor_rollup('tvpi_rt') }} as tvpi_rt,
    {{ investor_rollup('unfunded') }} as unfunded_inception_to_date_amt,
    CURRENT_TIMESTAMP() as load_dt,
    FROM investor_performance_metrics metrics
    JOIN {{ ref('link_investor_fund') }} link
        ON metrics.investor_id = link.investor_id
        AND metrics.fund_id = link.fund_id
    ORDER BY as_of_date
)

{{ append_hk_key_column('final_metrics') }}