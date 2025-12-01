With distribution_transactions as(
    SELECT hk_link,
    inv_tr.date_id,
        cal_q.quarter_id,
        cal_q.quarter_desc,
        cal_q.quarter_counter,       
        inv_tr.currency_id,
        {{ Investor_Distribution_in_Total_excludeTotal_Transfers_Transaction('inv_tr.metric_id', 'inv_tr.amount') }} +
        {{ Investor_Distribution_Adjustment_Transaction('inv_tr.metric_id', 'inv_tr.amount') }}  as Transaction_Amount,
        'INVESTOR_DISTRIBUTION' as transaction_type,
        CURRENT_TIMESTAMP() as load_dt
    FROM {{ source('bronze_from_harborview_edw', 'fact_investor_transactions') }} as inv_tr
    JOIN    {{ ref('link_fund_investor_transaction') }} as link 
        On Concat(investor_id,date_id,currency_id,fund_id,metric_id,is_transfer,exclude_transaction,monthly_date_id) = link.composite_key
        LEFT JOIN {{ source('bronze_from_harborview_edw', 'calendar_quarter') }} as cal_q
        ON inv_tr.date_id = cal_q.quarter_id
        JOIN {{ source('bronze_from_harborview_edw', 'dim_fund') }} dim_fund
        ON inv_tr.fund_id = dim_fund.fund_id 
    WHERE inv_tr.active_ind = 1
    AND inv_tr.exclude_transaction = 0
    AND dim_fund.type not in ('Third Party Investor')
    GROUP BY hk_link,date_id,quarter_id,quarter_desc,quarter_counter,inv_tr.currency_id
),
contribution_transactions as(
    SELECT hk_link,
    inv_tr.date_id,
        cal_q.quarter_id,
        cal_q.quarter_desc,
        cal_q.quarter_counter,       
        inv_tr.currency_id,
        {{ Investor_Capital_Called_Excludes_Total_Transfers_Transaction('inv_tr.metric_id', 'inv_tr.amount') }} +
        {{ Investor_Contribution_Adjustment_Transaction('inv_tr.metric_id', 'inv_tr.amount') }}  as Transaction_Amount,
        'INVESTOR_CONTRIBUTION' as transaction_type,
        CURRENT_TIMESTAMP() as load_dt
    FROM {{ source('bronze_from_harborview_edw', 'fact_investor_transactions') }} as inv_tr
    JOIN    {{ ref('link_fund_investor_transaction') }} as link
        On Concat(investor_id,date_id,currency_id,fund_id,metric_id,is_transfer,exclude_transaction,monthly_date_id) = link.composite_key
        LEFT JOIN {{ source('bronze_from_harborview_edw', 'calendar_quarter') }} as cal_q
        ON inv_tr.date_id = cal_q.quarter_id
        JOIN {{ source('bronze_from_harborview_edw', 'dim_fund') }} dim_fund
        ON inv_tr.fund_id = dim_fund.fund_id 
    WHERE inv_tr.active_ind = 1
    AND inv_tr.exclude_transaction = 0
    AND dim_fund.type not in ('Third Party Investor')
    GROUP BY hk_link,date_id,quarter_id,quarter_desc,quarter_counter,inv_tr.currency_id
),
commitment_transactions as(
    SELECT hk_link,
    inv_tr.date_id,
        cal_q.quarter_id,
        cal_q.quarter_desc,
        cal_q.quarter_counter,       
        inv_tr.currency_id,
        {{ Investor_Transaction_Unfunded('inv_tr.metric_id', 'inv_tr.amount') }} +
        {{ CALC_Investor_Transaction_Contribution_in_Cap_Adjustment('inv_tr.metric_id', 'inv_tr.amount') }}  as Transaction_Amount,
        'INVESTOR_COMMITMENT' as transaction_type,
        CURRENT_TIMESTAMP() as load_dt
    FROM {{ source('bronze_from_harborview_edw', 'fact_investor_transactions') }} as inv_tr
    JOIN    {{ ref('link_fund_investor_transaction') }} as link
        On Concat(investor_id,date_id,currency_id,fund_id,metric_id,is_transfer,exclude_transaction,monthly_date_id) = link.composite_key
        LEFT JOIN {{ source('bronze_from_harborview_edw', 'calendar_quarter') }} as cal_q
        ON inv_tr.date_id = cal_q.quarter_id
        JOIN {{ source('bronze_from_harborview_edw', 'dim_fund') }} dim_fund
        ON inv_tr.fund_id = dim_fund.fund_id 
    WHERE inv_tr.active_ind = 1
    AND inv_tr.exclude_transaction = 0
    AND dim_fund.type not in ('Third Party Investor')
    GROUP BY hk_link,date_id,quarter_id,quarter_desc,quarter_counter,inv_tr.currency_id
),
Investor_Distribution_in_Total_Exclude_Total_Transfers_Transactions as(
    SELECT hk_link,
    inv_tr.date_id,
        cal_q.quarter_id,
        cal_q.quarter_desc,
        cal_q.quarter_counter,       
        inv_tr.currency_id,
        {{ Investor_Distribution_in_Total_ExcludeTotal_Transfers_Transactions_('inv_tr.metric_id', 'inv_tr.amount') }}  as Transaction_Amount,
        'INVESTOR_DISTRIBUTION_IN_TOTAL_EXCLUDE_TOTAL_TRANSFERS' as transaction_type,
        CURRENT_TIMESTAMP() as load_dt
    FROM {{ source('bronze_from_harborview_edw', 'fact_investor_transactions') }} as inv_tr
    JOIN    {{ ref('link_fund_investor_transaction') }} as link
        On Concat(investor_id,date_id,currency_id,fund_id,metric_id,is_transfer,exclude_transaction,monthly_date_id) = link.composite_key
        LEFT JOIN {{ source('bronze_from_harborview_edw', 'calendar_quarter') }} as cal_q
        ON inv_tr.date_id = cal_q.quarter_id
        JOIN {{ source('bronze_from_harborview_edw', 'dim_fund') }} dim_fund
        ON inv_tr.fund_id = dim_fund.fund_id 
    WHERE inv_tr.active_ind = 1
    AND inv_tr.exclude_transaction = 0
    AND dim_fund.type not in ('Third Party Investor')
    GROUP BY hk_link,date_id,quarter_id,quarter_desc,quarter_counter,inv_tr.currency_id
),
Investor_Transfer_of_Interest_Transactions as(
    SELECT hk_link,
    inv_tr.date_id,
        cal_q.quarter_id,
        cal_q.quarter_desc,
        cal_q.quarter_counter,       
        inv_tr.currency_id,
        {{ Investor_Inception_Transferred_Contribution_Component('inv_tr.metric_id', 'inv_tr.amount') }} -
        {{ Investor_Inception_Transferred_Distribution_Component('inv_tr.metric_id', 'inv_tr.amount') }} +
        {{ Investor_Inception_Transferred_Income_Expense_Component('inv_tr.metric_id', 'inv_tr.amount') }}  as Transaction_Amount,
        'INVESTOR_TRANSFER_OF_INTEREST' as transaction_type,
        CURRENT_TIMESTAMP() as load_dt
    FROM {{ source('bronze_from_harborview_edw', 'fact_investor_transactions') }} as inv_tr
    JOIN    {{ ref('link_fund_investor_transaction') }} as link
        On Concat(investor_id,date_id,currency_id,fund_id,metric_id,is_transfer,exclude_transaction,monthly_date_id) = link.composite_key
        LEFT JOIN {{ source('bronze_from_harborview_edw', 'calendar_quarter') }} as cal_q
        ON inv_tr.date_id = cal_q.quarter_id
        JOIN {{ source('bronze_from_harborview_edw', 'dim_fund') }} dim_fund
        ON inv_tr.fund_id = dim_fund.fund_id 
    WHERE inv_tr.active_ind = 1
    AND inv_tr.exclude_transaction = 0
    AND dim_fund.type not in ('Third Party Investor')
    GROUP BY hk_link,date_id,quarter_id,quarter_desc,quarter_counter,inv_tr.currency_id
),
Investor_Distribution_Net_Transaction as(
    SELECT hk_link,
    inv_tr.date_id,
        cal_q.quarter_id,
        cal_q.quarter_desc,
        cal_q.quarter_counter,       
        inv_tr.currency_id,
        {{ Investor_Distribution_in_Total_excludeTotal_Transfers_Transaction('inv_tr.metric_id', 'inv_tr.amount') }} +
        {{ Investor_Distribution_Adjustment_Transaction('inv_tr.metric_id', 'inv_tr.amount') }}-
        {{ Investor_WithHolding_('inv_tr.metric_id', 'inv_tr.amount') }}  as Transaction_Amount,
        'INVESTOR_DISTRIBUTION_NET_TRANSACTION' as transaction_type,
        CURRENT_TIMESTAMP() as load_dt
    FROM {{ source('bronze_from_harborview_edw', 'fact_investor_transactions') }} as inv_tr
    JOIN    {{ ref('link_fund_investor_transaction') }} as link
        On Concat(investor_id,date_id,currency_id,fund_id,metric_id,is_transfer,exclude_transaction,monthly_date_id) = link.composite_key
        LEFT JOIN {{ source('bronze_from_harborview_edw', 'calendar_quarter') }} as cal_q
        ON inv_tr.date_id = cal_q.quarter_id
        JOIN {{ source('bronze_from_harborview_edw', 'dim_fund') }} dim_fund
        ON inv_tr.fund_id = dim_fund.fund_id 
    WHERE inv_tr.active_ind = 1
    AND inv_tr.exclude_transaction = 0
    AND dim_fund.type not in ('Third Party Investor')
    GROUP BY hk_link,date_id,quarter_id,quarter_desc,quarter_counter,inv_tr.currency_id
),
final_metrics as(
    Select hk_link,
    date_id,
    date_id as as_of_date,
        quarter_id,
        quarter_desc,
        quarter_counter,       
        currency_id,
        Transaction_Amount,
        transaction_type,
        load_dt
    From distribution_transactions
    Union
    Select hk_link,
    date_id, 
    date_id as as_of_date,
        quarter_id,
        quarter_desc,
        quarter_counter,       
        currency_id,
        Transaction_Amount,
        transaction_type,
        load_dt
    From contribution_transactions
    Union
    Select hk_link,
    date_id,
    date_id as as_of_date,
        quarter_id,
        quarter_desc,
        quarter_counter,       
        currency_id,
        Transaction_Amount,
        transaction_type,
        load_dt
    From commitment_transactions
    Union
    Select hk_link,
    date_id,
    date_id as as_of_date,
        quarter_id,
        quarter_desc,
        quarter_counter,       
        currency_id,
        Transaction_Amount,
        transaction_type,
        load_dt
    From Investor_Transfer_of_Interest_Transactions
    Union
    Select hk_link,
    date_id,
    date_id as as_of_date,
        quarter_id,
        quarter_desc,
        quarter_counter,       
        currency_id,
        Transaction_Amount,
        transaction_type,
        load_dt
    From Investor_Distribution_in_Total_Exclude_Total_Transfers_Transactions
    Union
    Select hk_link,
    date_id,
    date_id as as_of_date,
        quarter_id,
        quarter_desc,
        quarter_counter,       
        currency_id,
        Transaction_Amount,
        transaction_type,
        load_dt
    From Investor_Distribution_Net_Transaction
)

{{ append_hk_key_column('final_metrics') }}

