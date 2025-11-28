
WITH investor_transaction_metrics AS (
    SELECT hk_link,
        {{ Investor_Capital_Called_Excludes_Total_Transfers_Transaction('inv_tr.metric_id', 'inv_tr.amount') }} +
        {{ Investor_Contribution_Adjustment_Transaction('inv_tr.metric_id', 'inv_tr.amount') }}  as Investor_Contribution_Transaction,
        {{ CALC_Investor_Contribution_Transaction_in_Cap('inv_tr.metric_id', 'inv_tr.amount') }} +
        {{ Investor_Transaction_Unfunded('inv_tr.metric_id', 'inv_tr.amount') }} +
        {{ CALC_Investor_Transaction_Contribution_in_Cap_Adjustment('inv_tr.metric_id', 'inv_tr.amount') }} as Investor_Commitment_Transaction,
        {{ Investor_Distribution_in_Total_excludeTotal_Transfers_Transaction('inv_tr.metric_id', 'inv_tr.amount') }} +
        {{ Investor_Distribution_Adjustment_Transaction('inv_tr.metric_id', 'inv_tr.amount') }} as Investor_Distribution_Transaction,
        {{ Investor_WithHolding_('inv_tr.metric_id', 'inv_tr.amount') }} as Investor_WithHolding,
        Investor_Distribution_Transaction - Investor_WithHolding as Investor_Distribution_Net_Transaction,
        {{ Investor_Inception_Transferred_Contribution_Component('inv_tr.metric_id', 'inv_tr.amount') }} -
        {{ Investor_Inception_Transferred_Distribution_Component('inv_tr.metric_id', 'inv_tr.amount') }} +
        {{ Investor_Inception_Transferred_Income_Expense_Component('inv_tr.metric_id', 'inv_tr.amount') }} as Investor_Transfer_of_Interest,
        CURRENT_TIMESTAMP() as load_dt
    FROM {{ source('bronze_from_harborview_edw', 'fact_investor_transactions') }} as inv_tr
    JOIN    {{ ref('link_fund_investor_transaction') }} as link
        On Concat(investor_id,date_id,currency_id,fund_id,metric_id,is_transfer,exclude_transaction,monthly_date_id) = link.composite_key
    JOIN {{ source('bronze_from_harborview_edw', 'dim_fund') }} dim_fund
        ON inv_tr.fund_id = dim_fund.fund_id 
    WHERE inv_tr.active_ind = 1
    AND inv_tr.exclude_transaction = 0
    AND dim_fund.type not in ('Third Party Investor')
    GROUP BY hk_link
), -- the nav metric would be ued in tvs_sales metric calculation
running_sum_nav_metrics as (
    SELECT hk_link,
        {{ Running_Sum_Capital_Call_in_Total_FX_Trend('inv_tr.metric_id', 'inv_tr.amount') }} -
        {{ Running_Sum_Distribution_in_Total_FX_Trend('inv_tr.metric_id', 'inv_tr.amount') }} +
        {{ Running_Sum_Income_Expense_in_Total_FX_Trend('inv_tr.metric_id', 'inv_tr.amount') }} as Running_Sum_of_Investor_NAV_in_Total
    FROM {{ source('bronze_from_harborview_edw', 'fact_investor_transactions') }} as inv_tr
    JOIN    {{ ref('link_fund_investor_transaction') }} as link
        On Concat(investor_id,date_id,currency_id,fund_id,metric_id,is_transfer,exclude_transaction,monthly_date_id) = link.composite_key
    JOIN {{ source('bronze_from_harborview_edw', 'dim_fund') }} dim_fund
        ON inv_tr.fund_id = dim_fund.fund_id 
        WHERE inv_tr.active_ind = 1
    AND inv_tr.exclude_transaction = 0
    AND dim_fund.type not in ('Third Party Investor')
    And inv_tr.date_id <= dim_fund.Lock_date_eqt 
    GROUP BY hk_link
), 
-- we are calculating tvs_sales in different parts because of different filters
tvf_sales_metrics_first_part as (
    SELECT hk_link,
        coalesce({{ total_value_sales_aggregation('inv_tr.metric_id', 'inv_tr.amount') }}, 0) as Total_Value_of_Investor_TVF_Sales_First_Part
    FROM {{ source('bronze_from_harborview_edw', 'fact_investor_transactions') }} as inv_tr
    JOIN    {{ ref('link_fund_investor_transaction') }} as link
        On Concat(investor_id,date_id,currency_id,fund_id,metric_id,is_transfer,exclude_transaction,monthly_date_id) = link.composite_key
    JOIN {{ source('bronze_from_harborview_edw', 'dim_fund') }} dim_fund
        ON inv_tr.fund_id = dim_fund.fund_id 
        WHERE inv_tr.active_ind = 1
    AND inv_tr.exclude_transaction = 0
    AND dim_fund.type not in ('Third Party Investor')
    And inv_tr.is_transfered  = 2
    And inv_tr.date_id > dim_fund.Lock_date_eqt 
    GROUP BY hk_link
),
tvf_sales_metrics_second_part as (
    SELECT hk_link,
        coalesce({{ total_value_sales_aggregation('inv_tr.metric_id', 'inv_tr.amount') }}, 0) as Total_Value_of_Investor_TVF_Sales_Second_Part
    FROM {{ source('bronze_from_harborview_edw', 'fact_investor_transactions') }} as inv_tr
    JOIN    {{ ref('link_fund_investor_transaction') }} as link
        On Concat(investor_id,date_id,currency_id,fund_id,metric_id,is_transfer,exclude_transaction,monthly_date_id) = link.composite_key
    JOIN {{ source('bronze_from_harborview_edw', 'dim_fund') }} dim_fund
        ON inv_tr.fund_id = dim_fund.fund_id 
        WHERE inv_tr.active_ind = 1
    AND inv_tr.exclude_transaction = 0
    AND dim_fund.type not in ('Third Party Investor')
    And inv_tr.is_transfered  = 1
    And inv_tr.date_id > dim_fund.Lock_date_eqt 
    GROUP BY hk_link
),
tvf_sales_metrics_investor_distribution_part as (
    SELECT hk_link,
        coalesce({{ investor_distribution_('inv_tr.metric_id', 'inv_tr.amount') }}, 0) as investor_distribution_part
    FROM {{ source('bronze_from_harborview_edw', 'fact_investor_transactions') }} as inv_tr
    JOIN    {{ ref('link_fund_investor_transaction') }} as link
        On Concat(investor_id,date_id,currency_id,fund_id,metric_id,is_transfer,exclude_transaction,monthly_date_id) = link.composite_key
    JOIN {{ source('bronze_from_harborview_edw', 'dim_fund') }} dim_fund
        ON inv_tr.fund_id = dim_fund.fund_id 
        WHERE inv_tr.active_ind = 1
    --AND inv_tr.exclude_transaction = 0
    AND dim_fund.type not in ('Third Party Investor')
    And inv_tr.is_transfered  = 1
    --And inv_tr.date_id > dim_fund.Lock_date_eqt 
    GROUP BY hk_link
),
tvf_sales_metrics_nav_part as (
    SELECT hk_link,
        coalesce({{ total_value_sales_nav_aggregation('inv_tr.metric_id', 'inv_tr.amount') }}, 0) as nav_aggregation_part
    FROM {{ source('bronze_from_harborview_edw', 'fact_investor_transactions') }} as inv_tr
    JOIN    {{ ref('link_fund_investor_transaction') }} as link
        On Concat(investor_id,date_id,currency_id,fund_id,metric_id,is_transfer,exclude_transaction,monthly_date_id) = link.composite_key
    JOIN {{ source('bronze_from_harborview_edw', 'dim_fund') }} dim_fund
        ON inv_tr.fund_id = dim_fund.fund_id 
        WHERE inv_tr.active_ind = 1
    AND inv_tr.exclude_transaction = 0
    AND dim_fund.type not in ('Third Party Investor')
    --And inv_tr.is_transfered  = 1
    --And inv_tr.date_id > dim_fund.Lock_date_eqt 
    GROUP BY hk_link
),
tvs_sales_metrics as (
    SELECT 
        first_part.hk_link,
        first_part.Total_Value_of_Investor_TVF_Sales_First_Part +
        second_part.Total_Value_of_Investor_TVF_Sales_Second_Part +
        distribution_part.investor_distribution_part +
            nav_metrics.nav_aggregation_part
        as Total_Value_of_Investor_TVS_Sales
    FROM tvf_sales_metrics_first_part as first_part
    JOIN tvf_sales_metrics_second_part as second_part
        ON first_part.hk_link = second_part.hk_link
    JOIN tvf_sales_metrics_investor_distribution_part as distribution_part
        ON first_part.hk_link = distribution_part.hk_link
    JOIN tvf_sales_metrics_nav_part as nav_metrics
        ON first_part.hk_link = nav_metrics.hk_link
),



final_metrics as ( 
    SELECT  itm.hk_link,
    coalesce(Investor_Contribution_Transaction, 0) as Investor_Contribution_Transaction,
    coalesce(Investor_Commitment_Transaction, 0) as Investor_Commitment_Transaction,
    coalesce(Investor_Distribution_Transaction, 0) as Investor_Distribution_Transaction,
    coalesce(Investor_WithHolding, 0) as Investor_WithHolding,
    coalesce(Investor_Distribution_Net_Transaction, 0) as Investor_Distribution_Net_Transaction,
    coalesce(Investor_Transfer_of_Interest, 0) as Investor_Transfer_of_Interest,
    coalesce(Running_Sum_of_Investor_NAV_in_Total, 0) as Running_Sum_of_Investor_NAV_in_Total,
    coalesce(Total_Value_of_Investor_TVS_Sales, 0) as Total_Value_of_Investor_TVS_Sales,
    load_dt
    FROM investor_transaction_metrics itm LEFT JOIN running_sum_nav_metrics nm
        ON itm.hk_link = nm.hk_link LEFT JOIN tvs_sales_metrics tsm
        ON itm.hk_link = tsm.hk_link
)

{{ append_hk_key_column('final_metrics') }}
