{% macro company_rollup(col) %}
    SUM({{ col }}) OVER (
        PARTITION BY hk_company
        ORDER BY as_of_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )
{% endmacro %}

{% macro company_realized_value(metric_col, amount_col) %}
    SUM(
        CASE
            WHEN {{ metric_col }} = 179 THEN {{ amount_col }} /* Fund_level_contribution_cap_component_adjustment */
            ELSE 0
        END
    )
{% endmacro %}

{% macro company_current_value(metric_col, amount_col) %}
    SUM(
        CASE
            WHEN {{ metric_col }} = 20 THEN {{ amount_col }} /* Fund_level_contribution_cap_component_adjustment */
            ELSE 0
        END
    )
{% endmacro %}

{% macro company_current_cost(metric_col, amount_col) %}
    SUM(
        CASE
            WHEN {{ metric_col }} = 19 THEN {{ amount_col }} /* Fund_level_contribution_cap_component_adjustment */
            ELSE 0
        END
    )
{% endmacro %}

{% macro company_realized_cost(metric_col, amount_col) %}
    SUM(
        CASE
            WHEN {{ metric_col }} = 178 THEN {{ amount_col }} /* Fund_level_contribution_cap_component_adjustment */
            ELSE 0
        END
    )
{% endmacro %}