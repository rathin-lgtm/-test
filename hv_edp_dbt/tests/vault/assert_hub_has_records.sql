-- =============================================================================
-- TEST: Assert all hubs have at least one record
-- =============================================================================
-- This test verifies that the Data Vault hubs are not empty after loading.
-- Empty hubs indicate a data loading issue.
-- =============================================================================

{% set hubs = [
    'hub_fund',
    'hub_investor', 
    'hub_portfolio',
    'hub_company',
    'hub_holding'
] %}

{% for hub in hubs %}
{% if not loop.first %}UNION ALL{% endif %}
SELECT 
    '{{ hub }}' as hub_name,
    COUNT(*) as record_count
FROM {{ ref(hub) }}
HAVING COUNT(*) = 0
{% endfor %}
