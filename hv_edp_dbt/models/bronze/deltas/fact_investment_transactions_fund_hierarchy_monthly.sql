{% set keys = ['date_id', 'date_flag', 'fund_hier', 'loan_id', 'portfolio_investment_id', 'position_id', 'project_id', 'currency_id', 'metric_id', 'investment_currency_id'] %}  

{{ load_delta_table('raw_from_harborview_edw', 'fact_investment_transactions_fund_hierarchy_monthly', keys) }}