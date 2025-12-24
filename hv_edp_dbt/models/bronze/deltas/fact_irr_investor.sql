{% set keys = ['inv_fund_id', 'investor_name_id', 'child_fund_id', 'date_id', 'currency_id', 'metric_id', 'active_ind'] %}  

{{ load_delta_table('raw_from_harborview_edw', 'fact_irr_investor', keys) }}