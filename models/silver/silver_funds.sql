with funds as (
    select * from {{ source('hv_source', 'dim_fund') }}
    {{ filter_new_ingests() }}
)

select * from funds