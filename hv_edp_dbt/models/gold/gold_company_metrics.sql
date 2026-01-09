SELECT
    metrics.as_of_date as as_of_date,
    fund_attributes.efront_fund_id,
    link.company_id,
    company.company_name as company_name,
    metric_currency_code as metric_currency,
    company.company_currency as company_currency,
    company.company_business_description as company_exposure_business_description,
    company.company_geography_broad as company_exposure_geography_broad,
    company.company_geography_country as company_exposure_geography_country,
    company.company_industry_category as company_exposure_industry_category,
    company.company_industry_broad as company_exposure_industry_broad,
    company.company_industry as company_exposure_industry,
    company.company_status as company_status,
    company_original.company_geography_country as original_company_country,
    company_original.company_geography_broad as original_company_geography_broad,
    company_original.company_industry_category as original_company_industry_category,
    company_original.company_industry_broad as original_company_industry_broad,
    company_original.company_industry as original_company_industry,
    investment_attributes.company_investment_year as company_investment_year,
    investment_attributes.company_investment_type as company_investment_type,
    investment_attributes.company_public_status as company_public_status,
    investment_attributes.company_stage as company_exposure_stage,
    investment_attributes.company_stage_broad as company_exposure_stage_broad,
    realized_value as company_realized_value,
    total_value as company_total_value,
    total_cost as company_total_cost,
    gain_loss as company_gain_loss,
    current_value as company_current_value,
    tvtc as company_tvtc
FROM {{ ref('sat_company_metrics') }} metrics
JOIN {{ ref('sat_company_attributes') }} company
    ON metrics.hk_company = company.hk_company
JOIN {{ ref('sat_company_attributes') }} company_original
    ON metrics.hk_company_original = company_original.hk_company
JOIN {{ ref('sat_fund_company_investment_attributes') }} investment_attributes
    ON metrics.hk_link = investment_attributes.hk_link
    AND metrics.as_of_date = investment_attributes.as_of_date
JOIN {{ ref('link_fund_company') }} link
    ON metrics.hk_link = link.hk_link
JOIN {{ ref('sat_fund_attributes') }} fund_attributes
    ON link.hk_fund = fund_attributes.hk_fund