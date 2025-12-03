{% macro investor_distribution(metric_col, amount_col) %}
    SUM(
        CASE 
            WHEN {{ metric_col }} in (40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 52, 56, 60, 63, 186, 187, 188, 189, 210, 211, 326, 327) THEN {{ amount_col}}
            ELSE 0
        END
    )
{% endmacro %}

{% macro investor_distribution_gain(metric_col, amount_col) %}
    SUM(
        CASE 
            WHEN {{ metric_col }} in (44, 49) THEN {{ amount_col }}
            ELSE 0
        END
    )
{% endmacro %}

{% macro investor_contribution_adjustment(metric_col, amount_col) %}
    SUM(
        CASE 
            WHEN {{ metric_col }} in (319, 320, 321) THEN {{ amount_col }}
            ELSE 0
        END
    )
{% endmacro %}

{% macro investor_contribution_total(metric_col, amount_col) %}
    SUM(
        CASE 
            WHEN {{ metric_col }} in (12, 13, 14, 16, 185, 214, 215) THEN {{ amount_col }}
            ELSE 0
        END
    )
{% endmacro %}

{% macro investor_contribution_cap_components(metric_col, amount_col) %}
    SUM(
        CASE 
            WHEN {{ metric_col }} in (12, 13, 14, 15, 16, 17, 18, 185, 214, 215) THEN {{ amount_col }}
            ELSE 0
        END
    )
{% endmacro %}

{% macro investor_contribution_commitment_fund_currency(metric_col, amount_col) %}
    SUM(
        CASE 
            WHEN {{ metric_col }} in (6) THEN {{ amount_col }}
            ELSE 0
        END
    )
{% endmacro %}

{% macro investor_nav(metric_col, amount_col) %}
    SUM(
        CASE
            WHEN {{ metric_col }} in (12, 13, 14, 15, 16, 17, 18, 185, 214, 215, 83, 86, 87, 88, 89, 90, 91, 92, 93, 94, 96, 103, 104, 105, 106, 107, 110, 111, 120, 108, 109, 164, 119, 95, 85, 98, 100, 102, 121, 122, 123, 124, 125, 126, 127, 128, 129, 131, 133, 84, 97, 99, 101, 112, 113, 114, 115, 116, 117, 118, 130, 132, 233, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 234, 235, 236, 237, 238, 239, 240, 241, 245, 246, 247, 248, 249, 347, 366, 367, 368, 369, 372, 375, 371, 374, 377, 370, 373, 376, 378, 379, 380, 382, 384, 386, 381, 383, 385, 398, 399, 400, 346, 85, 514, 94, 510, 96, 515, 347, 485, 108, 460, 111, 120, 517, 459, 460, 461, 462, 463, 464, 465) THEN {{ amount_col }}
            WHEN {{ metric_col }} in (40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 456, 457, 458) THEN -1*{{ amount_col }}
            ELSE 0
        END
    )
{% endmacro %}

{% macro investor_transfers(metric_col, amount_col, transfered_col, date_id_col, lock_date_col) %}
    SUM(
        CASE 
            WHEN {{ metric_col }} in (134, 135, 136, 137, 138, 139, 140, 141, 142, 234, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 378, 379, 380, 381, 383, 385)
                AND {{ to_date(date_id_col) }} > {{ to_date(lock_date_col) }} AND {{ transfered_col }} in (1, 2) THEN {{ amount_col }}
            ELSE 0
        END
    )
{% endmacro %}

{% macro running_sum_investor_nav(metric_col, amount_col, date_id_col, lock_date_col) %}
    SUM(
        CASE
            WHEN {{ metric_col }} in (12, 13, 14, 16, 18, 185, 214, 215, 83, 86, 87, 88, 89, 90, 91, 92, 93, 94, 96, 103, 104, 105, 106, 107, 110, 111, 120, 108, 109, 164, 119, 95, 85, 98, 100, 102, 121, 122, 123, 124, 125, 126, 127, 128, 129, 131, 133, 84, 97, 99, 101, 112, 113, 114, 115, 116, 117, 118, 130, 132, 233, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 234, 235, 236, 237, 238, 239, 240, 241, 245, 246, 247, 248, 249, 347, 366, 367, 368, 369, 372, 375, 371, 374, 377, 370, 373, 376, 378, 379, 380, 382, 384, 386, 381, 383, 385, 398, 399, 400) AND {{ to_date(date_id_col) }} <= {{ to_date(lock_date_col) }} THEN {{ amount_col }}
            WHEN {{ metric_col }} in (40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 52, 56, 60, 63, 186, 187, 189, 210, 211) AND {{ to_date(date_id_col) }} <= {{ to_date(lock_date_col) }} THEN -1* {{ amount_col }}
            ELSE 0
        END
    )
{% endmacro %}
