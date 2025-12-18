SELECT
    link.hk_link,
    metrics.as_of_date,
    attributes.efront_investor_id,
    short_name as investor_name,
    parent_group_id as investor_group_id,
    parent_group_name as investor_group_name,
    region as investor_region,
    called_pct as investor_percent_called,
    distributed_pct as investor_percent_distributed,
    tvf_sales_rt as investor_tv_f_sales,
    tvpi_rt as investor_tv_c,
    unfunded_inception_to_date_amt as investor_unfunded,
    total_value_sales_amt as total_value_sales,
    return_of_capital_amt as investor_return_of_captial,
    net_asset_value_sales_amt as net_asset_value_sales,
    distribution_amt as investor_distribution,
    contribution_amt as investor_contribution,
    commitment_amt as investor_commitment,
    distribution_gain_amt as investor_distribution_gain,
    nav_total_running_sum as investor_nav_total_running_sum,
    contribution_total_running_sum as investor_contribution_total_running_sum,
    distribution_total_running_sum as investor_distribution_total_running_sum,
    unfunded_running_amt as unfunded,
    transfer_out_pnl_amt as transfer_out_pnl_amount,
    performance.irr_1_year_sales_rt as investor_irr_sales,
    performance.irr_1_year_sales_rt as investor_irr_sales_1_year,
    performance.irr_3_year_sales_rt as investor_irr_sales_3_year,
    performance.irr_5_year_sales_rt as investor_irr_sales_5_year,
    performance.irr_10_year_sales_rt as investor_irr_sales_10_year
FROM {{ ref('sat_investor_fund_metrics') }} metrics
JOIN {{ ref('link_investor_fund') }} link
    ON metrics.hk_link = link.hk_link
JOIN {{ ref('sat_investor_attributes') }} attributes
    ON attributes.hk_investor = link.hk_investor
JOIN {{ ref('sat_investor_fund_performance') }} performance
    ON performance.hk_link = link.hk_link
    AND metrics.as_of_date = performance.as_of_date
ORDER BY as_of_date
