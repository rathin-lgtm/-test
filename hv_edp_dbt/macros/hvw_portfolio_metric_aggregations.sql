{% macro portfolio_distributions(metric_col, amount_col) %}
    SUM(
        CASE
            WHEN {{ metric_col }} in (3, 4, 150, 157, 428, 429, 430, 431, 432, 433, 434, 435, 444, 445, 446, 447, 182, 180, 315, 66, 314) THEN {{ amount_col }}
            ELSE 0
        END
    )
{% endmacro %}

{% macro portfolio_calls_unlevered(metric_col, amount_col) %}
    SUM(
        CASE
            WHEN {{ metric_col }} in (65, 322, 64, 408, 409, 410, 436, 437, 438, 439, 440, 441, 442, 443) THEN {{ amount_col }}
            ELSE 0
        END
    )
{% endmacro %}

{% macro portfolio_debt_borrowed(metric_col, amount_col) %}
    SUM(
        CASE
            WHEN {{ metric_col }} in (1, 313, 358) THEN {{ amount_col }}
            ELSE 0
        END
    )
{% endmacro %}


{% macro portfolio_debt_balance_no_directs(metric_col, amount_col, type_broad_id_col) %}
    SUM(
        CASE
            WHEN {{ metric_col }} in (180, 315, 1, 313, 21) AND {{type_broad_id_col}} not in (0) THEN {{ amount_col }}
            ELSE 0
        END
    )
{% endmacro %}

{% macro portfolio_debt_deferred(metric_col, amount_col) %}
    SUM(
        CASE
            WHEN {{ metric_col }} in (21) THEN {{ amount_col }}
            ELSE 0
        END
    )
{% endmacro %}

{% macro portfolio_unfunded_unlevered(metric_col, amount_col) %}
    SUM(
        CASE
            WHEN {{ metric_col }} in (7, 5) THEN {{ amount_col }}
            ELSE 0
        END
    )
{% endmacro %}

{% macro portfolio_nav(metric_col, amount_col, asset_type_id_col) %}
    SUM(
        CASE
            WHEN {{ metric_col }} in (257, 263, 262, 261, 453, 452, 466, 468, 472) THEN {{ amount_col }} /*CALCPORTFOLIONAVCURRENTVALUEOFDEAL, CALCPORTFOLIONAVCURRENTVALUEOFDEALROLLFORWARDPORTION, calcportfolioofficialnavcurrerntvalueofdeal, calcportfolioHGPSMonthlynavcurrentvalueofdeal, calcportfolioNAVdebtbalance */
            WHEN {{ metric_col }} in (256) AND {{asset_type_id_col}} in (1, 5) THEN {{ amount_col }} /* CurrentvalueofDirect,  calcportfolionavcurrentvalueofAffiliatefund*/
            ELSE 0
        END
    )
{% endmacro %}

{% macro portfolio_irr_amount_filter_limited(metric_col, currency_id_col, investment_currency_id_col, fact_date_col, cal_date_dim_col, cal_date_col, amount_col) %}
    CASE
        WHEN {{ metric_col }} IN (256, 257, 261, 312, 453, 452, 468) AND {{ fact_date_col }} = {{ cal_date_col }} THEN -1*{{ amount_col }}
        WHEN {{ metric_col }} IN (262, 263) AND {{ fact_date_col }} = {{ cal_date_col }} THEN {{ amount_col }}
        WHEN {{ metric_col }} IN (1) AND {{ fact_date_col }} > {{ cal_date_col }} AND {{ currency_id_col }} = {{ investment_currency_id_col }} THEN -1*{{ amount_col }}
        WHEN {{ metric_col }} IN (180) AND {{ fact_date_col }} > {{ cal_date_col }} AND {{ currency_id_col }} = {{ investment_currency_id_col }} THEN {{ amount_col }}
        WHEN {{ metric_col }} IN (64, 428, 429, 431, 433, 434, 435, 436, 437, 442, 443, 446, 447, 65, 313, 322, 358, 408, 409, 410) AND {{ fact_date_col }} > {{ cal_date_col }} THEN -1*{{ amount_col }}
        WHEN {{ metric_col }} IN (3, 4, 21, 66, 182, 314, 315, 430, 432, 438, 439, 440, 441, 444, 445) AND {{ fact_date_col }} > {{ cal_date_col }} THEN {{ amount_col }}
        WHEN {{ metric_col }} IN (256, 257, 261, 312, 453, 452, 468) AND {{ fact_date_col }} = {{ cal_date_dim_col }} THEN {{ amount_col }}
        WHEN {{ metric_col }} IN (262, 263) AND {{ fact_date_col }} = {{ cal_date_dim_col }} THEN -1*{{ amount_col }}
    END
{% endmacro %}

{% macro portfolio_irr_amount_filter_inception(metric_col, currency_id_col, investment_currency_id_col, fact_date_col, cal_date_dim_col, amount_col) %}
    CASE
        WHEN {{ metric_col }} IN (1) AND {{ currency_id_col }} = {{ investment_currency_id_col }} THEN -1 * {{ amount_col }}
        WHEN {{ metric_col }} IN (180) AND {{ currency_id_col }} = {{ investment_currency_id_col }} THEN {{ amount_col }}
        WHEN {{ metric_col }} IN (64, 428, 429, 431, 433, 434, 435, 436, 437, 442, 443, 446, 447, 65, 313, 322, 358, 408, 409, 410) THEN -1*{{ amount_col }}
        WHEN {{ metric_col }} IN (262, 263) AND {{ fact_date_col }} = {{ cal_date_dim_col }} THEN -1*{{ amount_col }}
        WHEN {{ metric_col }} IN (256, 257, 261, 312, 453, 452, 468) AND {{ fact_date_col }} = {{ cal_date_dim_col }} THEN {{ amount_col }}
        WHEN {{ metric_col }} IN (3, 4, 21, 66, 182, 314, 315, 430, 432, 438, 439, 440, 441, 444, 445) THEN {{ amount_col }}
    END
{% endmacro %}

{% macro portfolio_irr_cashflow_indicator_filter(years,  date_id_col, rollup_date_id_col, metric_id_col) %}
    CASE
        WHEN {{ date_id_col }} <= {{ rollup_date_id_col }} - ({{ years }}*10000) AND {{ metric_id_col }} IN (1, 180, 64, 428, 429, 430, 431, 432, 433, 434, 435, 444, 445, 446, 447, 65, 313, 322, 358, 408, 409, 410, 3, 4, 21, 66, 182, 314, 315, 436, 437, 438, 439, 440, 441, 442, 443) THEN 1 
        ELSE 0
    END
{% endmacro %}

{% macro portfolio_irr_cashflow_metric_ids() %}
256, 257, 261, 312, 1, 262, 263, 180, 64, 428, 429, 430, 431, 432, 433, 434, 435, 444, 445, 446, 447, 65, 313, 322, 358, 408, 409, 410, 3, 4, 21, 66, 182, 314, 315, 436, 437, 438, 439, 440, 441, 442, 443, 453, 452, 468
{% endmacro %}
