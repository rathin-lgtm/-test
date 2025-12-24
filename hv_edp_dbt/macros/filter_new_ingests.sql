{% macro filter_new_ingests() %}
    {% if is_incremental() %}
        where DATE_FROM_PARTS(year, month, day) > (select max(file_date) from {{ this }} )
    {% endif %}
{% endmacro %}