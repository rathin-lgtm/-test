{{ config(pre_hook="{{ create_xirr_udf(this.schema) }}")}}
with monthly_metrics as (
    SELECT
    {{ to_date('transactions_monthly.date_id') }} as as_of_date,
    transactions_monthly.portfolio_id,
    transactions_monthly.fund_id,
    currency.currency_code,
    {{ portfolio_distributions('transactions_monthly.metric_id', 'transactions_monthly.running_monthly_amount', 'dim_portfolios.type_broad_id') }} as distributions,
    {{ portfolio_debt_borrowed('transactions_monthly.metric_id', 'transactions_monthly.running_monthly_amount') }} +
    {{ portfolio_calls_unlevered('transactions_monthly.metric_id', 'transactions_monthly.running_monthly_amount') }} +
    {{ portfolio_debt_deferred('transactions_monthly.metric_id', 'transactions_monthly.running_monthly_amount') }} as calls,
    CASE 
        WHEN calls = 0 THEN 0
        ELSE distributions / calls
    END as dpi,
    {{ portfolio_debt_borrowed('transactions_monthly.metric_id', 'transactions_monthly.running_monthly_amount') }} + 
    {{ portfolio_unfunded_unlevered('transactions_monthly.metric_id', 'transactions_monthly.running_monthly_amount') }} as commitments,
    {{ portfolio_debt_balance_no_directs('transactions_monthly.metric_id', 'transactions_monthly.running_monthly_amount', 'dim_portfolios.type_broad_id') }} as debt_balance_no_directs,
    FROM (
        SELECT * FROM {{ source('raw_from_harborview_edw', 'fact_investment_transactions_fund_hierarchy_monthly') }} WHERE date_flag in ('B', 'E') and portfolio_id != -1
    ) transactions_monthly
    JOIN {{ source('raw_from_harborview_edw', 'currency') }} currency
        ON transactions_monthly.currency_id = currency.currency_id
    JOIN {{ source('raw_from_harborview_edw', 'dim_portfolios') }} dim_portfolios
        ON transactions_monthly.portfolio_id = dim_portfolios.portfolio_id and transactions_monthly.fund_id = dim_portfolios.fund_id
    JOIN {{ source('raw_from_harborview_edw', 'dim_fund_hierarchy') }} dim_hierarchy
        ON transactions_monthly.fund_hier_id = dim_hierarchy.fund_hier_id and is_excluded = 0
    GROUP BY as_of_date, transactions_monthly.portfolio_id, currency_code, transactions_monthly.fund_id
),

daily_metrics as (
    SELECT 
    currency.currency_code,
    LAST_DAY({{ to_date('transactions.date_id') }}) as as_of_date,
    transactions.portfolio_id,
    transactions.fund_id,
    {{ portfolio_nav_no_deb_balance('transactions.metric_id', 'transactions.amount', 'dim_portfolios.asset_type_id') }} as nav_no_deb_balance,
    FROM (SELECT * FROM {{ source('raw_from_harborview_edw', 'fact_investment_transactions_fund_hierarchy') }} 
    WHERE gl_date_flag in ('M', 'MB') and portfolio_id != -1 ) transactions
    JOIN {{ source('raw_from_harborview_edw', 'currency') }} currency
        ON transactions.currency_id = currency.currency_id
    JOIN {{ source('raw_from_harborview_edw', 'dim_portfolios') }} dim_portfolios
        ON transactions.portfolio_id = dim_portfolios.portfolio_id and transactions.fund_id = dim_portfolios.fund_id
    JOIN {{ source('raw_from_harborview_edw', 'dim_fund_hierarchy') }} dim_hierarchy
        ON transactions.fund_hier_id = dim_hierarchy.fund_hier_id and is_excluded = 0
    GROUP BY as_of_date, transactions.portfolio_id, currency_code, transactions.fund_id
),

cashflows as (
    SELECT * FROM (
        SELECT
            fii.currency_id,
            fii.portfolio_id,
            fii.fund_id,
            amount,
            dfh.is_excluded,
            {{ portfolio_irr_cashflow_indicator_filter(1, 'fii.date_id', 'cal.rollup_to_date_id', 'fii.metric_id') }} as one_year_cashflow_ind,
            {{ portfolio_irr_cashflow_indicator_filter(2, 'fii.date_id', 'cal.rollup_to_date_id', 'fii.metric_id') }} as two_year_cashflow_ind,
            {{ portfolio_irr_cashflow_indicator_filter(3, 'fii.date_id', 'cal.rollup_to_date_id', 'fii.metric_id') }} as three_year_cashflow_ind,
            {{ portfolio_irr_cashflow_indicator_filter(4, 'fii.date_id', 'cal.rollup_to_date_id', 'fii.metric_id') }} as four_year_cashflow_ind,
            {{ portfolio_irr_cashflow_indicator_filter(5, 'fii.date_id', 'cal.rollup_to_date_id', 'fii.metric_id') }} as five_year_cashflow_ind,
            {{ portfolio_irr_cashflow_indicator_filter(7, 'fii.date_id', 'cal.rollup_to_date_id', 'fii.metric_id') }} as seven_year_cashflow_ind,
            {{ portfolio_irr_cashflow_indicator_filter(10, 'fii.date_id', 'cal.rollup_to_date_id', 'fii.metric_id') }} as ten_year_cashflow_ind,
            {{ portfolio_irr_cashflow_indicator_filter(15, 'fii.date_id', 'cal.rollup_to_date_id', 'fii.metric_id') }} as fifteen_year_cashflow_ind,
            {{ portfolio_irr_amount_filter_limited('fii.metric_id', 'fii.currency_id', 'fii.investment_currency_id', 'cal.Date_fact', 'cal.Date_Dim', 'cal.Date_1_Year', 'fii.amount') }} as amount_1_year,
            {{ portfolio_irr_amount_filter_limited('fii.metric_id', 'fii.currency_id', 'fii.investment_currency_id', 'cal.Date_fact', 'cal.Date_Dim', 'cal.Date_2_Year', 'fii.amount') }} as amount_2_year,
            {{ portfolio_irr_amount_filter_limited('fii.metric_id', 'fii.currency_id', 'fii.investment_currency_id', 'cal.Date_fact', 'cal.Date_Dim', 'cal.Date_3_Year', 'fii.amount') }} as amount_3_year,
            {{ portfolio_irr_amount_filter_limited('fii.metric_id', 'fii.currency_id', 'fii.investment_currency_id', 'cal.Date_fact', 'cal.Date_Dim', 'cal.Date_4_Year', 'fii.amount') }} as amount_4_year,
            {{ portfolio_irr_amount_filter_limited('fii.metric_id', 'fii.currency_id', 'fii.investment_currency_id', 'cal.Date_fact', 'cal.Date_Dim', 'cal.Date_5_Year', 'fii.amount') }} as amount_5_year,
            {{ portfolio_irr_amount_filter_limited('fii.metric_id', 'fii.currency_id', 'fii.investment_currency_id', 'cal.Date_fact', 'cal.Date_Dim', 'cal.Date_7_Year', 'fii.amount') }} as amount_7_year,
            {{ portfolio_irr_amount_filter_limited('fii.metric_id', 'fii.currency_id', 'fii.investment_currency_id', 'cal.Date_fact', 'cal.Date_Dim', 'cal.Date_10_Year', 'fii.amount') }} as amount_10_year,
            {{ portfolio_irr_amount_filter_limited('fii.metric_id', 'fii.currency_id', 'fii.investment_currency_id', 'cal.Date_fact', 'cal.Date_Dim', 'cal.Date_15_Year', 'fii.amount') }} as amount_15_year,
            {{ portfolio_irr_amount_filter_inception('fii.metric_id', 'fii.currency_id', 'fii.investment_currency_id', 'cal.Date_fact', 'cal.Date_Dim', 'fii.amount') }} as amount_inception,
            cal.Date_Fact as cashflow_date,
            fii.date_id as cashflow_date_id,
            rollup_to_date_id as date_id
        FROM {{ source('raw_from_harborview_edw', 'fact_irr_investment_fund_hierarchy') }} fii
        JOIN ({{ irr_calendar() }}) cal ON
            (fii.date_id = cal.rollup_date_id)
        JOIN {{ source('raw_from_harborview_edw', 'dim_fund_hierarchy') }} dfh ON
            (fii.fund_hier = dfh.fund_hier)
        WHERE fii.gl_date_flag in ('M', 'MB') AND fii.portfolio_id <> -1 AND fii.metric_id in ({{ portfolio_irr_cashflow_metric_ids() }})
    ) WHERE is_excluded = 0
),

xirrs as (
    SELECT 
        portfolio_id,
        fund_id,
        currency.currency_code,
        {{ to_date('date_id') }} as as_of_date,
        irr_inception as irr
    FROM (
        SELECT
            portfolio_id,
            currency_id,
            date_id,
            fund_id,
            {{ target.database }}.{{ this.schema }}.xirr(amount_inception, cashflow_date, -0.01) * max(one_year_cashflow_ind) as irr_inception
        FROM cashflows
        GROUP BY portfolio_id, currency_id, date_id, fund_id
    ) irrs
    JOIN {{ source('raw_from_harborview_edw', 'currency') }} currency
        ON irrs.currency_id = currency.currency_id
),

final_metrics as (
SELECT 
    monthly.as_of_date,
    hk_link,
    monthly.currency_code as metric_currency_code,
    distributions,
    calls,
    dpi,
    commitments,
    debt_balance_no_directs + COALESCE(nav_no_deb_balance, 0) as nav,
    COALESCE(distributions + nav, 0) as total_value,
    CASE 
        WHEN calls = 0 THEN 0
        ELSE total_value / calls
    END as tvpi,
    COALESCE(total_value - calls, 0) as gain_loss,
    COALESCE(xirrs.irr, 0) as irr,
    CURRENT_TIMESTAMP() as load_dt,
    FROM monthly_metrics monthly
    LEFT JOIN daily_metrics daily 
        ON daily.portfolio_id = monthly.portfolio_id and daily.as_of_date = monthly.as_of_date and daily.currency_code = monthly.currency_code and daily.fund_id = monthly.fund_id
    LEFT JOIN xirrs
        ON monthly.portfolio_id = xirrs.portfolio_id AND xirrs.as_of_date = monthly.as_of_date and xirrs.currency_code = monthly.currency_code and xirrs.fund_id = monthly.fund_id
    JOIN {{ ref('link_portfolio_fund') }} link
        ON monthly.portfolio_id = link.portfolio_id
        AND monthly.fund_id = link.fund_id
    ORDER BY as_of_date
)

{{ append_hk_key_column('final_metrics') }}
