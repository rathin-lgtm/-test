with portfolios as (
    select * from {{ source('bronze_from_harborview_edw', 'dim_portfolios') }}
)

select distinct {{ hk('portfolio_id') }} as hk_portfolio,
       portfolio_id,
       CURRENT_TIMESTAMP() as load_dt,
       portfolios.file_name as record_source
       from portfolios