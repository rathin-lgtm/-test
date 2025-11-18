with attributes as (
    SELECT
        sha2(upper(trim(fid.source_table_col_val))) as hk_fund,
        fund.short_name as fund_name,
        c.name as fund_currency,
        aiv_fund.short_name as fund_investor_presentation_aiv,
        {{ to_date('aiv_fund.lock_date') }} as fund_investor_presentation_aiv_lock_date,
        aiv_fund.fund_type_e_id as fund_investor_presentation_aiv_type_efront,
        {{ to_date('fund.lock_date') }} as fund_lock_date,
        CURRENT_TIMESTAMP() as load_dt,
        fund.file_name as record_source
        --fund.start_eff_date,
        --fund.end_eff_date,
        --fund.active_ind
    FROM 
        {{ source('bronze_from_harborview_edw', 'dim_fund') }} fund
    JOIN {{ source('bronze_from_harborview_edw', 'currency') }} c
        ON fund.currency_id = c.currency_id
    JOIN {{ source('bronze_from_harborview_edw', 'global_edw_key_to_iqid') }} fid
        ON fund.fund_id = fid.edw_key AND fid.source_table = 'fund_xref'
    LEFT JOIN {{ source('bronze_from_harborview_edw', 'dim_fund') }} aiv_fund
        ON fund.aiv_fund_group_id = aiv_fund.fund_id
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
    record_source
FROM attributes
ORDER BY hk_fund
