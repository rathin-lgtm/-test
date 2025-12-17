with investments as (
    select * from {{ source('raw_from_harborview_edw', 'dim_investor') }}
)

select distinct {{ hk('investor_name_id') }} as hk_investor,
    investor_name_id as investor_id,
    CURRENT_TIMESTAMP() as load_dt,
    investments.file_name as record_source
    from investments
