with attributes as (
    SELECT 
        sha2(upper(trim(portfolio.portfolio_id))) as hk_portfolio,
        portfolio.fund_id,
        currency.name as portfolio_currency,
        portfolio.portfolio_close_year,
        portfolio.portfolio_name,
        portfolio.portfolio_entity_status,
        YEAR({{ to_date('portfolio.portfolio_commitment_date') }}) as portfolio_commitment_year,
        portfolio.portfolio_disclosure_level,
        portfolio.type_broad_id,
        type_broad.type_broad_desc,
        portfolio.portfolio_vintage_year,
        dim_geo.L1_description as portfolio_geography_broad,
        dim_geo.L2_description as portfolio_geography,
        dim_geo.L3_description as portfolio_geography_l3,
        dim_geo.L5_description as portfolio_geography_l5,
        dim_company.industry_description as portfolio_industry,
        dim_company.L1_description as portfolio_industry_l1,
        l1_stage.description as portfolio_stage_broad,
        l2_stage.description as portfolio_stage,
        CASE 
            WHEN manager.manager_id = -1 THEN 'HarbourVest Partners'
            ELSE LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(manager.manager_name, CHAR(10), ''), CHAR(34),''''), CHAR(13), ''), CHAR(9), ''), CHAR(160), '')))
        END as portfolio_manager,
        CURRENT_TIMESTAMP() as load_dt,
        portfolio.start_eff_date,
        portfolio.end_eff_date,
        portfolio.active_ind
    FROM
        {{ source('hv_source', 'dim_portfolios') }} portfolio
    LEFT JOIN {{ source('hv_source', 'dim_type_broad') }} type_broad
        ON portfolio.type_broad_id = type_broad.type_broad_id
    LEFT JOIN {{ source('hv_source', 'dim_hv_geography_hierarchy') }} dim_geo
        ON dim_geo.code = portfolio.portfolio_geography_id
    LEFT JOIN {{ source('hv_source', 'dim_company_industry_hierarchy') }} dim_company
        ON dim_company.industry_fine_code = portfolio.di_fine_industry_id
    LEFT JOIN {{ source('hv_source', 'stage') }} stage
        ON stage.stage_code = portfolio.portfolio_stage_id
    LEFT JOIN {{ source('hv_source', 'stage') }} l1_stage
        ON stage.l1 = l1_stage.stage_code
    LEFT JOIN {{ source('hv_source', 'stage') }} l2_stage
        ON stage.l2 = l2_stage.stage_code
    LEFT JOIN {{ source('hv_source', 'dim_manager') }} manager
        ON portfolio.project_manager_id = manager.manager_id
    JOIN {{ source('hv_source', 'currency') }} currency
        ON portfolio.portfolio_currency_id = currency.currency_id
    WHERE portfolio.portfolio_id <> -1 
)

SELECT
    hk_portfolio,
    portfolio_name,
    portfolio_entity_status,
    portfolio_currency,
    fund_id,
    portfolio_close_year,
    portfolio_commitment_year,
    portfolio_disclosure_level,
    type_broad_id,
    type_broad_desc,
    portfolio_vintage_year,
    portfolio_geography_broad,
    portfolio_geography,
    portfolio_geography_l3,
    portfolio_geography_l5,
    portfolio_industry,
    portfolio_industry_l1,
    portfolio_stage_broad,
    portfolio_stage,
    portfolio_manager,
    start_eff_date as effective_from,
    end_eff_date as effective_to,
    active_ind as is_active,
    {{ encoded_hashed_row() }} as skey,
    load_dt,
FROM attributes
