with funds as (
    select * from {{ source('bronze_from_harborview_edw', 'dim_fund') }}
),

keys as (
 select * from {{ source('bronze_from_harborview_edw', 'global_edw_key_to_iqid') }}
)

select sha2(upper(trim(keys.source_table_col_val))) as hk_fund,
       keys.source_table_col_val as efront_fund_id,
       CURRENT_TIMESTAMP() as load_dt,
       funds.file_name as record_source
       from funds
       join keys on funds.fund_id = keys.edw_key AND keys.source_table = 'fund_xref'
