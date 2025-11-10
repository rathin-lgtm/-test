with portfolios as (
    select * from {{ source('hv_source', 'dim_portfolios') }}
)

SELECT 
sha2(upper(trim(portfolio_id))) as hk_portfolio,
sha2(upper(trim(fund_id))) as hk_fund,
sha2(hk_portfolio || hk_fund) as hk_link,
CURRENT_TIMESTAMP() as load_dt,
from portfolios
group by hk_link, hk_portfolio, hk_fund