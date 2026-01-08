-- For investor contribution

{% macro investor_capital_called_excludes_total_transfers_transaction(metric_col, amount_col) %}
    SUM(
        CASE
            WHEN {{ metric_col }} in (12,13,14,16,185,214,215) THEN {{ amount_col }}
            ELSE 0
        END
    )
{% endmacro %}

{% macro investor_contribution_adjustment_transaction(metric_col, amount_col) %}
    SUM(
        CASE
            WHEN {{ metric_col }} in (319, 320) THEN {{ amount_col }}
            ELSE 0
        END
    )
{% endmacro %}

-- for investor commitment 
{% macro investor_transaction_unfunded(metric_col, amount_col) %}
    SUM(
        CASE
            WHEN {{ metric_col }} in (6) THEN {{ amount_col }}
            WHEN {{ metric_col }} in (12, 13, 14, 15, 16, 17, 18, 185, 214, 215) THEN -1* {{ amount_col }}
            WHEN {{ metric_col }} in (391) THEN {{ amount_col }}
            ELSE 0
        END
    )
{% endmacro %}

{% macro calc_investor_transaction_contribution_in_cap_adjustment(metric_col, amount_col) %}
    SUM(
        CASE
            WHEN {{ metric_col }} in (319, 320, 321) THEN {{ amount_col }}
            ELSE 0
        END
    )
{% endmacro %}

{% macro calc_investor_contribution_transactions_in_cap(metric_col, amount_col) %}
    SUM(
        CASE
            WHEN {{ metric_col }} in (12, 13, 14, 15, 16, 17, 18, 185, 214, 215) THEN {{ amount_col }}
            ELSE 0
        END
    )
{% endmacro %}

-- distribution transactions

{% macro investor_distribution_in_total_exclude_total_transfers_transaction(metric_col, amount_col) %}
    SUM(
        CASE
            WHEN {{ metric_col }} in (40,41,42,43,44,45,46,47,48,49,52,56,60,63,186,187,188,189,210,211) THEN {{ amount_col }}
            ELSE 0
        END
    )
{% endmacro %}

{% macro investor_distribution_adjustment_transaction(metric_col, amount_col) %}
    SUM(
        CASE
            WHEN {{ metric_col }} in (326,327) THEN {{ amount_col }}
            ELSE 0
        END
    )
{% endmacro %}


-- For Investor Transfer of Interest Transactions

{% macro investor_inception_transferred_contribution_component(metric_col, amount_col) %}
    SUM(
        CASE
            WHEN {{ metric_col }} in (15,17,18) THEN {{ amount_col }}
            ELSE 0
        END
    )
{% endmacro %}

{% macro investor_inception_transferred_distribution_component(metric_col, amount_col) %}
    SUM(
        CASE
            WHEN {{ metric_col }} in (50, 51, 53, 54, 55, 57, 58, 59, 61, 62) THEN {{ amount_col }}
            ELSE 0
        END
    )
{% endmacro %}

{% macro investor_inception_transferred_income_expense_component(metric_col, amount_col) %}
    SUM(
        CASE
            WHEN {{ metric_col }} in (164) THEN {{ amount_col }}
            ELSE 0
        END
    )
{% endmacro %} 

-- For investor_distribution_in_total_exclude_total_transfers_transactions

{% macro investor_distribution_in_total_exclude_total_transfers_transactions_m(metric_col, amount_col) %}
    SUM(
        CASE
            WHEN {{ metric_col }} in (40,41,42,43,44,45,46,47,48,49,52,56,60,63,186,187,188,189,210,211) THEN {{ amount_col }}
            ELSE 0
        END
    )
{% endmacro %}

-- Investor Capital Called (excludes Total Transfers) Transaction

{% macro investor_capital_called_excludes_total_transfers_transaction_m(metric_col, amount_col) %}
    SUM(
        CASE
            WHEN {{ metric_col }} in (12, 13, 14, 16, 185, 214, 215) THEN {{ amount_col }}
            ELSE 0
        END
    )
{% endmacro %}

-- Investor Withholding

{% macro investor_withholding_m(metric_col, amount_col) %}
    SUM(
        CASE
            WHEN {{ metric_col }} IN (23, 24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39) THEN {{ amount_col }}
            ELSE 0
        END
    )
{% endmacro %}

{% macro investor_transaction_rollup(col) %}
    SUM({{ col }}) OVER (
        PARTITION BY hk_investor, hk_fund, currency_id
        ORDER BY as_of_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )
{% endmacro %}
