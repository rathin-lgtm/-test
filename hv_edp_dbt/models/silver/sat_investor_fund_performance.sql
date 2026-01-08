with investor_performance_metrics as (
    SELECT 
        {{ to_date('investor_transactions.date_id') }} as as_of_date,
        investor_transactions.investor_name_id as investor_id,
        investor_transactions.fund_id,
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
        {{ safe_division(
            [
                investor_distribution('investor_transactions.metric_id', 'investor_transactions.amount')
            ],
            [
                investor_contribution_total('investor_transactions.metric_id', 'investor_transactions.amount'),
                investor_contribution_adjustment('investor_transactions.metric_id', 'investor_transactions.amount')
            ]
            )
        }} as dc_sales_rt,
        {{ investor_nav('investor_transactions.metric_id', 'investor_transactions.amount') }} +
        {{ investor_transfers('investor_transactions.metric_id', 'investor_transactions.amount', 'investor_transactions.is_transfered', 'investor_transactions.date_id', 'fund.lock_date_eqt') }} +
        {{ investor_distribution('investor_transactions.metric_id', 'investor_transactions.amount') }} -
        {{ investor_contribution_total('investor_transactions.metric_id', 'investor_transactions.amount') }} as gain_loss_sales_amt,
    FROM (
        SELECT * FROM {{ source('bronze_from_harborview_edw', 'fact_investor_transactions') }} WHERE exclude_transaction = 0
    ) investor_transactions
    JOIN {{ source('bronze_from_harborview_edw', 'dim_fund') }} fund
        ON investor_transactions.fund_id = fund.fund_id and fund.type <> 'Third Party Investor'
    GROUP BY as_of_date, investor_transactions.investor_name_id, investor_transactions.fund_id
),

final_metrics as (
    SELECT
    as_of_date,
    hk_link,
    {{ investor_rollup('tvf_sales_rt') }} as tvf_sales_rt,
    {{ investor_rollup('tvpi_rt') }} as tvpi_rt,
    {{ investor_rollup('unfunded') }} as unfunded_inception_to_date_amt,
    i.irr as irr_sales_rt,
    i.irr_1_year as irr_1_year_sales_rt,
    i.irr_3_year as irr_3_year_sales_rt,
    i.irr_5_year as irr_5_year_sales_rt,
    i.irr_10_year as irr_10_year_sales_rt,
    {{ investor_rollup('dc_sales_rt') }} as dc_sales_rt,
    {{ investor_rollup('gain_loss_sales_amt') }} as gain_loss_sales_amt,
    CURRENT_TIMESTAMP() as load_dt,
    FROM investor_performance_metrics metrics
    JOIN {{ ref('link_investor_fund') }} link
        ON metrics.investor_id = link.investor_id
        AND metrics.fund_id = link.fund_id
    LEFT JOIN {{ ref('investor_fund_performance_irr_intermediate') }} i
       ON metrics.investor_id = i.investor_id
       AND metrics.fund_id = i.fund_id
        AND metrics.as_of_date = i.as_of_date1
    ORDER BY as_of_date
)

{{ append_hk_key_column('final_metrics') }}