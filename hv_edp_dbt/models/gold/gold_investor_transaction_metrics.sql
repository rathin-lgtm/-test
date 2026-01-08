with daily as (
	SELECT
		link.hk_investor,
		link.hk_fund,
		metrics.as_of_date,
		quarter_desc,
		currency_id,
		SUM(CASE WHEN transaction_type = 'INVESTOR_DISTRIBUTION' THEN  transaction_amount ELSE 0 END) AS investor_distribution_amount,
		SUM(CASE WHEN transaction_type = 'INVESTOR_DISTRIBUTION_GAIN_TRANSACTION' THEN  transaction_amount ELSE 0 END) AS investor_distribution_gain_amount,
		SUM(CASE WHEN transaction_type = 'INVESTOR_CONTRIBUTION' THEN  transaction_amount ELSE 0 END) AS investor_contribution_amount,
		SUM(CASE WHEN transaction_type = 'INVESTOR_COMMITMENT' THEN  transaction_amount ELSE 0 END) AS investor_commitment_amount,
		SUM(CASE WHEN transaction_type = 'INVESTOR_TRANSFER_OF_INTEREST' THEN  transaction_amount ELSE 0 END) AS investor_transfer_of_interest_amount,
		SUM(CASE WHEN transaction_type = 'INVESTOR_DISTRIBUTION_IN_TOTAL_EXCLUDE_TOTAL_TRANSFERS' THEN  transaction_amount ELSE 0 END) AS investor_distribution_in_total_exclude_total_transfers_amount,
		SUM(CASE WHEN transaction_type = 'INVESTOR_DISTRIBUTION_NET_TRANSACTION' THEN  transaction_amount ELSE 0 END) AS investor_distribution_net_transaction_amount,
		SUM(CASE WHEN transaction_type = 'INVESTOR_CAPITAL_CALLED_EXCLUDES_TOTAL_TRANSFERS_TRANSACTION' THEN  transaction_amount ELSE 0 END) AS investor_capital_called_excludes_total_transfers_transaction_amount,
		SUM(CASE WHEN transaction_type = 'INVESTOR_WITHHOLDING_TRANSACTION' THEN  transaction_amount ELSE 0 END) AS investor_withholding_transaction_amount,
		SUM(CASE WHEN transaction_type = 'INVESTOR_RETURN_OF_CAPITAL_TRANSACTION' THEN  transaction_amount ELSE 0 END) AS investor_return_of_capital_transaction_amount,
		SUM(CASE WHEN transaction_type = 'INVESTOR_UNFUNDED_TRANSACTION' THEN  transaction_amount ELSE 0 END) AS investor_unfunded_transaction_amount
	FROM {{ ref('sat_investor_daily_transaction') }} metrics
	JOIN {{ ref('link_fund_investor_transaction') }} link
		ON metrics.hk_link = link.hk_link
	GROUP BY hk_investor, hk_fund, as_of_date, quarter_desc, currency_id
),

rolled_transactions as (
	SELECT
		hk_investor,
		hk_fund,
		as_of_date,
		quarter_desc,
		currency_id,
		{{ investor_transaction_rollup('investor_distribution_amount') }} as investor_distribution_amount,
		{{ investor_transaction_rollup('investor_distribution_gain_amount') }} as investor_distribution_gain_amount,
		{{ investor_transaction_rollup('investor_contribution_amount') }} as investor_contribution_amount,
		{{ investor_transaction_rollup('investor_commitment_amount') }} as investor_commitment_amount,
		{{ investor_transaction_rollup('investor_transfer_of_interest_amount') }} as investor_transfer_of_interest_amount,
		{{ investor_transaction_rollup('investor_distribution_in_total_exclude_total_transfers_amount') }} as investor_distribution_in_total_exclude_total_transfers_amount,
		{{ investor_transaction_rollup('investor_distribution_net_transaction_amount') }} as investor_distribution_net_transaction_amount,
		{{ investor_transaction_rollup('investor_capital_called_excludes_total_transfers_transaction_amount') }} as investor_capital_called_excludes_total_transfers_transaction_amount,
		{{ investor_transaction_rollup('investor_withholding_transaction_amount') }} as investor_withholding_transaction_amount,
		{{ investor_transaction_rollup('investor_return_of_capital_transaction_amount') }} as investor_return_of_capital_transaction_amount,
		{{ investor_transaction_rollup('investor_unfunded_transaction_amount') }} as investor_unfunded_transaction_amount
	FROM daily
)

SELECT
    rolled.as_of_date,
	rolled.as_of_date as investor_transaction_date,
	rolled.quarter_desc as investor_transaction_quarter,
    attributes.efront_investor_id,
    fund_attributes.efront_fund_id,
    short_name as investor_name,
    parent_group_id as investor_group_id,
    parent_group_name as investor_group_name,
    region as investor_region,
	rolled.investor_distribution_amount as investor_distribution_transaction,
	rolled.investor_distribution_gain_amount as investor_distribution_gain_transaction,
	rolled.investor_contribution_amount as investor_contribution_transaction,
	rolled.investor_commitment_amount as investor_commitment_transaction,
	rolled.investor_transfer_of_interest_amount as investor_transfer_of_interest_transaction,
	rolled.investor_distribution_in_total_exclude_total_transfers_amount as investor_distribution_in_total_exclude_total_transfers_transaction,
	rolled.investor_distribution_net_transaction_amount as investor_distribution_net_transaction,
	rolled.investor_capital_called_excludes_total_transfers_transaction_amount as investor_capital_called_excludes_total_transfers_transaction,
	rolled.investor_withholding_transaction_amount as investor_withholding_transaction,
	rolled.investor_return_of_capital_transaction_amount as investor_return_of_captial_transaction,
	rolled.investor_unfunded_transaction_amount as unfunded,
	{{ safe_division(['rolled.investor_capital_called_excludes_total_transfers_transaction_amount'], ['rolled.investor_commitment_amount']) }} as investor_percent_called,
	{{ safe_division(['rolled.investor_distribution_amount'], ['rolled.investor_contribution_amount']) }} as investor_percent_distributed
FROM rolled_transactions rolled
JOIN {{ ref('sat_investor_attributes') }} attributes
    ON attributes.hk_investor = rolled.hk_investor
JOIN {{ ref('sat_fund_attributes') }} fund_attributes
    ON rolled.hk_fund = fund_attributes.hk_fund
ORDER BY as_of_date
