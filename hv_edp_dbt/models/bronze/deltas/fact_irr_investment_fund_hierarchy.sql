{% set keys = ['date_id', 'gl_date_id', 'gl_date_flag', 'direct_company_id', 'fund_hier', 'loan_id', 'position_id', 'currency_id', 'metric_id', 'investment_currency_id'] %}  

{{ load_delta_table('raw_from_harborview_edw', 'fact_irr_investment_fund_hierarchy', keys, True, False) }}