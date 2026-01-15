# Effective Dating vs. Point-in-Time Snapshots - Explained

## Question: "What if the date I need falls between two as_of_dates?"

This is a **critical distinction** between **metrics satellites** and **attributes satellites**. Let me explain with examples from your codebase.

---

## 1. METRICS SATELLITES (Point-in-Time Snapshots)

### How They Work

Looking at your `sat_fund_metrics`:

```sql
-- Your current structure
SELECT 
    as_of_date,        -- '2024-01-31', '2024-02-29', '2024-03-31'
    hk_fund,
    lp_nav,
    tvpi,
    irr,
    ...
FROM sat_fund_metrics
```

**Key Point:** Metrics are **naturally periodic** - they represent month-end snapshots.

### Example Scenario

**Data in table:**
```
as_of_date    | hk_fund | lp_nav    | tvpi
--------------|---------|-----------|------
2024-01-31    | ABC123  | 1000000   | 1.25
2024-02-29    | ABC123  | 1050000   | 1.30
2024-03-31    | ABC123  | 1100000   | 1.35
```

**Query: "What was the NAV on 2024-02-15?"**

**Answer:** Use the most recent snapshot **on or before** that date:
```sql
SELECT lp_nav, tvpi
FROM sat_fund_metrics
WHERE hk_fund = 'ABC123'
  AND as_of_date <= '2024-02-15'
ORDER BY as_of_date DESC
LIMIT 1;
-- Returns: 1000000 (from 2024-01-31)
```

**Why This Works:**
- Metrics are **calculated at specific points in time** (month-end)
- You can't have a "real" NAV for Feb 15th - it's only calculated at month-end
- Business users understand: "Show me the most recent month-end value"

**If you need Feb 15th specifically:**
- You'd use **interpolation** (rare in finance)
- Or accept the most recent month-end value (standard practice)

---

## 2. ATTRIBUTES SATELLITES (Need Effective Dating)

### The Problem

Looking at your `sat_fund_attributes`:

```sql
-- Your current structure (NO as_of_date!)
SELECT 
    hk_fund,
    fund_name,                    -- 'Fund Alpha'
    fund_lock_date,              -- '2024-01-15'
    fund_currency,               -- 'USD'
    sub_perspective_name,        -- 'Main Fund'
    ...
    load_dt                      -- When record was loaded
FROM sat_fund_attributes
```

**Key Problem:** Attributes change at **unknown times**, not on a schedule.

### Example Scenario

**What happens when fund name changes?**

**Timeline:**
- Jan 1, 2024: Fund name = "Fund Alpha"
- Feb 15, 2024: Fund name changes to "Fund Alpha II" (mid-month!)
- Mar 1, 2024: Fund name changes to "Fund Alpha II - Series A"

**Current Approach (Row Hash):**
```
hk_fund | fund_name                    | load_dt
--------|------------------------------|------------------
ABC123  | Fund Alpha                   | 2024-01-01 10:00
ABC123  | Fund Alpha II                 | 2024-02-15 14:30
ABC123  | Fund Alpha II - Series A      | 2024-03-01 09:15
```

**Query: "What was the fund name on 2024-02-20?"**

**Problem:** You can't tell! You only know:
- Latest record: "Fund Alpha II - Series A" (from Mar 1)
- But you don't know when "Fund Alpha II" was effective

**With Effective Dating:**
```
hk_fund | fund_name                    | start_eff_ts      | end_eff_ts
--------|------------------------------|-------------------|-------------------
ABC123  | Fund Alpha                   | 2024-01-01 00:00 | 2024-02-15 14:30
ABC123  | Fund Alpha II                 | 2024-02-15 14:30 | 2024-03-01 09:15
ABC123  | Fund Alpha II - Series A      | 2024-03-01 09:15 | NULL (current)
```

**Query: "What was the fund name on 2024-02-20?"**
```sql
SELECT fund_name
FROM sat_fund_attributes
WHERE hk_fund = 'ABC123'
  AND start_eff_ts <= '2024-02-20'
  AND (end_eff_ts IS NULL OR end_eff_ts > '2024-02-20');
-- Returns: "Fund Alpha II" ✅
```

---

## 3. THE KEY DIFFERENCE

| Aspect | Metrics Satellites | Attributes Satellites |
|--------|-------------------|----------------------|
| **Change Frequency** | Periodic (month-end) | Random/Unknown |
| **Natural Date** | `as_of_date` (snapshot date) | No natural date |
| **Query Pattern** | "Most recent on/before date" | "What was value on exact date?" |
| **Effective Dating Needed?** | ❌ No - date is the snapshot | ✅ Yes - need start/end dates |

---

## 4. REAL-WORLD EXAMPLE FROM YOUR CODEBASE

### Metrics: `sat_fund_metrics`

**Scenario:** User asks "What was the fund NAV on 2024-02-15?"

**Your data:**
```
as_of_date | lp_nav
-----------|--------
2024-01-31 | 1000000
2024-02-29 | 1050000
```

**Answer:** Use 2024-01-31 value (most recent month-end before Feb 15)
- This is **correct** because NAV is only calculated at month-end
- No need for effective dating

### Attributes: `sat_fund_attributes`

**Scenario:** User asks "What was the fund name when we made investment X on 2024-02-20?"

**Your data (current approach):**
```
hk_fund | fund_name      | load_dt
--------|----------------|------------------
ABC123  | Fund Alpha     | 2024-01-01
ABC123  | Fund Alpha II  | 2024-02-15
```

**Problem:** You can't tell which name was active on Feb 20!
- `load_dt` tells you when data was **loaded**, not when it became **effective**

**With effective dating:**
```
hk_fund | fund_name      | start_eff_ts      | end_eff_ts
--------|----------------|-------------------|-------------------
ABC123  | Fund Alpha     | 2024-01-01        | 2024-02-15
ABC123  | Fund Alpha II  | 2024-02-15        | NULL
```

**Answer:** "Fund Alpha II" was active on Feb 20 ✅

---

## 5. RECOMMENDATION

### For Metrics Satellites (Keep Current Approach)
- ✅ Keep `as_of_date` - it IS the effective timestamp
- ✅ Use "most recent on/before" logic for queries
- ✅ No need for `start_eff_ts`/`end_eff_ts`

### For Attributes Satellites (Consider Effective Dating)
- ⚠️ **If** business users need historical queries → implement effective dating
- ⚠️ **If** only current state needed → keep current approach
- ⚠️ **Decision needed:** Do you need to query "what was fund name on date X?"

---

## 6. HYBRID APPROACH (Best of Both)

You could have **both** patterns in your vault:

```sql
-- Metrics: Point-in-time snapshots
sat_fund_metrics (as_of_date, hk_fund, nav, tvpi, ...)

-- Attributes: Effective dating (if needed)
sat_fund_attributes (
    hk_fund,
    fund_name,
    start_eff_ts,  -- When name became effective
    end_eff_ts,    -- When name stopped being effective
    ...
)
```

**This is actually the Data Vault 2.0 best practice!**

---

## Summary

**Your question is valid!** The answer depends on:

1. **Metrics:** Use most recent snapshot (no effective dating needed)
2. **Attributes:** Need effective dating IF you need historical queries

The key insight: **Metrics have natural periodic dates, attributes don't.**
