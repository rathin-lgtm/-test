{% macro holding_commitment(metric_col, amount_col, currency_col, investment_currency_col) %}
    SUM(
        CASE
            WHEN {{ metric_col }} in (5,7) THEN 
                CASE
                    WHEN {{ currency_col }} = {{ investment_currency_col }}
                        THEN {{ amount_col }}
                END
            ELSE NULL
        END
    )
{% endmacro %}