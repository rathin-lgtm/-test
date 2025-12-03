SELECT
-- Likely needs fund_efront_id to be added
    as_of_date,
    holding_id,
    holding_currency,
    holding_commitment_unlevered
FROM {{ ref('sat_holding_metrics') }} m
JOIN {{ ref('sat_holding_attributes') }} a
    ON m.hk_holding = a.hk_holding
JOIN {{ ref('hub_holding') }} hub
    ON m.hk_holding = hub.hk_holding