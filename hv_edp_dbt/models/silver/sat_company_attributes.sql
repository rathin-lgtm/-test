with attributes as (
    SELECT 
        company.company_id,
        company_broad.short_name as company_name,
        currency.name as company_currency,
        CASE WHEN company_broad.is_public = 1 THEN 'PUBLIC' ELSE 'PRIVATE' END as company_status,
        company.business_desc as company_exposure_business_description,
        dim_geo.L1_description as company_exposure_geography_broad,
        dim_geo.L3_description as company_exposure_geography_country,
        company_hier.L1_description as company_exposure_industry_category,
        company_hier.L2_description as company_exposure_industry_broad,
        company_hier.L3_description as company_exposure_industry,
        CURRENT_TIMESTAMP() as load_dt
    FROM
        {{ source('bronze_from_harborview_edw', 'company') }} company
    LEFT JOIN {{ source('bronze_from_harborview_edw', 'company_broad') }} company_broad
        ON company.company_broad_id = company_broad.company_broad_id
    JOIN {{ source('bronze_from_harborview_edw', 'currency') }} currency
        ON company_broad.currency_id = currency.currency_id
    LEFT JOIN {{ source('bronze_from_harborview_edw', 'dim_hv_geography_hierarchy') }} dim_geo
        ON dim_geo.code = company.investment_geography_id
    LEFT JOIN {{ source('bronze_from_harborview_edw', 'dim_company_industry_hierarchy') }} company_hier
        ON company.industry_fine_code = company_hier.industry_fine_code
)

SELECT
{{ hk('company_id') }} as hk_company,
company_name,
company_currency,
company_status,
company_exposure_business_description,
company_exposure_geography_broad,
company_exposure_geography_country,
company_exposure_industry_category,
company_exposure_industry_broad,
company_exposure_industry,
{{ encoded_hashed_row() }} as skey
FROM attributes
