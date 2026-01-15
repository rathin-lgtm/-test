-- =============================================================================
-- TEST: Assert gold metrics tables have data for recent periods
-- =============================================================================
-- This test verifies that the gold layer has data for recent reporting periods.
-- Alerts if no data exists within the last 90 days.
-- =============================================================================

WITH recent_data AS (
    SELECT 'gold_fund_metrics' as model_name, MAX(as_of_date) as max_date FROM {{ ref('gold_fund_metrics') }}
    UNION ALL
    SELECT 'gold_portfolio_metrics', MAX(as_of_date) FROM {{ ref('gold_portfolio_metrics') }}
    UNION ALL
    SELECT 'gold_investor_performance_metrics', MAX(as_of_date) FROM {{ ref('gold_investor_performance_metrics') }}
)

SELECT 
    model_name,
    max_date,
    DATEDIFF(day, max_date, CURRENT_DATE()) as days_since_update
FROM recent_data
WHERE max_date IS NULL 
   OR DATEDIFF(day, max_date, CURRENT_DATE()) > 90
