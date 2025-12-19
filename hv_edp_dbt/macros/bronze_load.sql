{% macro load_full_refresh_table(source_name, table_name) %}
    SELECT * EXCLUDE (value, year, month, day), DATE_FROM_PARTS(year, month, day) as file_date, METADATA$FILENAME as file_name from {{ source(source_name, table_name) }}
{% endmacro %}