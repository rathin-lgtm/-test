SELECT DISTINCT
        hk_link,
        as_of_date,
        quarter_id,
        quarter_desc,
        quarter_counter,       
        currency_id,
        CASE WHEN transaction_type = 'INVESTOR_DISTRIBUTION' THEN  transaction_amount ELSE 0 END AS investor_distribution_amount,
        CASE WHEN transaction_type = 'INVESTOR_CONTRIBUTION' THEN  transaction_amount ELSE 0 END AS investor_contribution_amount,
        CASE WHEN transaction_type = 'INVESTOR_COMMITMENT' THEN  transaction_amount ELSE 0 END AS investor_commitment_amount,
        CASE WHEN transaction_type = 'INVESTOR_TRANSFER_OF_INTEREST' THEN  transaction_amount ELSE 0 END AS investor_transfer_of_interest_amount,
        CASE WHEN transaction_type = 'INVESTOR_DISTRIBUTION_IN_TOTAL_EXCLUDE_TOTAL_TRANSFERS' THEN  transaction_amount ELSE 0 END AS investor_distribution_in_total_exclude_total_transfers_amount,
        CASE WHEN transaction_type = 'INVESTOR_DISTRIBUTION_NET_TRANSACTION' THEN  transaction_amount ELSE 0 END AS investor_distribution_net_transaction_amount,
        CASE WHEN transaction_type = 'INVESTOR_CAPITAL_CALLED_EXCLUDES_TOTAL_TRANSFERS_TRANSACTION' THEN  transaction_amount ELSE 0 END AS investor_capital_called_excludes_total_transfers_transaction

FROM {{ ref('sat_investor_daily_transaction') }}