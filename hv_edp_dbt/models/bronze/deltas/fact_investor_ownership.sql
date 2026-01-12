{% set keys = ['investor_name_id', 'fund_hier', 'start_date'] %}  

{{ load_delta_table('raw_from_harborview_edw', 'fact_investor_ownership', keys, False, True) }}