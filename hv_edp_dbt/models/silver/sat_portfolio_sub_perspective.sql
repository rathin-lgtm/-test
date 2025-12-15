WITH subperspective_based_dates AS (
     SELECT 
        link.hk_link,
        link.fund_sub_perspective_id,
        dp.portfolio_id, 
        min(dp.portfolio_close_date) AS portfolio_close_date_by_sub_perspective, 
        min(dp.portfolio_close_date) / 10000 AS portfolio_close_year_by_sub_perspective,
		min(portfolio_vintage_year) AS Portfolio_vintage_year_by_sub_perspective,
        CURRENT_TIMESTAMP() as load_dt	
FROM	{{ source('bronze_from_harborview_edw', 'dim_portfolios') }}	dp
JOIN {{ ref('link_portfolio_fund') }} link
        ON dp.portfolio_id = link.portfolio_id
        AND dp.fund_id = link.fund_id
WHERE dp.portfolio_close_date <> -1
GROUP BY   link.hk_link, link.fund_sub_perspective_id, dp.portfolio_id
),
final_attributes AS (
    SELECT hk_link,
        fund_sub_perspective_id,
        portfolio_id,
        portfolio_close_date_by_sub_perspective,
        portfolio_close_year_by_sub_perspective,
        Portfolio_vintage_year_by_sub_perspective,
        load_dt
    FROM subperspective_based_dates
)
{{ append_hk_key_column('final_attributes') }}



