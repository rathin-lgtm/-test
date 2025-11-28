with hub_inv_tr as (
    select * from {{ ref('hub_investor_transaction') }} 
    
)

SELECT distinct
sha2(hk_investor_transaction || hk_fund || hk_investor) as hk_link,
hk_investor_transaction,
hk_fund,
hk_investor,
hub_inv_tr.composite_key,
CURRENT_TIMESTAMP() as load_dt
FROM hub_inv_tr
JOIN {{ ref('hub_fund') }} as hub_fund
    ON hub_inv_tr.fund_id = hub_fund.fund_id
JOIN {{ ref('hub_investor') }} as hub_investor
    ON hub_inv_tr.investor_id = hub_investor.investor_id