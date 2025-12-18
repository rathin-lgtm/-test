with investor_metrics as (
    SELECT
        {{ to_date('investor_transactions.date_id') }} as as_of_date,
        investor_transactions.investor_name_id as investor_id,
        investor_transactions.fund_id,
        {{ investor_distribution('investor_transactions.metric_id', 'investor_transactions.amount')}} as distribution_amt,
        {{ investor_distribution_gain('investor_transactions.metric_id', 'investor_transactions.amount') }} as distribution_gain_amt,
        {{ investor_contribution_total('investor_transactions.metric_id', 'investor_transactions.amount') }} +
        {{ investor_contribution_adjustment('investor_transactions.metric_id', 'investor_transactions.amount') }} as contribution_amt,
        {{ investor_contribution_adjustment('investor_transactions.metric_id', 'investor_transactions.amount') }} +
        {{ investor_contribution_commitment_fund_currency('investor_transactions.metric_id', 'investor_transactions.amount') }} as commitment_amt,
        {{ investor_nav('investor_transactions.metric_id', 'investor_transactions.amount') }} +
        {{ investor_transfers('investor_transactions.metric_id', 'investor_transactions.amount', 'investor_transactions.is_transfered', 'investor_transactions.date_id', 'fund.lock_date_eqt') }} as net_asset_value_sales_amt,
        {{ investor_nav('investor_transactions.metric_id', 'investor_transactions.amount') }} +
        {{ investor_transfers('investor_transactions.metric_id', 'investor_transactions.amount', 'investor_transactions.is_transfered', 'investor_transactions.date_id', 'fund.lock_date_eqt') }} +
        {{ investor_distribution('investor_transactions.metric_id', 'investor_transactions.amount') }} as total_value_sales_amt,
        {{ investor_return_of_captial('investor_transactions.metric_id', 'investor_transactions.amount') }} as return_of_capital_amt,
        {{ running_sum_investor_nav('investor_transactions.metric_id', 'investor_transactions.amount', 'investor_transactions.date_id', 'fund.lock_date_eqt') }} as nav_total_running_sum,
        {{ running_sum_investor_contribution('investor_transactions.metric_id', 'investor_transactions.amount') }} as contribution_for_running_sum,
        {{ investor_distribution('investor_transactions.metric_id', 'investor_transactions.amount') }} as distribution_for_running_sum,
        {{ unfunded_running('investor_transactions.metric_id', 'investor_transactions.amount') }} as unfunded_running_amt,
        {{ transfer_out('investor_transactions.metric_id', 'investor_transactions.amount', 'investor_transactions.is_transfered') }} as transfer_out_pnl_amt
    FROM (
        SELECT * FROM {{ source('bronze_from_harborview_edw', 'fact_investor_transactions') }} WHERE exclude_transaction = 0
    ) investor_transactions
    JOIN {{ source('bronze_from_harborview_edw', 'dim_fund') }} fund
        ON investor_transactions.fund_id = fund.fund_id and fund.type <> 'Third Party Investor'
    GROUP BY as_of_date, investor_transactions.investor_name_id, investor_transactions.fund_id
),

final_metrics as (
    SELECT
        metrics.as_of_date,
        hk_link,
        {{ investor_rollup('distribution_amt') }} as distribution_amt,
        {{ investor_rollup('distribution_gain_amt') }} as distribution_gain_amt,
        {{ investor_rollup('contribution_amt') }} as contribution_amt,
        {{ investor_rollup('commitment_amt') }} as commitment_amt,
        {{ investor_rollup('net_asset_value_sales_amt') }} as net_asset_value_sales_amt,
        {{ investor_rollup('total_value_sales_amt') }} as total_value_sales_amt,
        {{ investor_rollup('return_of_capital_amt') }} as return_of_capital_amt,
        {{ investor_rollup('nav_total_running_sum') }} as nav_total_running_sum,
        {{ investor_rollup('contribution_for_running_sum') }} as contribution_total_running_sum,
        {{ investor_rollup('distribution_for_running_sum') }} as distribution_total_running_sum,
        {{ investor_rollup('unfunded_running_amt') }} as unfunded_running_amt,
        {{ investor_rollup('transfer_out_pnl_amt') }} as transfer_out_pnl_amt,
        CURRENT_TIMESTAMP() as load_dt
    FROM investor_metrics metrics
    JOIN {{ ref('link_investor_fund') }} link
        ON metrics.investor_id = link.investor_id
        AND metrics.fund_id = link.fund_id
    ORDER BY as_of_date
)

{{ append_hk_key_column('final_metrics') }}