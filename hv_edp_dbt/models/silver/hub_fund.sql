with funds as (
    select * from {{ ref('dim_fund') }}
)

select {{ hk('fund_id') }} as hk_fund,
       fund_id,
       CURRENT_TIMESTAMP() as load_dt,
       funds.file_name as record_source
       from funds
