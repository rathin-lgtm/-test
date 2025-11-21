SELECT 
    as_of_date,
    holding_currency,
    holding_commitment_unlevered
FROM {{ ref('sat_holding_metrics') }} m
JOIN {{ ref('sat_holding_attributes') }} a
    ON m.hk_holding = a.hk_holding