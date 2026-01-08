WITH base_transactions AS (
    SELECT 
        hk_link,
        inv_tr.date_id AS as_of_date,
        cal_q.quarter_id,
        cal_q.quarter_desc,
        cal_q.quarter_counter,       
        inv_tr.currency_id,
        inv_tr.metric_id,
        inv_tr.amount,
        CURRENT_TIMESTAMP() AS load_dt
    FROM {{ source('bronze_from_harborview_edw', 'fact_investor_transactions') }} AS inv_tr
    JOIN    {{ ref('link_fund_investor_transaction') }} AS link 
        ON Concat(investor_name_id,date_id,currency_id,fund_id,metric_id,is_transfer,exclude_transaction,monthly_date_id) = link.composite_key
        LEFT JOIN {{ source('bronze_from_harborview_edw', 'calendar_quarter') }} AS cal_q
        ON inv_tr.date_id = cal_q.quarter_id
        JOIN {{ source('bronze_from_harborview_edw', 'dim_fund') }} dim_fund
        ON inv_tr.fund_id = dim_fund.fund_id 
    WHERE inv_tr.active_ind = 1
    AND inv_tr.exclude_transaction = 0
    AND dim_fund.type NOT IN ('Third Party Investor')
),

final_metrics AS(
    SELECT hk_link,
        as_of_date,
        quarter_id,
        quarter_desc,
        quarter_counter,       
        currency_id,
        {{ investor_distribution_in_total_exclude_total_transfers_transaction('metric_id', 'amount') }} +
        {{ investor_distribution_adjustment_transaction('metric_id', 'amount') }}  AS transaction_amount,
        'INVESTOR_DISTRIBUTION' AS transaction_type,
        MAX(load_dt) as load_dt
    FROM base_transactions
    GROUP BY hk_link, as_of_date, quarter_id, quarter_desc, quarter_counter, currency_id
    UNION ALL
    SELECT hk_link,
        as_of_date,
        quarter_id,
        quarter_desc,
        quarter_counter,       
        currency_id,
        {{ investor_capital_called_excludes_total_transfers_transaction('metric_id', 'amount') }} +
        {{ investor_contribution_adjustment_transaction('metric_id', 'amount') }}  AS transaction_amount,
        'INVESTOR_CONTRIBUTION' AS transaction_type,
        MAX(load_dt) as load_dt
    FROM base_transactions
    GROUP BY hk_link, as_of_date, quarter_id, quarter_desc, quarter_counter, currency_id
    UNION ALL
    SELECT hk_link,
        as_of_date,
        quarter_id,
        quarter_desc,
        quarter_counter,       
        currency_id,
        {{ investor_transaction_unfunded('metric_id', 'amount') }} +
        {{ calc_investor_transaction_contribution_in_cap_adjustment('metric_id', 'amount') }}  +
        {{ calc_investor_contribution_transactions_in_cap('metric_id', 'amount') }}as transaction_amount,
        'INVESTOR_COMMITMENT' AS transaction_type,
        MAX(load_dt) as load_dt
    FROM base_transactions
    GROUP BY hk_link, as_of_date, quarter_id, quarter_desc, quarter_counter, currency_id
    UNION ALL
    SELECT hk_link,
        as_of_date,
        quarter_id,
        quarter_desc,
        quarter_counter,       
        currency_id,
        {{ investor_distribution_in_total_exclude_total_transfers_transactions_m('metric_id', 'amount') }}  AS transaction_amount,
        'INVESTOR_DISTRIBUTION_IN_TOTAL_EXCLUDE_TOTAL_TRANSFERS' AS transaction_type,
        MAX(load_dt) as load_dt
    FROM base_transactions
    GROUP BY hk_link, as_of_date, quarter_id, quarter_desc, quarter_counter, currency_id
    UNION ALL
    SELECT hk_link,
        as_of_date,
        quarter_id,
        quarter_desc,
        quarter_counter,       
        currency_id,
        {{ investor_inception_transferred_contribution_component('metric_id', 'amount') }} -
        {{ investor_inception_transferred_distribution_component('metric_id', 'amount') }} +
        {{ investor_inception_transferred_income_expense_component('metric_id', 'amount') }}  AS transaction_amount,
        'INVESTOR_TRANSFER_OF_INTEREST' AS transaction_type,
        MAX(load_dt) as load_dt
    FROM base_transactions
    GROUP BY hk_link, as_of_date, quarter_id, quarter_desc, quarter_counter, currency_id
    UNION ALL
    SELECT hk_link,
        as_of_date,
        quarter_id,
        quarter_desc,
        quarter_counter,       
        currency_id,
        {{ investor_distribution_in_total_exclude_total_transfers_transaction('metric_id', 'amount') }} +
        {{ investor_distribution_adjustment_transaction('metric_id', 'amount') }}-
        {{ investor_withholding_m('metric_id', 'amount') }}  AS transaction_amount,
        'INVESTOR_DISTRIBUTION_NET_TRANSACTION' AS transaction_type,
        MAX(load_dt) as load_dt
    FROM base_transactions
    GROUP BY hk_link, as_of_date, quarter_id, quarter_desc, quarter_counter, currency_id
    UNION ALL
    SELECT hk_link,
        as_of_date,
        quarter_id,
        quarter_desc,
        quarter_counter,       
        currency_id,
        {{ investor_capital_called_excludes_total_transfers_transaction_m('metric_id', 'amount') }}  AS transaction_amount,
        'INVESTOR_CAPITAL_CALLED_EXCLUDES_TOTAL_TRANSFERS_TRANSACTION' AS transaction_type,
        MAX(load_dt) as load_dt
    FROM base_transactions
    GROUP BY hk_link, as_of_date, quarter_id, quarter_desc, quarter_counter, currency_id
    UNION ALL
    SELECT hk_link,
        as_of_date,
        quarter_id,
        quarter_desc,
        quarter_counter,       
        currency_id,
        {{ investor_withholding_m('metric_id', 'amount') }}  AS transaction_amount,
        'INVESTOR_WITHHOLDING_TRANSACTION' AS transaction_type,
        MAX(load_dt) as load_dt
    FROM base_transactions
    GROUP BY hk_link, as_of_date, quarter_id, quarter_desc, quarter_counter, currency_id
    UNION ALL
    SELECT hk_link,
        as_of_date,
        quarter_id,
        quarter_desc,
        quarter_counter,       
        currency_id,
        {{ investor_return_of_captial('metric_id', 'amount') }} as transaction_amount,
        'INVESTOR_RETURN_OF_CAPITAL_TRANSACTION' AS transaction_type,
        MAX(load_dt) as load_dt
    FROM base_transactions
    GROUP BY hk_link, as_of_date, quarter_id, quarter_desc, quarter_counter, currency_id
    UNION ALL
    SELECT hk_link,
        as_of_date,
        quarter_id,
        quarter_desc,
        quarter_counter,       
        currency_id,
        {{ unfunded_running('metric_id', 'amount') }} as transaction_amount,
        'INVESTOR_UNFUNDED_TRANSACTION' AS transaction_type,
        MAX(load_dt) as load_dt
    FROM base_transactions
    GROUP BY hk_link, as_of_date, quarter_id, quarter_desc, quarter_counter, currency_id
    UNION ALL
    SELECT hk_link,
        as_of_date,
        quarter_id,
        quarter_desc,
        quarter_counter,       
        currency_id,
        {{ investor_distribution_gain('metric_id', 'amount') }} as transaction_amount,
        'INVESTOR_DISTRIBUTION_GAIN_TRANSACTION' AS transaction_type,
        MAX(load_dt) as load_dt
    FROM base_transactions
    GROUP BY hk_link, as_of_date, quarter_id, quarter_desc, quarter_counter, currency_id
)

{{ append_hk_key_column('final_metrics') }}

