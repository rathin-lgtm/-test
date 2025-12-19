with attributes as (
    SELECT
        hub.hk_holding,
        currency.name as holding_currency,
        holding.fund_id,
        CURRENT_TIMESTAMP() as load_dt,
        holding.start_eff_date,
        holding.end_eff_date,
        holding.active_ind
    FROM
        {{ ref('dim_holdings') }} holding
    JOIN {{ ref('currency') }} currency
        ON currency.currency_id = holding.holding_currency_id
    JOIN {{ ref('hub_holding') }} hub
        ON holding.holding_id = hub.holding_id
    WHERE holding.holding_id <> -1
),

final_attributes as (
    SELECT 
        hk_holding,
        holding_currency,
        fund_id,
        load_dt
    FROM attributes
)

{{ append_hk_key_column('final_attributes') }}
