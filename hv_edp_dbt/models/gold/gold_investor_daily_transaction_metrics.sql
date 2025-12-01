SELECT DISTINCT
        hk_link,
        as_of_date,
        quarter_id,
        quarter_desc,
        quarter_counter,       
        currency_id,
        CASE WHEN transaction_type = 'INVESTOR_DISTRIBUTION' THEN  Transaction_Amount Else 0 End as INVESTOR_DISTRIBUTION_AMOUNT,
        CASE WHEN transaction_type = 'INVESTOR_CONTRIBUTION' THEN  Transaction_Amount Else 0 End as INVESTOR_CONTRIBUTION_AMOUNT,
        CASE WHEN transaction_type = 'INVESTOR_COMMITMENT' THEN  Transaction_Amount Else 0 End as INVESTOR_COMMITMENT_AMOUNT,
        CASE WHEN transaction_type = 'INVESTOR_TRANSFER_OF_INTEREST' THEN  Transaction_Amount Else 0 End as INVESTOR_TRANSFER_OF_INTEREST_AMOUNT,
        CASE WHEN transaction_type = 'INVESTOR_DISTRIBUTION_IN_TOTAL_EXCLUDE_TOTAL_TRANSFERS' THEN  Transaction_Amount Else 0 End as INVESTOR_DISTRIBUTION_IN_TOTAL_EXCLUDE_TOTAL_TRANSFERS_AMOUNT,
        CASE WHEN transaction_type = 'INVESTOR_DISTRIBUTION_NET_TRANSACTION' THEN  Transaction_Amount Else 0 End as INVESTOR_DISTRIBUTION_NET_TRANSACTION_AMOUNT,

FROM {{ ref('sat_investor_daily_transaction') }}