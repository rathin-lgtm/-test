{% macro filter_new_ingests() %}
    WHERE DATE_FROM_PARTS(year, month, day) > (SELECT max(file_date) FROM {{ this }} )
{% endmacro %}

{% macro filter_fund_ids(preposition) %}
    {% set fund_ids = var('filtered_fund_ids', []) %}
    {% if target.name == "personal_dev" and fund_ids | length > 0  %}
       {{preposition}} fund_id in ( {{ fund_ids | join(', ') }} )
    {% endif %}
{% endmacro %}

{% macro load_full_refresh_table(source_name, table_name) %}
    SELECT * EXCLUDE (value, time_period_key, session_log_key, year, month, day), 
    DATE_FROM_PARTS(year, month, day) as file_date, 
    METADATA$FILENAME as file_name,
    METADATA$FILE_LAST_MODIFIED as file_timestamp
    FROM {{ source(source_name, table_name) }}
    QUALIFY DATE_FROM_PARTS(year, month, day) = MAX(DATE_FROM_PARTS(year, month, day)) OVER()
    AND METADATA$FILE_LAST_MODIFIED = MAX((METADATA$FILE_LAST_MODIFIED)) OVER()
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
        {{ filter_fund_ids('AND') }}
    {% else %}
        {{ filter_fund_ids('WHERE') }}
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