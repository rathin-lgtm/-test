/* HVW_METRIC_AGGREGATIONS
   This file is largely macros containing legacy behaviour specific to Harbourview. Strategic goal is to eventually delete this as we change to pulling data direct from source systems.
 */
{% macro fund_rollup(col) %}
    SUM({{ col }}) OVER (
        PARTITION BY hk_fund, currency_code
        ORDER BY as_of_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )
{% endmacro %}

{% macro fund_nav(date_id_col, metric_col, lock_date_col, amount_col) %}
    SUM(
        CASE
            WHEN {{ metric_col }} in (12, 13, 14, 15, 16, 17, 18, 185, 214, 215) THEN {{ amount_col }} /* Fund_inception_Contribution_Cap_withoutInterest_Paid_at_Closing_Fund_Currency */
            WHEN {{ metric_col }} in (40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63) THEN -1*{{ amount_col }} /* Fund_inception_dist_Cap_In_Fund_currency */
            WHEN {{ metric_col }} in (83, 86, 87, 88, 89, 90, 91, 92, 93, 94, 96, 103, 104, 105, 106, 107, 110, 111, 120, 108, 109, 164, 119, 95, 85, 98, 100, 102, 121, 122, 123, 124, 125, 126, 127, 128, 129, 131, 133, 84, 97, 99, 101, 112, 113, 114, 115, 116, 117, 118, 130, 132, 233, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 234, 235, 236, 237, 238, 239, 240, 241, 245, 246, 247, 248, 249, 347, 366, 367, 368, 369, 372, 375, 371, 374, 377, 370, 373, 376, 378, 379, 380, 382, 384, 386, 381, 383, 385, 398, 399, 400, 346, 85, 514, 94, 510, 96, 515, 347, 485, 108, 460, 111, 120, 517, 459, 460, 461, 462, 463, 464, 465) 
                AND {{ to_date(date_id_col) }} <= {{ to_date(lock_date_col) }} THEN {{ amount_col }} /* Fund_Inception_Income_Expense_In_Fund_Currency */
            ELSE 0
        END
    )
{% endmacro %}

{% macro fund_distributions(metric_col, amount_col) %}
    SUM(
        CASE
            WHEN {{ metric_col }} in (42, 40, 41, 46, 43, 45, 47, 48, 44, 49, 54, 55, 56, 57, 58, 59, 61, 60, 50, 51, 52, 53, 62, 63, 323, 324, 325, 326, 327, 328) THEN {{ amount_col }}
            ELSE 0
        END
    )
{% endmacro %}

{% macro fund_contributions(metric_col, amount_col) %}
    SUM(
        CASE
            WHEN {{ metric_col }} in (12, 13, 14, 15, 16, 17, 18, 185, 214, 215) THEN {{ amount_col }}
            ELSE 0
        END
    )
{% endmacro %}

{% macro fund_commitments(metric_col, amount_col) %}
    SUM(
        CASE
            /* HVW formula has contributions in this calc but since we are partitioning on currency they should cancel out */
            WHEN {{ metric_col }} in (319,320,321) THEN {{ amount_col }} /* Fund_level_contribution_cap_component_adjustment */
            WHEN {{ metric_col }} in (6) THEN {{ amount_col }} /* cumulative_commitment */
            ELSE 0
        END
    )
{% endmacro %}

{% macro capital_called_add_term(metric_col, amount_col) %}
    SUM(
        CASE
            WHEN {{ metric_col }} in (8) THEN {{ amount_col }}
            ELSE 0
        END
    )
{% endmacro %}

{% macro fund_irr_amount_filter_limited(metric_col, fact_date_col, cal_date_dim_col, cal_date_col, amount_col) %}
    SUM(
        CASE
        WHEN {{ metric_col }} = 227 AND {{ fact_date_col }} = {{ cal_date_col }} THEN -1*{{ amount_col }}
        WHEN {{ metric_col }} = 217 AND {{ fact_date_col }} > {{ cal_date_col }} THEN -1*{{ amount_col }}
        WHEN {{ metric_col }} = 218 AND {{ fact_date_col }} > {{ cal_date_col }} THEN {{ amount_col }}
        WHEN {{ metric_col }} = 227 AND {{ fact_date_col }} = {{ cal_date_dim_col }} THEN {{ amount_col }}
    END
    )
{% endmacro %}

{% macro fund_irr_amount_filter_inception(metric_col, fact_date_col, cal_date_dim_col, amount_col) %}
    SUM(
        CASE
        WHEN {{ metric_col }} = 217 THEN -1*{{ amount_col }}
        WHEN {{ metric_col }} = 218 THEN {{ amount_col }}
        WHEN {{ metric_col }} = 227 AND {{ fact_date_col }} = {{ cal_date_dim_col }} THEN {{ amount_col }}
    END
    )
{% endmacro %}

{% macro fund_irr_cashflow_indicator_filter(years, date_id_col, rollup_date_id_col, metric_id_col) %}
    MAX(CASE
        WHEN {{ date_id_col }} <= {{ rollup_date_id_col }} - ({{ years }}*10000) AND {{ metric_id_col }} IN (217,218) THEN 1 
        ELSE 0
    END)
{% endmacro %}

{% macro irr_cashflow_metric_ids() %}
217, 218, 227
{% endmacro %}