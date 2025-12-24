{% macro load_full_refresh_table(source_name, table_name) %}
    SELECT * EXCLUDE (value, time_period_key, session_log_key, year, month, day), DATE_FROM_PARTS(year, month, day) as file_date, METADATA$FILENAME as file_name FROM {{ source(source_name, table_name) }}
{% endmacro %}


{% macro load_delta_table(source_name, table_name, unique_keys) %}

{{
    config(
        incremental_strategy='merge',
        unique_key=unique_keys,
        post_hook="DELETE FROM {{ this }} WHERE last_operation_ind = 'D'")
}}

with src as (
    SELECT * EXCLUDE (value, time_period_key, session_log_key, hashvalue, year, month, day),
    DATE_FROM_PARTS(year, month, day) as file_date,
    METADATA$FILENAME as file_name
    FROM {{ source(source_name, table_name) }} 
    {% if is_incremental() %}
    {{ filter_new_ingests() }}
    {% endif %}
),

latest as (
    SELECT
    *,
    row_number() OVER (
        PARTITION BY {{ unique_keys | join(', ') }}
        ORDER BY last_update desc
    ) as rn
    FROM src
)

SELECT * EXCLUDE (rn, operation_ind),
operation_ind as last_operation_ind
FROM latest
WHERE rn = 1
{% endmacro %}