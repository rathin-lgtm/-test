{% macro filter_new_ingests() %}
    DATE_FROM_PARTS(year, month, day) > (SELECT max(file_date) FROM {{ this }} )
{% endmacro %}

{% macro filter_fund_ids(fund_ids) %}
    fund_id in ( {{ fund_ids | join(', ') }} )
{% endmacro %}

{% macro filter_investor_ids(investor_ids) %}
    investor_name_id in ( {{ investor_ids | join(', ') }} )
{% endmacro %}

{% macro load_full_refresh_table(source_name, table_name, exclude_cols=['value', 'time_period_key', 'session_log_key', 'year', 'month', 'day']) %}
    SELECT * EXCLUDE ({{ exclude_cols | join(', ') }}), 
    DATE_FROM_PARTS(year, month, day) as file_date, 
    METADATA$FILENAME as file_name,
    METADATA$FILE_LAST_MODIFIED as file_timestamp
    FROM {{ source(source_name, table_name) }}
    QUALIFY DATE_FROM_PARTS(year, month, day) = MAX(DATE_FROM_PARTS(year, month, day)) OVER()
    AND METADATA$FILE_LAST_MODIFIED = MAX((METADATA$FILE_LAST_MODIFIED)) OVER()
{% endmacro %}


{% macro load_delta_table(source_name, table_name, unique_keys, fund_filter, investor_filter) %}
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
    WHERE True
    {% if target.name == "personal_dev"%}
        {% if fund_filter %}
            {% set fund_ids = var('filtered_fund_ids', []) %}
            {% if fund_ids | length > 0  %}
                AND {{ filter_fund_ids(fund_ids) }}
            {% endif %}
        {% endif %}
        {% if investor_filter %}
            {% set investor_ids = var('filtered_investor_ids', []) %}
            {% if investor_ids | length > 0  %}
                AND {{ filter_investor_ids(investor_ids) }}
            {% endif %}
        {% endif %}
    {% endif %}
    {% if is_incremental() %}
        AND {{ filter_new_ingests() }}
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