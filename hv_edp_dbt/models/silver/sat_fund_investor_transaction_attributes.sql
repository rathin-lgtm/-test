with attributes as (
    SELECT 
        hk_link,
        inv_tr.date_id,
        cal_q.quarter_id,
        cal_q.quarter_desc,
        cal_q.quarter_counter,
        CURRENT_TIMESTAMP() as load_dt
    FROM {{ source('bronze_from_harborview_edw', 'fact_investor_transactions') }} as inv_tr 
    join {{ ref('link_fund_investor_transaction') }} as link
    On Concat(investor_id,date_id,currency_id,fund_id,metric_id,is_transfer,exclude_transaction,monthly_date_id) = link.composite_key
    LEFT JOIN {{ source('bronze_from_harborview_edw', 'calendar_quarter') }} as cal_q
        ON inv_tr.date_id = cal_q.quarter_id
    WHERE inv_tr.active_ind = 1
),
final_attributes as (
    Select
        {{ to_date('date_id') }} as as_of_date,
        hk_link,
        date_id,
        quarter_id,
        quarter_desc,
        quarter_counter,
        load_dt
    From 
        attributes
)
{{ append_hk_key_column('final_attributes') }}

