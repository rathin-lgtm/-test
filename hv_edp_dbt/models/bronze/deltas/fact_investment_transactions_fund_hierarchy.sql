{% set keys = ['cash_flow_id', 'fund_hier', 'loan_id', 'position_id', 'project_id', 'date_id', 'gl_date_id', 'currency_id', 'metric_id', 'cash_flow_type_id'] %}  

{{ load_delta_table('raw_from_harborview_edw', 'fact_investment_transactions_fund_hierarchy', keys, True, False) }}