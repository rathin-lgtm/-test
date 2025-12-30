{% macro create_xirr_udf(schema) %}
    CREATE OR REPLACE AGGREGATE FUNCTION {{ target.database }}.{{ schema }}.xirr(
        cashflow FLOAT,
        cfdate DATE
    )
    RETURNS FLOAT
    LANGUAGE PYTHON
    RUNTIME_VERSION = '3.12'
    PACKAGES = ('pyxirr')
    HANDLER = 'XirrAggregator'
    AS
    $$
from pyxirr import xirr

GUESS_DEFAULT = -0.01
class XirrAggregator:
    def __init__(self):
        self._cashflow_by_date = {}

    def accumulate(self, cashflow: float, cashflow_date: str):
        if cashflow is not None and cashflow_date is not None:
            self._state["cashflows"].append(cashflow)
            self._state["dates"].append(cashflow_date)
        self._state["guess"] = guess

    def accumulate(self, cashflow: float, cashflow_date: str):
        if cashflow is None or cashflow_date is None:
            return
        current = self._cashflow_by_date.get(cashflow_date)
        if current is None:
            self._cashflow_by_date[cashflow_date] = float(cashflow)
        else:
            self._cashflow_by_date[cashflow_date] = current + float(cashflow)

    def merge(self, other):
        other_map = other["_cashflow_by_date"]
        for date, cashflow in other_map.items():
            self._cashflow_by_date[date] = self._cashflow_by_date.get(date, 0.0) + cashflow

    def finish(self):
        if not self._cashflow_by_date:
            return None
        items = sorted(self._cashflow_by_date.items(), key=lambda t: t[0])
        dates = [date for date, _ in items]
        cashflows = [cashflow for _, cashflow in items]
        try:
            return float(xirr(dates, cashflows, guess=GUESS_DEFAULT))
        except Exception:
            return None

    @property
    def aggregate_state(self):
        return {"_cashflow_by_date": self._cashflow_by_date}

    @property
    def aggregate_state(self):
        return self._state
    $$;
{% endmacro %}