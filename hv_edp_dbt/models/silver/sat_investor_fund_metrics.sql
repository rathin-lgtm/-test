with investor_metrics as (
    SELECT
        {{ to_date('investor_transactions.date_id') }} as as_of_date,
        investor_transactions.investor_name_id as investor_id,
        investor_transactions.fund_id,
        {{ investor_distribution('investor_transactions.metric_id', 'investor_transactions.amount')}} as distribution_amount,
        {{ investor_distribution_gain('investor_transactions.metric_id', 'investor_transactions.amount') }} as distribution_gain_amount,
        {{ investor_contribution_total('investor_transactions.metric_id', 'investor_transactions.amount') }} +
        {{ investor_contribution_adjustment('investor_transactions.metric_id', 'investor_transactions.amount') }} as contribution_amount,
        {{ investor_contribution_adjustment('investor_transactions.metric_id', 'investor_transactions.amount') }} +
        {{ investor_contribution_commitment_fund_currency('investor_transactions.metric_id', 'investor_transactions.amount') }} as commitment_amount,
        {{ investor_nav('investor_transactions.metric_id', 'investor_transactions.amount') }} +
        {{ investor_transfers('investor_transactions.metric_id', 'investor_transactions.amount', 'investor_transactions.is_transfered', 'investor_transactions.date_id', 'fund.lock_date_eqt') }} as net_asset_value_sales_amount,
        {{ investor_nav('investor_transactions.metric_id', 'investor_transactions.amount') }} +
        {{ investor_transfers('investor_transactions.metric_id', 'investor_transactions.amount', 'investor_transactions.is_transfered', 'investor_transactions.date_id', 'fund.lock_date_eqt') }} +
        {{ investor_distribution('investor_transactions.metric_id', 'investor_transactions.amount') }} as total_value_sales_amount,
        {{ running_sum_investor_nav('investor_transactions.metric_id', 'investor_transactions.amount', 'investor_transactions.date_id', 'fund.lock_date_eqt') }} as nav_total_running_sum,
        {{ running_sum_investor_contribution('investor_transactions.metric_id', 'investor_transactions.amount') }} as contribution_for_running_sum, -- did not use pexisting contribution macro because of difference in metric_ids
        {{ investor_distribution('investor_transactions.metric_id', 'investor_transactions.amount') }} as distribution_for_running_sum, -- same ids so used existing distribution macro
        {{ unfunded_running('investor_transactions.metric_id', 'investor_transactions.amount') }} as unfunded_for_runninng_sum, -- did not use pexisting contribution macro because of difference in metric_ids
        {{ transfer_out('investor_transactions.metric_id', 'investor_transactions.amount', 'investor_transactions.is_transfered') }} as transfer_out_pnl_amount_for_running_sum
    FROM (
        SELECT * FROM {{ source('raw_from_harborview_edw', 'fact_investor_transactions') }} WHERE exclude_transaction = 0
    ) investor_transactions
    JOIN {{ source('raw_from_harborview_edw', 'dim_fund') }} fund
        ON investor_transactions.fund_id = fund.fund_id and fund.type <> 'Third Party Investor'
    GROUP BY as_of_date, investor_transactions.investor_name_id, investor_transactions.fund_id
),

final_metrics as (
    SELECT
        metrics.as_of_date,
        hk_link,
        distribution_amount,
        distribution_gain_amount,
        contribution_amount,
        commitment_amount,
        net_asset_value_sales_amount,
        total_value_sales_amount,
        nav_total_running_sum,
        SUM(contribution_for_running_sum) OVER(
            PARTITION BY hk_link ORDER BY metrics.as_of_date ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS contribution_total_running_sum,
        SUM(distribution_for_running_sum) OVER(
            PARTITION BY hk_link ORDER BY metrics.as_of_date ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS distribution_total_running_sum,
        SUM(unfunded_for_runninng_sum) OVER(
            PARTITION BY hk_link ORDER BY metrics.as_of_date ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS unfunded_runninng_amount,
        SUM(transfer_out_pnl_amount_for_running_sum) OVER(
            PARTITION BY hk_link ORDER BY metrics.as_of_date ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS transfer_out_pnl_amount,
        CURRENT_TIMESTAMP() as load_dt
    FROM investor_metrics metrics
    JOIN {{ ref('link_investor_fund') }} link
        ON metrics.investor_id = link.investor_id
        AND metrics.fund_id = link.fund_id
    ORDER BY as_of_date
)

{{ append_hk_key_column('final_metrics') }}