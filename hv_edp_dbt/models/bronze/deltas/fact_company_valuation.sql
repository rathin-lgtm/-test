{% set keys = ['company_id', 'fund_id', 'date_id', 'currency_id', 'loan_id', 'metric_id', 'position_id', 'original_company_id', 'public_status'] %}  

{{ load_delta_table('raw_from_harborview_edw', 'fact_company_valuation', keys, True, False) }}