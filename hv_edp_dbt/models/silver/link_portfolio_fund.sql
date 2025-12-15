with portfolios as (
    select * from {{ source('bronze_from_harborview_edw', 'dim_portfolios') }}
)

SELECT distinct
{{ hk('p.portfolio_id') }} as hk_portfolio,
{{ hk('p.fund_id') }} as hk_fund,
sha2(hk_portfolio || hk_fund) as hk_link,
p.portfolio_id,
p.fund_id,
sp.fund_sub_perspective_id,
CURRENT_TIMESTAMP() as load_dt,
from portfolios p
-- We are doing all this join becuase we want unique sub-perspective_id for every fund_id. One fund id should have one unique sub-perspective id 
--We need this for 
--USER STORY 373873,USER STORY 373874, USER STORY 373875. Dates for portfolio + sub-perspective reporting
Join {{ source('bronze_from_harborview_edw', 'dim_fund') }} d
on p.fund_id = d.fund_id
join {{ source('bronze_from_harborview_edw', 'fact_fund_sub_perspective_funds') }} f
on d.fund_id = f.fund_id
join {{ source('bronze_from_harborview_edw', 'dim_fund_sub_perspective') }} sp
on f.fund_id = sp.fund_sub_perspective_primary_fund_id
and f.fund_sub_perspective_id = sp.fund_sub_perspective_id
Where sp.fund_perspective_view_id = 3
