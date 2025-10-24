SELECT
    as_of_date,
    efront_fund_id,
    fund_name,
    fund_currency,
    fund_lock_date,
    fund_investor_presentation_aiv,
    fund_investor_presentation_aiv_type_efront,
    fund_investor_presentation_aiv_lock_date,
    lp_nav as fund_lp_nav,
    lp_total_value as fund_lp_total_value,
    lp_commitments as fund_lp_commitments,
    lp_capital_called as fund_lp_capital_called,
    lp_contributions as fund_lp_contributions,
    lp_distributions as fund_lp_distributions
FROM {{ ref('sat_fund_metrics') }} m
JOIN {{ ref('hub_fund') }} f
    ON m.hk_fund = f.hk_fund
JOIN {{ ref('sat_fund_attributes') }} a
    ON m.hk_fund = a.hk_fund
