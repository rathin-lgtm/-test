with portfolios as (
    select * from {{ source('hv_source', 'dim_portfolios') }}
)

select sha2(upper(trim(portfolio_id))) as hk_portfolio,
       CURRENT_TIMESTAMP() as load_dt,
       portfolios.file_name as record_source
       from portfolios
       group by portfolio_id, file_name, load_dt