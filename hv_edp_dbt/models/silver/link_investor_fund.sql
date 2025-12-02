with investors as (
    select * from {{ source('bronze_from_harborview_edw', 'fact_investor_transactions') }}
)

SELECT DISTINCT
    hk_investor,
    hk_fund,
    sha2(hk_investor || hk_fund) as hk_link,
    investors.investor_name_id as investor_id,
    investors.fund_id,
    CURRENT_TIMESTAMP() as load_dt
FROM investors
JOIN {{ ref('hub_investor') }} hub
    ON investors.investor_name_id = hub.investor_id
JOIN {{ ref('hub_fund') }} hub_fund
    ON investors.fund_id = hub_fund.fund_id
