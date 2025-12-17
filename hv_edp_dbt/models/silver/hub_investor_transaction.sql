with investor_transactions as (
    select *, 
    Concat(investor_name_id,date_id,currency_id,fund_id,metric_id,is_transfer,exclude_transaction,monthly_date_id) as composite_key,
     from {{ source('raw_from_harborview_edw', 'fact_investor_transactions') }}
)

-- There is a hashvalue column present in the source table but we are generating our own hash key based on business keys
select distinct {{ hk('composite_key') }} as hk_investor_transaction,
    composite_key,
    investor_name_id as investor_id,
    date_id,
    currency_id,
    fund_id,
    metric_id,
    is_transfer,
    exclude_transaction,
    monthly_date_id,  
    CURRENT_TIMESTAMP() as load_dt,
    investor_transactions.file_name as record_source
    from investor_transactions
