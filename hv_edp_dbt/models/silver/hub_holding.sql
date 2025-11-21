with holdings as (
    select * from {{ source('bronze_from_harborview_edw', 'dim_holdings') }}
)

select distinct {{ hk('holding_id') }} as hk_holding,
    holding_id,
    CURRENT_TIMESTAMP() as load_dt,
    holdings.file_name as record_source
    from holdings
