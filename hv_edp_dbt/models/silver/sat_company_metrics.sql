WITH fund_hier_ownership as (
    SELECT 
        ivo.L29_id,
        fspfn.fund_sub_perspective_id,
        ivo.fund_hier_id,
        ivo.fund_hier,
        max(ivo.hier_percentage) as hier_percentage
    FROM {{ source('bronze_from_harborview_edw', 'fund_hiers_pct_hist') }} ivo
    JOIN {{ source('bronze_from_harborview_edw', 'fact_fund_sub_perspective_fund_network_paths') }} fspfn ON
        ivo.fund_hier_id = fspfn.fund_hier_id
    WHERE ivo.ownership_quarter_seq = 0
    GROUP BY ivo.L29_id, fspfn.fund_sub_perspective_id, ivo.fund_hier_id, ivo.fund_hier
),
company_metrics as (
    SELECT
        cv.fund_id,
        fh.fund_sub_perspective_id,
        cv.company_id,
        cv.original_company_id,
        cv.direct_company_id,
        cv.date_id,
        cv.currency_id,
        cv.metric_id,
        cv.investment_id,
        cv.position_id,
        cv.project_id,
        cv.loan_id, cv.stage_id, 
        cv.investment_type_id,
        cv.asset_type_id, 
        cv.investment_year, 
        cv.vintage_year, 
        cv.public_status, 
        cv.state_id, 
        cv.year_of_initial_investment, 
        cv.original_company_geography_id, 
        cv.company_geography_code,
        cv.industry_id, 
        cv.original_industry_id, 
        cv.amount, 
        fh.hier_percentage, 
        cv.amount * fh.hier_percentage hier_amount, 
        cv.hv_share, 
        cv.portfolio_id, 
        cv.portfolio_date, 
        cv.portfolio_status, 
        cv.is_realized_ind, 
        fh.fund_hier_id, 
        fh.fund_hier, 
        cv.investment_relation, 
        cv.percent_owned
    FROM fund_hier_ownership fh
    JOIN {{ source('bronze_from_harborview_edw', 'fact_company_valuation') }} cv ON
        fh.L29_id = cv.fund_id
)
SELECT
    company_id,
    date_id,
    {{ company_realized_value('metric_id', 'hier_amount') }} as company_realized_value,
    {{ company_current_value('metric_id', 'hier_amount') }} as company_current_value,
    (company_current_value - company_realized_value) as company_total_value,
    {{ company_realized_cost('metric_id', 'hier_amount') }} as company_realized_cost,
    {{ company_current_cost('metric_id', 'hier_amount') }} as company_current_cost,
    (company_current_cost - company_realized_cost) as company_total_cost,
    CASE 
        WHEN company_total_cost = 0 THEN 0
        ELSE company_total_value / company_total_cost
    END as company_tvtc
FROM company_metrics
GROUP BY date_id, company_id