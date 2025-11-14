with companies as (
    select * from {{ source('bronze_from_harborview_edw', 'company') }}
)

select sha2(upper(trim(company_id))) as hk_company,
       company_id,
       CURRENT_TIMESTAMP() as load_dt,
       companies.file_name as record_source
       from companies