{% macro restricted_name_masking(staff_cond_col, id_col) %}
    CASE WHEN {{ staff_cond_col }} = 1 AND {{ id_col }} <> -1 THEN 'Restricted' END
{% endmacro %}

{% macro hv_group_override(staff_cond_col) %}
    CASE WHEN {{ staff_cond_col }} = 1 THEN '1444282' END
{% endmacro %}
