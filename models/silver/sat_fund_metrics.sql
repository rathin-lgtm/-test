{{ config(
    materialized='table',
    pre_hook="{{ create_xirr_udf(this.schema) }}"
) }}

with lp_investor_txns as (
    SELECT * FROM {{ source('hv_source', 'fact_investor_transactions') }} WHERE investor_type = 'LP'
),
daily_metrics as (
    SELECT
    t.date_id,
    t.fund_id,
    t.currency_id,
    {{ nav('t.date_id', 't.metric_id', 'f.lock_date', 't.amount') }} as nav,
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
    CURRENT_TIMESTAMP() as load_dt,
    t.file_name as record_source
    FROM lp_investor_txns t
    JOIN {{ source('hv_source', 'dim_fund') }} f
        ON t.fund_id = f.fund_id
    GROUP BY t.date_id, t.fund_id, t.currency_id, t.file_name
),
cashflows as (
    SELECT * FROM (
        SELECT
            fii.fund_id,
            fii.currency_id,
            investor_type,
            fx_rate,
            amount,
            {{ fund_irr_cashflow_indicator_filter(1, 'fii.date_id', 'cal.rollup_to_date_id', 'fii.metric_id') }} as one_year_cashflow_ind,
            {{ fund_irr_cashflow_indicator_filter(2, 'fii.date_id', 'cal.rollup_to_date_id', 'fii.metric_id') }} as two_year_cashflow_ind,
            {{ fund_irr_cashflow_indicator_filter(3, 'fii.date_id', 'cal.rollup_to_date_id', 'fii.metric_id') }} as three_year_cashflow_ind,
            {{ fund_irr_cashflow_indicator_filter(4, 'fii.date_id', 'cal.rollup_to_date_id', 'fii.metric_id') }} as four_year_cashflow_ind,
            {{ fund_irr_cashflow_indicator_filter(5, 'fii.date_id', 'cal.rollup_to_date_id', 'fii.metric_id') }} as five_year_cashflow_ind,
            {{ fund_irr_cashflow_indicator_filter(7, 'fii.date_id', 'cal.rollup_to_date_id', 'fii.metric_id') }} as seven_year_cashflow_ind,
            {{ fund_irr_cashflow_indicator_filter(10, 'fii.date_id', 'cal.rollup_to_date_id', 'fii.metric_id') }} as ten_year_cashflow_ind,
            {{ fund_irr_cashflow_indicator_filter(15, 'fii.date_id', 'cal.rollup_to_date_id', 'fii.metric_id') }} as fifteen_year_cashflow_ind,
            {{ fund_irr_amount_filter_limited('fii.metric_id', 'cal.Date_fact', 'cal.Date_Dim', 'cal.Date_1_Year', 'fii.amount') }} as amount_1_year,
            {{ fund_irr_amount_filter_limited('fii.metric_id', 'cal.Date_fact', 'cal.Date_Dim', 'cal.Date_2_Year', 'fii.amount') }} as amount_2_year,
            {{ fund_irr_amount_filter_limited('fii.metric_id', 'cal.Date_fact', 'cal.Date_Dim', 'cal.Date_3_Year', 'fii.amount') }} as amount_3_year,
            {{ fund_irr_amount_filter_limited('fii.metric_id', 'cal.Date_fact', 'cal.Date_Dim', 'cal.Date_4_Year', 'fii.amount') }} as amount_4_year,
            {{ fund_irr_amount_filter_limited('fii.metric_id', 'cal.Date_fact', 'cal.Date_Dim', 'cal.Date_5_Year', 'fii.amount') }} as amount_5_year,
            {{ fund_irr_amount_filter_limited('fii.metric_id', 'cal.Date_fact', 'cal.Date_Dim', 'cal.Date_7_Year', 'fii.amount') }} as amount_7_year,
            {{ fund_irr_amount_filter_limited('fii.metric_id', 'cal.Date_fact', 'cal.Date_Dim', 'cal.Date_10_Year', 'fii.amount') }} as amount_10_year,
            {{ fund_irr_amount_filter_limited('fii.metric_id', 'cal.Date_fact', 'cal.Date_Dim', 'cal.Date_15_Year', 'fii.amount') }} as amount_15_year,
            {{ fund_irr_amount_filter_inception('fii.metric_id', 'cal.Date_fact', 'cal.Date_Dim', 'fii.amount') }} as amount_inception,
            cal.Date_Fact as cashflow_date,
            fii.date_id as cashflow_date_id,
            rollup_to_date_id as date_id
        FROM {{ source('hv_source', 'fact_irr_investor') }} fii
        JOIN ({{ irr_calendar() }}) cal ON
            (fii.date_id = cal.rollup_date_id)
        WHERE fii.active_ind = 1 AND fii.currency_id IN (8, 10) AND fii.metric_id IN (217, 218, 227)
    ) WHERE COALESCE(amount_1_year, amount_2_year, amount_3_year, amount_4_year, amount_5_year, amount_7_year ,amount_10_year, amount_15_year, amount_inception) IS NOT NULL AND investor_type = 'LP'
),
xirrs as (
    SELECT
        fund_id,
        currency_id,
        date_id,
        {{ target.database }}.{{ this.schema }}.xirr(amount_inception, cashflow_date, -0.01) * max(one_year_cashflow_ind) as irr_inception,
        {{ target.database }}.{{ this.schema }}.xirr(amount_1_year, cashflow_date, -0.01) * max(one_year_cashflow_ind) as irr_1_year,
        {{ target.database }}.{{ this.schema }}.xirr(amount_3_year, cashflow_date, -0.01) * max(three_year_cashflow_ind) as irr_3_year,
        {{ target.database }}.{{ this.schema }}.xirr(amount_5_year, cashflow_date, -0.01) * max(five_year_cashflow_ind) as irr_5_year,
        {{ target.database }}.{{ this.schema }}.xirr(amount_10_year, cashflow_date, -0.01) * max(ten_year_cashflow_ind) as irr_10_year
    FROM cashflows
    GROUP BY fund_id, currency_id, date_id
)
SELECT 
    DATE(d.date_id, 'YYYYMMDD') as as_of_date,
    sha2(upper(trim(fid.source_table_col_val))) as hk_fund,
    c.currency_code as metric_currency_code,
    {{ rollup('nav') }} as lp_nav,
    {{ rollup('tvpi') }} as tvpi,
    {{ rollup('dpi') }} as dpi,
    {{ rollup('distributions') }} as lp_distributions,
    {{ rollup('contributions') }} as lp_contributions,
    {{ rollup('total_value') }} as lp_total_value,
    {{ rollup('commitments') }} as lp_commitments,
    {{ rollup('capital_called') }} as lp_capital_called,
    {{ rollup('gain_loss') }} as gain_loss,
    LAST_VALUE(x.irr_inception) IGNORE NULLS OVER (
        PARTITION BY d.fund_id, d.currency_id
        ORDER BY d.date_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) as irr,
    LAST_VALUE(x.irr_1_year) IGNORE NULLS OVER (
        PARTITION BY d.fund_id, d.currency_id
        ORDER BY d.date_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) as irr_1_year,
    LAST_VALUE(x.irr_3_year) IGNORE NULLS OVER (
        PARTITION BY d.fund_id, d.currency_id
        ORDER BY d.date_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) as irr_3_year,
    LAST_VALUE(x.irr_5_year) IGNORE NULLS OVER (
        PARTITION BY d.fund_id, d.currency_id
        ORDER BY d.date_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) as irr_5_year,
    LAST_VALUE(x.irr_10_year) IGNORE NULLS OVER (
        PARTITION BY d.fund_id, d.currency_id
        ORDER BY d.date_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) as irr_10_year,
    HEX_ENCODE(HASH(as_of_date, hk_fund, currency_code, nav, tvpi, distributions, contributions, total_value, commitments, capital_called, gain_loss)) as skey,
    load_dt,
    record_source
FROM (daily_metrics) d
JOIN {{ source('hv_source', 'currency') }} c
    ON d.currency_id = c.currency_id
JOIN {{ source('hv_source', 'global_edw_key_to_iqid') }} fid
    ON d.fund_id = fid.edw_key AND fid.source_table = 'fund_xref'
LEFT OUTER JOIN xirrs x
    ON x.fund_id = d.fund_id AND d.date_id = x.date_id AND d.currency_id = x.currency_id
ORDER BY as_of_date
