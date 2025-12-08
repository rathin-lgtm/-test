SELECT
    as_of_date,
    portfolio_id,
    fund_attributes.efront_fund_id,
    portfolio_name,
    portfolio_close_year,
    portfolio_disclosure_level,
    portfolio_commitment_year,
    metric_currency_code as metric_currency,
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
JOIN {{ ref('sat_portfolio_attributes') }} attributes
    ON metrics.hk_link = attributes.hk_link
JOIN {{ ref('link_portfolio_fund') }} link
    ON metrics.hk_link = link.hk_link
JOIN {{ ref('sat_fund_attributes') }} fund_attributes
    ON link.hk_fund = fund_attributes.hk_fund