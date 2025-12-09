with investor_metrics as (
    SELECT
        {{ to_date('investor_transactions.date_id') }} as as_of_date,
        investor_transactions.investor_name_id as investor_id,
        investor_transactions.fund_id,
        {{ investor_distribution('investor_transactions.metric_id', 'investor_transactions.amount')}} as investor_distribution,
        {{ investor_distribution_gain('investor_transactions.metric_id', 'investor_transactions.amount') }} as investor_distribution_gain,
        {{ investor_contribution_total('investor_transactions.metric_id', 'investor_transactions.amount') }} +
        {{ investor_contribution_adjustment('investor_transactions.metric_id', 'investor_transactions.amount') }} as investor_contribution,
        {{ investor_contribution_adjustment('investor_transactions.metric_id', 'investor_transactions.amount') }} +
        {{ investor_contribution_commitment_fund_currency('investor_transactions.metric_id', 'investor_transactions.amount') }} as investor_commitment,
        {{ investor_nav('investor_transactions.metric_id', 'investor_transactions.amount') }} +
        {{ investor_transfers('investor_transactions.metric_id', 'investor_transactions.amount', 'investor_transactions.is_transfered', 'investor_transactions.date_id', 'fund.lock_date_eqt') }} as net_asset_value_sales,
        {{ investor_nav('investor_transactions.metric_id', 'investor_transactions.amount') }} +
        {{ investor_transfers('investor_transactions.metric_id', 'investor_transactions.amount', 'investor_transactions.is_transfered', 'investor_transactions.date_id', 'fund.lock_date_eqt') }} +
        {{ investor_distribution('investor_transactions.metric_id', 'investor_transactions.amount') }} as total_value_sales,
        {{ running_sum_investor_nav('investor_transactions.metric_id', 'investor_transactions.amount', 'investor_transactions.date_id', 'fund.lock_date_eqt') }} as investor_nav_total_running_sum,
        {{ running_sum_investor_contribution('investor_transactions.metric_id', 'investor_transactions.amount') }} as investor_contribution_total_running_sum,
        {{ running_sum_investor_distribution('investor_transactions.metric_id', 'investor_transactions.amount') }} as investor_distribution_total_running_sum,
        {{ unfunded_running('investor_transactions.metric_id', 'investor_transactions.amount') }} as unfunded_runninng_amount,
        {{ transfer_out('investor_transactions.metric_id', 'investor_transactions.amount', 'investor_transactions.is_transfered') }} as transfer_out_pnl_amount
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
        investor_distribution,
        investor_distribution_gain,
        investor_contribution,
        investor_commitment,
        net_asset_value_sales,
        total_value_sales,
        investor_nav_total_running_sum,
        investor_contribution_total_running_sum,
        investor_distribution_total_running_sum,
        unfunded_runninng_amount,
        transfer_out_pnl_amount,
        CURRENT_TIMESTAMP() as load_dt
    FROM investor_metrics metrics
    JOIN {{ ref('link_investor_fund') }} link
        ON metrics.investor_id = link.investor_id
        AND metrics.fund_id = link.fund_id
    ORDER BY as_of_date
)

{{ append_hk_key_column('final_metrics') }}