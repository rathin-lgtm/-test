with sub_perspectives as (
    -- TODO: To be removed when proper tag system is in place and these sub-perspective attributes are placed somewhere else.
    SELECT *
    FROM {{ source('bronze_from_harborview_edw', 'dim_fund_sub_perspective') }} dim
    JOIN {{ source('bronze_from_harborview_edw', 'fact_fund_sub_perspective_funds') }} fct
        ON fct.fund_sub_perspective_id = dim.fund_sub_perspective_id
    WHERE fund_perspective_view_id = 3 -- SELECT MAIN FUNDS ONLY
),
attributes as (
    SELECT
        hub.hk_fund,
        fid.source_table_col_val as efront_fund_id,
        fund.short_name as fund_name,
        sp.fund_sub_perspective_name,
        c.name as fund_currency,
        aiv_fund.short_name as fund_investor_presentation_aiv,
        {{ to_date('aiv_fund.lock_date') }} as fund_investor_presentation_aiv_lock_date,
        aiv_fund.fund_type_e_id as fund_investor_presentation_aiv_type_efront,
        {{ to_date('fund.lock_date') }} as fund_lock_date,
        {{ to_date('aiv_fund.initial_capcall_date') }} as investor_presentation_aiv_initial_capcall_date,
        {{ to_date('aiv_fund.fund_org_date') }} as investor_presentation_aiv_origination_date,
        cal.calendar_quarter_id as investor_presentation_aiv_origination_quarter,
        cal.calendar_year as investor_presentation_aiv_origination_year,
        c.name as investor_presentation_aiv_currency,
        aiv_fund.type as investor_presentation_aiv_type,
        aiv_fund.do_not_show_irr as investor_presentation_aiv_do_not_show_irr,
        aiv_fund.accounting_status as investor_presentation_aiv_accounting_status,
        CURRENT_TIMESTAMP() as load_dt
    FROM 
        {{ source('bronze_from_harborview_edw', 'dim_fund') }} fund
    JOIN {{ source('bronze_from_harborview_edw', 'currency') }} c
        ON fund.currency_id = c.currency_id
    JOIN {{ source('bronze_from_harborview_edw', 'global_edw_key_to_iqid') }} fid
        ON fund.fund_id = fid.edw_key AND fid.source_table = 'fund_xref'
    LEFT JOIN sub_perspectives sp
        ON sp.fund_id = fund.fund_id
    LEFT JOIN {{ source('bronze_from_harborview_edw', 'dim_fund') }} aiv_fund
        ON fund.aiv_fund_group_id = aiv_fund.fund_id
    JOIN {{ ref('hub_fund') }} hub
        ON fund.fund_id = hub.fund_id
    LEFT JOIN {{ source('bronze_from_harborview_edw', 'calendar') }} cal
        ON aiv_fund.Fund_Org_Date = cal.date_id
),
final_attributes as (
    SELECT 
        hk_fund,
        efront_fund_id,
        fund_name,
        fund_sub_perspective_name,
        fund_currency,
        fund_investor_presentation_aiv,
        fund_investor_presentation_aiv_lock_date,
        fund_investor_presentation_aiv_type_efront,
        fund_lock_date,
        investor_presentation_aiv_initial_capcall_date,
        investor_presentation_aiv_origination_date,
        investor_presentation_aiv_origination_quarter,
        investor_presentation_aiv_origination_year,
        investor_presentation_aiv_currency,
        investor_presentation_aiv_type,
        investor_presentation_aiv_do_not_show_irr,
        investor_presentation_aiv_accounting_status,
        load_dt
    FROM attributes
    ORDER BY hk_fund
)

{{ append_hk_key_column('final_attributes') }}