{% macro filter_new_ingests() %}
    {% if is_incremental() %}
        where ingest_time > (select max(ingest_time) from {{ this }} )
    {% endif %}
{% endmacro %}