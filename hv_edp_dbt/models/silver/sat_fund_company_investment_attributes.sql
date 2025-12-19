with attributes as (
    SELECT
        hk_link,
        {{ to_date('date_id') }} as as_of_date,
        investment_year as company_investment_year,
        investment_type.investment_type_desc as company_investment_type,
        {{ indicator_yes_no('public_status') }} as company_public_status,
        stage.description as company_stage,
        l1_stage.description as company_stage_broad,
        CURRENT_TIMESTAMP() as load_dt
    FROM  (SELECT distinct date_id, company_id, fund_id, investment_year, investment_type_id, public_status, stage_id from {{ source('raw_from_harborview_edw', 'fact_company_valuation') }} ) company_valuation
    LEFT JOIN {{ ref('dim_investment_type') }} investment_type
        ON company_valuation.investment_type_id = investment_type.investment_type_id
    LEFT JOIN {{ ref('stage') }} stage
        ON stage.stage_code = company_valuation.stage_id 
    LEFT JOIN {{ ref('stage') }} l1_stage
        ON stage.l1 = l1_stage.stage_code
    JOIN {{ ref('link_fund_company') }} link
        ON company_valuation.company_id = link.company_id
        AND company_valuation.fund_id = link.fund_id
)

{{ append_hk_key_column('attributes') }}
