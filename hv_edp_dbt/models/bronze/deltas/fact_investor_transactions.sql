{% set keys = ['date_id', 'investor_id', 'currency_id', 'fund_id', 'metric_id', 'is_transfer', 'exclude_transaction', 'monthly_date_id'] %}  

{{ load_delta_table('raw_from_harborview_edw', 'fact_investor_transactions', keys, True, False) }}