with portfolios as (
    select * from {{ source('bronze_from_harborview_edw', 'dim_portfolios') }}
)

SELECT distinct
{{ hk('portfolio_id') }} as hk_portfolio,
{{ hk('fund_id') }} as hk_fund,
sha2(hk_portfolio || hk_fund) as hk_link,
portfolio_id,
fund_id,
CURRENT_TIMESTAMP() as load_dt,
from portfolios