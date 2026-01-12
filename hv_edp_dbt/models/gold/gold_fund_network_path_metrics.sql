SELECT
        fund_sub_perspective_id, 
        hier_percentage, 
        hier_amount,
        fund_hier_id, 
        fund_hier,
        load_dt::date as as_of_date
FROM {{ ref('fund_network_path_standalone') }} 
