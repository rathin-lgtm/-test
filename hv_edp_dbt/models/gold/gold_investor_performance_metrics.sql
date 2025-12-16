SELECT
    metrics.as_of_date,
    attributes.efront_investor_id,
    investor_name,
    investor_group_id,
    investor_group_name,
    called_pct as investor_percent_called,
    distributed_pct as investor_percent_distributed,
    tvf_sales_rt as investor_tv_f_sales,
    tvpi_rt as investor_tv_c,
    unfunded_inception_to_date_amt as investor_unfunded,
    total_value_sales_amt as total_value_sales,
    net_asset_value_sales_amt as net_asset_value_sales,
    distribution_amt as investor_distribution,
    contribution_amt as investor_contribution,
    commitment_amt as investor_commitment,
    distribution_gain_amt as investor_distribution_gain,
    nav_total_running_sum as investor_nav_total_running_sum,
    contribution_total_running_sum as investor_contribution_total_running_sum,
    distribution_total_running_sum as investor_distribution_total_running_sum,
    unfunded_running_amt as unfunded,
    transfer_out_pnl_amt as transfer_out_pnl_amount
FROM {{ ref('sat_investor_fund_metrics') }} metrics
JOIN {{ ref('link_investor_fund') }} link
    ON metrics.hk_link = link.hk_link
JOIN {{ ref('sat_investor_attributes') }} attributes
    ON attributes.hk_investor = link.hk_investor
JOIN {{ ref('sat_investor_fund_performance') }} performance
    ON performance.hk_link = link.hk_link
    AND metrics.as_of_date = performance.as_of_date
ORDER BY as_of_date
