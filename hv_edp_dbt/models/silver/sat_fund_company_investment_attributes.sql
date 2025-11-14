with attributes as (
    SELECT
        hk_link,
        {{ to_date('date_id') }} as date,
        company_valuation.company_id,
        company_valuation.fund_id,
        investment_year as company_exposure_investment_year,
        investment_type.investment_type_desc as company_exposure_investment_type,
        {{ indicator_yes_no('public_status') }} as company_exposure_public_status,
        stage.description as company_exposure_stage,
        l1_stage.description as company_exposure_stage_broad,
        CURRENT_TIMESTAMP() as load_dt
    FROM  (SELECT distinct date_id, company_id, fund_id, investment_year, investment_type_id, public_status, stage_id from {{ source('bronze_from_harborview_edw', 'fact_company_valuation') }} ) company_valuation
    LEFT JOIN {{ source('bronze_from_harborview_edw', 'dim_investment_type') }} investment_type
        ON company_valuation.investment_type_id = investment_type.investment_type_id
    LEFT JOIN {{ source('bronze_from_harborview_edw', 'stage') }} stage
        ON stage.stage_code = company_valuation.stage_id 
    LEFT JOIN {{ source('bronze_from_harborview_edw', 'stage') }} l1_stage
        ON stage.l1 = l1_stage.stage_code
    JOIN {{ ref('link_fund_company') }} link
        ON {{ hk('company_valuation.company_id') }} = link.hk_company
        AND {{ hk('company_valuation.fund_id') }} = link.hk_fund
)

SELECT
hk_link,
date,
company_id,
fund_id,
company_exposure_investment_year,
company_exposure_investment_type,
company_exposure_public_status,
company_exposure_stage,
company_exposure_stage_broad,
load_dt,
{{ encoded_hashed_row() }} as skey
FROM attributes
