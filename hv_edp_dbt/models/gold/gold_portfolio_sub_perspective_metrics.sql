SELECT
        hk_link,
        fund_sub_perspective_id,
        portfolio_id,
        portfolio_close_date_by_sub_perspective,
        portfolio_close_year_by_sub_perspective,
        Portfolio_vintage_year_by_sub_perspective,
        load_dt::date as as_of_date
FROM {{ ref('sat_portfolio_sub_perspective') }} psp
