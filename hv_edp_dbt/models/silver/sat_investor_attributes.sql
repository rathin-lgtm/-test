with attributes as (
    SELECT
        hub.hk_investor,
        fid.source_table_col_val as efront_investor_id,
        COALESCE({{ restricted_name_masking('investor.part_of_hv_staff', 'investor.investor_name_id') }}, investor.short_name) as investor_name,
        COALESCE({{ hv_group_override('investor.part_of_hv_staff') }}, investor.parent_investor_id) as investor_group_id,
        COALESCE({{ restricted_name_masking('grp.part_of_hv_staff', 'grp.investor_name_id') }}, grp.short_name) as investor_group_name,
        CURRENT_TIMESTAMP() as load_dt
    FROM
        {{ ref('dim_investor') }} investor
    LEFT JOIN {{ ref('dim_investor') }} grp
        ON grp.investor_name_id = COALESCE({{ hv_group_override('investor.part_of_hv_staff') }}, investor.parent_investor_id)
    JOIN {{ ref('hub_investor') }} hub
        ON investor.investor_name_id = hub.investor_id
    LEFT JOIN {{ ref('global_edw_key_to_iqid') }} fid
        ON hub.investor_id = fid.edw_key AND fid.source_table = 'investors'
),

final_attributes as (
    SELECT 
        hk_investor,
        efront_investor_id,
        investor_name,
        investor_group_id,
        COALESCE(investor_group_name, 'Restricted') as investor_group_name,
        load_dt
    FROM attributes
)

{{ append_hk_key_column('final_attributes') }}