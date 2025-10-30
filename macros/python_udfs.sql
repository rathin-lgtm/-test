{% macro create_xirr_udf(schema) %}
    CREATE OR REPLACE AGGREGATE FUNCTION {{ target.database }}.{{ schema }}.xirr(
        cashflow FLOAT,
        cfdate DATE,
        guess FLOAT DEFAULT -0.01
    )
    RETURNS FLOAT
    LANGUAGE PYTHON
    RUNTIME_VERSION = '3.12'
    PACKAGES = ('pyxirr')
    HANDLER = 'XirrAggregator'
    AS
    $$
from pyxirr import xirr

class XirrAggregator:
    def __init__(self):
        self._state = {
            "cashflows": [],
            "dates": [],
            "guess": -0.01
        }

    def accumulate(self, cashflow: float, cfdate, guess: float = -0.01):
        if cashflow is not None and cfdate is not None:
            self._state["cashflows"].append(cashflow)
            self._state["dates"].append(cfdate)
        self._state["guess"] = guess

    def merge(self, other):
        self._state["cashflows"].extend(other["cashflows"])
        self._state["dates"].extend(other["dates"])
        if other.get("guess") is not None:
            self._state["guess"] = other["guess"]

    def finish(self):
        if not self._state["cashflows"] or not self._state["dates"]:
            return None

        try:
            return float(xirr(self._state["dates"], self._state["cashflows"], guess=self._state["guess"]))
        except Exception:
            return None


    @property
    def aggregate_state(self):
        return self._state

    @staticmethod
    def merge_states(state1, state2):
        return {
            "cashflows": state1["cashflows"] + state2["cashflows"],
            "dates": state1["dates"] + state2["dates"],
            "guess": state2["guess"] if state2.get("guess") is not None else state1["guess"]
        }

    @staticmethod
    def finish_state(state):
        if not state["cashflows"] or not state["dates"]:
            return None

        try:
            return float(xirr(state["dates"], state["cashflows"], guess=state["guess"]))
        except Exception:
            return None

    $$;
{% endmacro %}