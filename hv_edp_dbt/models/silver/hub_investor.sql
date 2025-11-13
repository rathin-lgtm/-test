with distinct_investor_ids as (
    SELECT distinct(investor_id), file_name
    FROM {{ source('bronze_from_harborview_edw', 'fact_investor_transactions') }}
)

SELECT 
    sha2(upper(trim(iid.source_table_col_val))) as hk_investor,
    iid.source_table_col_val as efront_investor_id,
    CURRENT_TIMESTAMP() as load_dt,
    i.file_name as record_source
FROM distinct_investor_ids i
JOIN {{ source('bronze_from_harborview_edw', 'global_edw_key_to_iqid') }} iid
        ON investor_id = iid.edw_key AND iid.source_table = 'investors'