with attributes as (
    SELECT 
        hub.hk_company,
        REPLACE(TRIM(company_broad.short_name), '"', '''') as company_name,
        currency.name as company_currency,
        CASE WHEN company_broad.is_public = 1 THEN 'PUBLIC' ELSE 'PRIVATE' END as company_status,
        company.business_desc as company_business_description,
        dim_geo.L1_description as company_geography_broad,
        dim_geo.L3_description as company_geography_country,
        company_hier.L1_description as company_industry_category,
        company_hier.L2_description as company_industry_broad,
        company_hier.L3_description as company_industry,
        CURRENT_TIMESTAMP() as load_dt
    FROM
        {{ ref('company') }} company
    LEFT JOIN {{ ref('company_broad') }} company_broad
        ON company.company_broad_id = company_broad.company_broad_id
    JOIN {{ ref('currency') }} currency
        ON company_broad.currency_id = currency.currency_id
    LEFT JOIN {{ ref('dim_hv_geography_hierarchy') }} dim_geo
        ON dim_geo.code = company.investment_geography_id
    LEFT JOIN {{ ref('dim_company_industry_hierarchy') }} company_hier
        ON company.industry_fine_code = company_hier.industry_fine_code
    JOIN {{ ref('hub_company') }} hub
        ON company.company_id = hub.company_id 
)

{{ append_hk_key_column('attributes') }}
