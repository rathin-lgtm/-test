with funds as (
    select * from {{ source('bronze_from_harborview_edw', 'dim_fund') }}
)

select {{ hk('fund_id') }} as hk_fund,
       fund_id,
       CURRENT_TIMESTAMP() as load_dt,
       funds.file_name as record_source
       from funds
