WITH fund_hier_ownership as (
    SELECT 
        ivo.L29_id,
        ivo.fund_hier_id,
        ivo.fund_hier,
        max(ivo.hier_percentage) as hier_percentage
    FROM {{ ref('fund_hiers_pct_hist') }} ivo
    WHERE ivo.ownership_quarter_seq = 0 AND ivo.active_ind = 1
    GROUP BY ivo.L29_id, ivo.fund_hier_id, ivo.fund_hier
),
company_metrics as (
    SELECT
        cv.date_id,
        cv.fund_id,
        cv.company_id,
        cv.original_company_id,
        cv.currency_id,
        cv.metric_id,
        cv.amount * fh.hier_percentage hier_amount
    FROM fund_hier_ownership fh
    JOIN {{ ref('fact_company_valuation') }} cv ON
        fh.L29_id = cv.fund_id
),
daily_metrics as (
    SELECT
        hub.hk_company,
        link.hk_link,
        hub_original.hk_company as hk_company_original,
        date_id,
        {{ company_realized_value('metric_id', 'hier_amount') }} as company_realized_value,
        {{ company_current_value('metric_id', 'hier_amount') }} as company_current_value,
        (company_current_value - company_realized_value) as company_total_value,
        {{ company_realized_cost('metric_id', 'hier_amount') }} as company_realized_cost,
        {{ company_current_cost('metric_id', 'hier_amount') }} as company_current_cost,
        (company_current_cost - company_realized_cost) as company_total_cost,
        company_total_value - company_total_cost as company_gain_loss,
        CURRENT_TIMESTAMP() as load_dt
    FROM company_metrics metrics
    JOIN {{ ref('hub_company') }} hub
        ON metrics.company_id = hub.company_id 
    JOIN {{ ref('hub_company') }} hub_original
        ON metrics.original_company_id = hub_original.company_id 
    JOIN {{ ref('link_fund_company') }} link
        ON metrics.fund_id = link.fund_id
        and metrics.company_id = link.company_id
    GROUP BY date_id, hub.hk_company, hub_original.hk_company, link.hk_link
),

final_metrics as (
SELECT
    {{ to_date('date_id') }} as as_of_date,
    hk_link,
    hk_company,
    hk_company_original,
    load_dt,
    {{ company_rollup('company_realized_value') }} as realized_value, 
    {{ company_rollup('company_current_value') }} as current_value, 
    {{ company_rollup('company_total_value') }} as total_value, 
    {{ company_rollup('company_realized_cost') }} as realized_cost,
    {{ company_rollup('company_current_cost') }} as current_cost,
    {{ company_rollup('company_total_cost') }} as total_cost, 
    {{ company_rollup('company_gain_loss') }} as gain_loss,
    CASE 
        WHEN total_cost = 0 THEN 0
        ELSE total_value / total_cost
    END as tvtc,
FROM daily_metrics
)

{{ append_hk_key_column('final_metrics') }}