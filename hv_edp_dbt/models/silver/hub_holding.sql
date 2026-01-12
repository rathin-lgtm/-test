with holdings as (
    select * from {{ ref('dim_holdings') }}
)

select distinct {{ hk('holding_id') }} as hk_holding,
    holding_id,
    CURRENT_TIMESTAMP() as load_dt,
    holdings.file_name as record_source
    from holdings
