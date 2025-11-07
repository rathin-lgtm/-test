SELECT
    as_of_date,
    portfolio_name,
    portfolio_close_year,
    portfolio_commitment_year,
    portfolio_currency,
    portfolio_manager,
    portfolio_geography,
    portfolio_geography_broad,
    portfolio_geography_l3,
    portfolio_geography_l5,
    portfolio_industry,
    portfolio_industry_l1,
    portfolio_stage,
    portfolio_stage_broad,
    portfolio_entity_status as portfolio_status, 
    type_broad_desc as portfolio_type_broad,
    portfolio_vintage_year,
    tvpi as portfolio_tv_f,
    total_value as portfolio_total_value,
    nav as portfolio_nav,
    irr as portfolio_irr,
    gain_loss as portfolio_gain_loss,
    distributions as portfolio_distributions,
    dpi as portfolio_d_f,
    commitments as portfolio_commitments,
    calls as portfolio_calls
FROM {{ ref('sat_portfolio_metrics') }} metrics
JOIN {{ ref('hub_portfolio') }} hub
    ON metrics.hk_portfolio = hub.hk_portfolio
JOIN {{ ref('sat_portfolio_attributes') }} attributes
    ON metrics.hk_portfolio = attributes.hk_portfolio
    AND metrics.fund_id = attributes.fund_id
ORDER BY as_of_date
