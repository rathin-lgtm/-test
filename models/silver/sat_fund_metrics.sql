{{ config(
    materialized='table',
    pre_hook="{{ create_xirr_udf(this.schema) }}"
) }}

with daily_metrics as (
    SELECT
    DATE(date_id, 'YYYYMMDD') as as_of_date,
    sha2(upper(trim(fid.source_table_col_val))) as hk_fund,
    c.currency_code,
    {{ nav('date_id', 't.metric_id', 'f.lock_date', 't.amount') }} as nav,
    0 as irr_gross,
    0 as irr_net,
    {{ distributions('t.metric_id', 't.amount') }} as distributions,
    {{ contributions('t.metric_id', 't.amount') }} as contributions,
    nav + distributions as total_value,
    CASE 
        WHEN contributions = 0 THEN 0
        ELSE total_value / contributions
    END as tvpi,
    CASE 
        WHEN contributions = 0 THEN 0
        ELSE distributions / contributions
    END as dpi,
    {{ commitments('t.metric_id', 't.amount') }} as commitments,
    contributions + {{ capital_called_add_term('t.metric_id', 't.amount') }} as capital_called,
    total_value - contributions as gain_loss,
    0 as pme_irr_1,
    0 as pme_irr_2,
    0 as pme_irr_msciaw,
    CURRENT_TIMESTAMP() as load_dt,
    t.file_name as record_source

    FROM (
        SELECT * FROM {{ source('hv_source', 'fact_investor_transactions') }} WHERE investor_type = 'LP'
    ) t
    JOIN {{ source('hv_source', 'currency') }} c
        ON t.currency_id = c.currency_id
    JOIN {{ source('hv_source', 'global_edw_key_to_iqid') }} fid
        ON t.fund_id = fid.edw_key AND fid.source_table = 'fund_xref'
    JOIN {{ source('hv_source', 'dim_fund') }} f
        ON t.fund_id = f.fund_id
    GROUP BY as_of_date, hk_fund, currency_code, t.file_name
)

SELECT 
    as_of_date,
    hk_fund,
    currency_code as metric_currency_code,
    {{ rollup('nav') }} as lp_nav,
    {{ rollup('tvpi') }} as tvpi,
    {{ rollup('dpi') }} as dpi,
    irr_gross,
    irr_net,
    {{ rollup('distributions') }} as lp_distributions,
    {{ rollup('contributions') }} as lp_contributions,
    {{ rollup('total_value') }} as lp_total_value,
    {{ rollup('commitments') }} as lp_commitments,
    {{ rollup('capital_called') }} as lp_capital_called,
    {{ rollup('gain_loss') }} as gain_loss,
    pme_irr_1,
    pme_irr_2,
    pme_irr_msciaw,
    HEX_ENCODE(HASH(as_of_date, hk_fund, currency_code, nav, tvpi, irr_gross, irr_net, distributions, contributions, total_value, commitments, capital_called, gain_loss, pme_irr_1, pme_irr_2, pme_irr_msciaw)) as skey,
    load_dt,
    record_source
FROM (daily_metrics)
ORDER BY as_of_date
