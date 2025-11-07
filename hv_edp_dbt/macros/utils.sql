
{% macro to_date(col) %}
    TRY_TO_DATE({{ col }}, 'YYYYMMDD')
{% endmacro %}


{% macro encoded_hashed_row() %}
    HEX_ENCODE(TO_CHAR(HASH(OBJECT_CONSTRUCT_KEEP_NULL(* EXCLUDE (load_dt)))))
{% endmacro %}