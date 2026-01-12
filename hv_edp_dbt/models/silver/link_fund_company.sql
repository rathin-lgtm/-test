with fact as (
    select * from {{ ref('fact_company_valuation') }}
)

SELECT distinct
hk_company,
hk_fund,
sha2(hk_company || hk_fund) as hk_link,
fact.fund_id,
fact.company_id,
CURRENT_TIMESTAMP() as load_dt,
from fact
JOIN {{ ref('hub_company') }} hub
    ON fact.company_id = hub.company_id
JOIN {{ ref('hub_fund') }} hub_fund
    ON fact.fund_id = hub_fund.fund_id