SELECT
    as_of_date,
    attributes.efront_investor_id,
    investor_name,
    investor_group_id,
    investor_group_name,
    total_value_sales_amount as total_value_sales,
    net_asset_value_sales_amount as net_asset_value_sales,
    distribution_amount as investor_distribution,
    contribution_amount as investor_contribution,
    commitment_amount as investor_commitment,
    distribution_gain_amount as investor_distribution_gain,
    nav_total_running_sum as investor_nav_total_running_sum,
    contribution_total_running_sum as investor_contribution_total_running_sum,
    distribution_total_running_sum as investor_distribution_total_running_sum,
    unfunded_runninng_amount as unfunded,
    transfer_out_pnl_amount
FROM {{ ref('sat_investor_fund_metrics') }} metrics
JOIN {{ ref('link_investor_fund') }} link
    ON metrics.hk_link = link.hk_link
JOIN {{ ref('sat_investor_attributes') }} attributes
    ON attributes.hk_investor = link.hk_investor
ORDER BY as_of_date
