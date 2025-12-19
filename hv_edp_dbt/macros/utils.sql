
{% macro to_date(col) %}
    TRY_TO_DATE({{ col }}::VARCHAR, 'YYYYMMDD')
{% endmacro %}


{% macro append_hk_key_column(cte_name) %}
    SELECT t.*,
    HEX_ENCODE(TO_CHAR(HASH(OBJECT_CONSTRUCT_KEEP_NULL(* EXCLUDE (load_dt))))) as hk_key
    from {{ cte_name }} t
{% endmacro %}

{% macro indicator_yes_no(indicator_col) %}
    CASE 
        WHEN {{ indicator_col }} = 1 THEN 'Yes'
        WHEN {{ indicator_col }} = 0 THEN 'No'
        ELSE 'Unknown'
    END
{% endmacro %}

{% macro disclosure_level(level_col) %}
    CASE 
        WHEN {{ level_col }} = 10 THEN 'All'
        WHEN {{ level_col }} = 20 THEN 'NAV Only'
        WHEN {{ level_col }} = 30 THEN 'No Metrics'
        ELSE 'Unknown'
    END
{% endmacro %}

{% macro hk(column) %}
    sha2(upper(trim({{ column }})))
{% endmacro %}

{% macro safe_division(numerators, denominators) %}
    {%- set num_expr = numerators | join(' + ') -%}
    {%- set den_expr = denominators | join(' + ') -%}

    CASE 
        WHEN ({{ den_expr }}) = 0 THEN 0
        ELSE ({{ num_expr }}) / ({{ den_expr }})
    END
{% endmacro %}
