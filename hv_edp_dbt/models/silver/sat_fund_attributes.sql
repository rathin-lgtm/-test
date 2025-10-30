with attributes as (
    SELECT
        sha2(upper(trim(fid.source_table_col_val))) as hk_fund,
        t.short_name as fund_name,
        c.name as fund_currency,
        a17.short_name as fund_investor_presentation_aiv,
        DATE(a17.lock_date, 'YYYYMMDD') as fund_investor_presentation_aiv_lock_date,
        a17.fund_type_e_id as fund_investor_presentation_aiv_type_efront,
        DATE(a17.lock_date, 'YYYYMMDD') as fund_lock_date,
        CURRENT_TIMESTAMP() as load_dt,
        t.file_name as record_source,
        t.start_eff_date,
        t.end_eff_date,
        t.active_ind
    FROM 
        {{ source('hv_source', 'dim_fund') }} t
    JOIN {{ source('hv_source', 'currency') }} c
        ON t.currency_id = c.currency_id
    JOIN {{ source('hv_source', 'global_edw_key_to_iqid') }} fid
        ON t.fund_id = fid.edw_key AND fid.source_table = 'fund_xref'
    LEFT JOIN {{ source('hv_source', 'dim_fund') }} a17
        ON t.aiv_fund_group_id = a17.fund_id
)

SELECT 
    hk_fund,
    fund_name,
    fund_currency,
    fund_investor_presentation_aiv,
    fund_investor_presentation_aiv_lock_date,
    fund_investor_presentation_aiv_type_efront,
    fund_lock_date,
    HEX_ENCODE(HASH(hk_fund, fund_name, fund_currency, fund_investor_presentation_aiv, fund_investor_presentation_aiv_lock_date, fund_investor_presentation_aiv_type_efront, fund_lock_date)) as skey,
    load_dt,
    record_source,
    start_eff_date as effective_from,
    end_eff_date as effective_to,
    active_ind as is_active
FROM attributes
ORDER BY hk_fund
