with distinct_investor_ids as (
    SELECT distinct(investor_id), file_name
    FROM {{ source('bronze_from_harborview_edw', 'fact_investor_transactions') }}
)

SELECT 
    {{ hk('investor_id') }} as hk_investor,
    investor_id,
    CURRENT_TIMESTAMP() as load_dt,
    file_name as record_source
FROM distinct_investor_ids 