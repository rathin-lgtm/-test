with attributes as (
    SELECT
        hub.hk_investor,
        fid.source_table_col_val as efront_investor_id,
        COALESCE({{ restricted_name_masking('investor.part_of_hv_staff', 'investor.investor_name_id') }}, investor.short_name) as short_name,
        COALESCE({{ hv_group_override('investor.part_of_hv_staff') }}, investor.parent_investor_id) as parent_group_id,
        COALESCE({{ restricted_name_masking('grp.part_of_hv_staff', 'grp.investor_name_id') }}, grp.short_name) as parent_group_name,
        investor.address_region as region,
        CURRENT_TIMESTAMP() as load_dt
    FROM
        {{ source('bronze_from_harborview_edw', 'dim_investor') }} investor
    LEFT JOIN {{ source('bronze_from_harborview_edw', 'dim_investor') }} grp
        ON grp.investor_name_id = COALESCE({{ hv_group_override('investor.part_of_hv_staff') }}, investor.parent_investor_id)
    JOIN {{ ref('hub_investor') }} hub
        ON investor.investor_name_id = hub.investor_id
    LEFT JOIN {{ source('bronze_from_harborview_edw', 'global_edw_key_to_iqid') }} fid
        ON hub.investor_id = fid.edw_key AND fid.source_table = 'investors'
),

final_attributes as (
    SELECT 
        hk_investor,
        efront_investor_id,
        short_name,
        parent_group_id,
        COALESCE(parent_group_name, 'Restricted') as parent_group_name,
        region,
        load_dt
    FROM attributes
)

{{ append_hk_key_column('final_attributes') }}