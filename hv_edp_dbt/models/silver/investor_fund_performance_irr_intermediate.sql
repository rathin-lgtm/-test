--irr calculation for investor_fund_performace is fairly complicated, so kepping it as a separate intermediate model.
-- we will join this model to sat_investor_fund_performance to get the irr values there.
{{ config(
    materialized='table',
    pre_hook="{{ create_xirr_udf(this.schema) }}"
) }}

-- Cashflows limited to IRR windows and investor+fund granularity
WITH cashflows AS (
    SELECT * FROM (
        SELECT
            fii.fund_id,
            fii.investor_name_id as investor_id,
            fii.currency_id,
            fii.investor_type,
            fii.metric_id,
            fii.amount,

            -- Window indicators (guard rails)
            {{ fund_irr_cashflow_indicator_filter(1,  'fii.date_id', 'cal.rollup_to_date_id', 'fii.metric_id') }}  AS one_year_cashflow_ind,
            {{ fund_irr_cashflow_indicator_filter(3,  'fii.date_id', 'cal.rollup_to_date_id', 'fii.metric_id') }}  AS three_year_cashflow_ind,
            {{ fund_irr_cashflow_indicator_filter(5,  'fii.date_id', 'cal.rollup_to_date_id', 'fii.metric_id') }}  AS five_year_cashflow_ind,
            {{ fund_irr_cashflow_indicator_filter(10, 'fii.date_id', 'cal.rollup_to_date_id', 'fii.metric_id') }}  AS ten_year_cashflow_ind,

            -- Amount filters per window
            {{ fund_irr_amount_filter_limited('fii.metric_id', 'cal.Date_fact', 'cal.Date_Dim', 'cal.Date_1_Year',  'fii.amount') }} AS amount_1_year,
            {{ fund_irr_amount_filter_limited('fii.metric_id', 'cal.Date_fact', 'cal.Date_Dim', 'cal.Date_3_Year',  'fii.amount') }} AS amount_3_year,
            {{ fund_irr_amount_filter_limited('fii.metric_id', 'cal.Date_fact', 'cal.Date_Dim', 'cal.Date_5_Year',  'fii.amount') }} AS amount_5_year,
            {{ fund_irr_amount_filter_limited('fii.metric_id', 'cal.Date_fact', 'cal.Date_Dim', 'cal.Date_10_Year', 'fii.amount') }} AS amount_10_year,

            -- macro for inception amounts (investor + fund performance)
            {{ fund_irr_amount_filter_inception_investor_fund_performance('fii.metric_id', 'cal.Date_Fact', 'cal.Date_Dim', 'fii.amount') }} AS amount_inception,

            -- Cashflow date used by XIRR
            cal.Date_Fact         AS cashflow_date,
            cal.rollup_to_date_id AS date_id
        FROM {{ source('bronze_from_harborview_edw', 'fact_irr_investor') }} fii
        JOIN ({{ irr_calendar() }}) cal
          ON fii.date_id = cal.rollup_date_id
        WHERE fii.active_ind = 1
          AND fii.metric_id IN ({{ irr_cashflow_metric_investor_fund_performance_ids() }})
    )
    WHERE COALESCE(amount_1_year, amount_3_year, amount_5_year, amount_10_year, amount_inception) IS NOT NULL
      AND investor_type = 'LP'
),

-- IRRs per investor+fund (+currency) and reporting date
xirrs AS (
    SELECT
        fund_id,
        investor_id,
        currency_id,
        date_id,
        -- Inception IRR: gate by presence of inception cashflows (NOT by 1-year guard rail)
        CASE
          WHEN COALESCE(SUM(amount_inception), 0) <> 0
          THEN {{ target.database }}.{{ this.schema }}.xirr(amount_inception, cashflow_date, -0.01)
          ELSE NULL
        END AS irr_inception,

        CASE
          WHEN MAX(one_year_cashflow_ind) = 1
          THEN {{ target.database }}.{{ this.schema }}.xirr(amount_1_year, cashflow_date, -0.01)
          ELSE NULL
        END AS irr_1_year,

        CASE
          WHEN MAX(three_year_cashflow_ind) = 1
          THEN {{ target.database }}.{{ this.schema }}.xirr(amount_3_year, cashflow_date, -0.01)
          ELSE NULL
        END AS irr_3_year,

        CASE
          WHEN MAX(five_year_cashflow_ind) = 1
          THEN {{ target.database }}.{{ this.schema }}.xirr(amount_5_year, cashflow_date, -0.01)
          ELSE NULL
        END AS irr_5_year,

        CASE
          WHEN MAX(ten_year_cashflow_ind) = 1
          THEN {{ target.database }}.{{ this.schema }}.xirr(amount_10_year, cashflow_date, -0.01)
          ELSE NULL
        END AS irr_10_year

    FROM cashflows
    GROUP BY fund_id, investor_id, currency_id, date_id
),

-- Final IRR-only output (investor + fund)
final_irrs AS (
  SELECT DISTINCT
    link.hk_link,
    hub.hk_fund,
    inv_hub.hk_investor,
    x.investor_id,
    x.fund_id,
    {{ to_date('x.date_id') }} as as_of_date,
    -- Carry-forward latest non-NULL IRRs per investor+fund
    LAST_VALUE(irr_inception) IGNORE NULLS OVER (
        PARTITION BY  x.investor_id,x.fund_id
        ORDER BY x.date_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS irr,

    LAST_VALUE(irr_1_year) IGNORE NULLS OVER (
        PARTITION BY  x.investor_id,x.fund_id
        ORDER BY x.date_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS irr_1_year,

    LAST_VALUE(irr_3_year) IGNORE NULLS OVER (
        PARTITION BY x.investor_id, x.fund_id
        ORDER BY x.date_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS irr_3_year,

    LAST_VALUE(irr_5_year) IGNORE NULLS OVER (
        PARTITION BY x.investor_id, x.fund_id
        ORDER BY x.date_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS irr_5_year,

    LAST_VALUE(irr_10_year) IGNORE NULLS OVER (
        PARTITION BY x.investor_id, x.fund_id
        ORDER BY x.date_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS irr_10_year

  FROM xirrs x
  JOIN {{ ref('hub_fund') }} hub
    ON x.fund_id = hub.fund_id
  JOIN {{ ref('hub_investor') }} inv_hub
    ON x.investor_id = inv_hub.investor_id
  JOIN {{ ref('link_investor_fund') }} link
    ON x.investor_id = link.investor_id
    AND x.fund_id = link.fund_id
   
)

SELECT DISTINCT
    hk_link as hk_link1, -- aliasing to avoid name conflict in the final join. The ambiguos column name appears from macro.
    hk_fund,
    hk_investor,
    investor_id,
    fund_id,
    as_of_date as as_of_date1, -- aliasing because ambiguos column name appears from macro after join. You can see the compiled query in sat_investor_fund_performance.
    sum(irr) as irr,
    sum(irr_1_year) as irr_1_year,
    sum(irr_3_year) as irr_3_year,  
    sum(irr_5_year) as irr_5_year,  
    sum(irr_10_year) as irr_10_year
FROM final_irrs
GROUP BY hk_link, hk_fund, hk_investor, investor_id, fund_id, as_of_date
ORDER BY as_of_date