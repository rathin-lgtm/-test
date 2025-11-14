with fact as (
    select * from {{ source('bronze_from_harborview_edw', 'fact_company_valuation') }}
)

SELECT distinct
{{ hk('company_id') }} as hk_company,
{{ hk('fund_id') }}  as hk_fund,
sha2(hk_company || hk_fund) as hk_link,
CURRENT_TIMESTAMP() as load_dt,
from fact