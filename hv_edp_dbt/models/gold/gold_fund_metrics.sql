SELECT
    as_of_date,
    fund_id,
    efront_fund_id,
    fund_name,
    fund_sub_perspective_name,
    fund_currency,
    metric_currency_code as metric_currency,
    fund_lock_date,
    fund_investor_presentation_aiv,
    fund_investor_presentation_aiv_type_efront,
    fund_investor_presentation_aiv_lock_date,
    gain_loss,
    dpi,
    tvpi,
    irr,
    irr_1_year,
    irr_3_year,
    irr_5_year,
    irr_10_year,
    lp_nav as fund_lp_nav,
    lp_total_value as fund_lp_total_value,
    lp_commitments as fund_lp_commitments,
    lp_capital_called as fund_lp_capital_called,
    lp_contributions as fund_lp_contributions,
    lp_distributions as fund_lp_distributions
FROM {{ ref('sat_fund_metrics') }} m
JOIN {{ ref('sat_fund_attributes') }} a
    ON m.hk_fund = a.hk_fund
JOIN {{ ref('hub_fund') }} hub
    ON m.hk_fund = hub.hk_fund