with investment_transactions_monthly as (
    SELECT distinct 
        investments_monthly.fund_id,
        investments_monthly.investment_id,
        investments.investment_currency_id
    FROM {{ source('bronze_from_harborview_edw', 'fact_investment_transactions_fund_hierarchy_monthly') }} investments_monthly
    LEFT JOIN {{ source('bronze_from_harborview_edw', 'dim_investments') }} investments
        ON investments_monthly.fund_id = investments.fund_id
        AND investments_monthly.investment_id = investments.investment_id
),

investment_transactions as (
    SELECT distinct
        investment_transactions.fund_id,
        investment_transactions.investment_id,
        investments.investment_currency_id
    FROM {{ source('bronze_from_harborview_edw', 'fact_investment_transactions_fund_hierarchy') }} investment_transactions
    LEFT JOIN {{ source('bronze_from_harborview_edw', 'dim_investments') }} investments
        ON investment_transactions.fund_id = investments.fund_id
        AND investment_transactions.investment_id = investments.investment_id
),

holding_currency as (
    SELECT 
        COALESCE(investment_transactions_monthly.fund_id, investment_transactions.fund_id) as fund_id,
        COALESCE(investment_transactions_monthly.investment_id, investment_transactions.investment_id) as investment_id,
        COALESCE(investment_transactions_monthly.investment_currency_id, investment_transactions.investment_currency_id) as holding_currency_id
    FROM investment_transactions_monthly
    FULL OUTER JOIN investment_transactions
        ON investment_transactions_monthly.fund_id = investment_transactions.fund_id
        AND investment_transactions_monthly.investment_id = investment_transactions.investment_id),

attributes as (
    SELECT
        hk_link,
        {{ to_date('date_id') }} as as_of_date,
        investment_year as company_investment_year,
        investment_type.investment_type_desc as company_investment_type,
        {{ indicator_yes_no('public_status') }} as company_public_status,
        stage.description as company_stage,
        l1_stage.description as company_stage_broad,
        currency.name as currency,
        CURRENT_TIMESTAMP() as load_dt
    FROM  (SELECT distinct date_id, company_id, fund_id, investment_year, investment_type_id, public_status, stage_id from {{ source('bronze_from_harborview_edw', 'fact_company_valuation') }} ) company_valuation
    LEFT JOIN {{ source('bronze_from_harborview_edw', 'dim_investment_type') }} investment_type
        ON company_valuation.investment_type_id = investment_type.investment_type_id
    LEFT JOIN {{ source('bronze_from_harborview_edw', 'stage') }} stage
        ON stage.stage_code = company_valuation.stage_id 
    LEFT JOIN {{ source('bronze_from_harborview_edw', 'stage') }} l1_stage
        ON stage.l1 = l1_stage.stage_code
    LEFT JOIN holding_currency
        ON holding_currency.fund_id = company_valuation.fund_id
    LEFT JOIN {{ source('bronze_from_harborview_edw', 'currency') }} currency
        ON currency.currency_id = holding_currency.holding_currency_id
    JOIN {{ ref('link_fund_company') }} link
        ON company_valuation.company_id = link.company_id
        AND company_valuation.fund_id = link.fund_id
)

{{ append_hk_key_column('attributes') }}
