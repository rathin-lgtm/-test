{% macro create_xirr_udf(schema) %}
    CREATE OR REPLACE FUNCTION {{ target.database }}.{{ schema }}.xirr(
        cashflows ARRAY,
        dates ARRAY,
        guess FLOAT DEFAULT -0.01
    )
    RETURNS FLOAT
    LANGUAGE PYTHON
    RUNTIME_VERSION = '3.12'
    PACKAGES = ('pyxirr')
    HANDLER = 'compute_xirr'
    AS
    $$def compute_xirr(cashflows, dates, guess=-0.01):
    """
    Compute XIRR for given cashflows and dates.
    Args:
        cashflows (list[float]): List of cash flow amounts.
        dates (list[str]): List of date strings. (YYYY-MM-DD).
        guess (float): Initial guess for XIRR calcs.
    Returns:
        float: The XIRR value (annualized rate) or None.
    """
    from pyxirr import xirr
    if not cashflows or not dates or len(cashflows) != len(dates):
        return None
    try:
        return float(xirr(dates, cashflows, guess=guess))
    except Exception:
        return None$$;
{% endmacro %}