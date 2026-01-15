# Link Satellites - Explained with Real Example

## The Problem: Relationship Attributes Don't Belong in Links

In Data Vault 2.0, **links should only contain hash keys**. Any attributes of the relationship belong in a **link satellite**.

---

## YOUR CURRENT IMPLEMENTATION (Incorrect)

Looking at your `link_portfolio_fund.sql`:

```sql
SELECT distinct
    {{ hk('p.portfolio_id') }} as hk_portfolio,
    {{ hk('p.fund_id') }} as hk_fund,
    sha2(hk_portfolio || hk_fund) as hk_link,
    p.portfolio_id,
    p.fund_id,
    sp.fund_sub_perspective_id,  -- ❌ ATTRIBUTE IN LINK!
    CURRENT_TIMESTAMP() as load_dt,
FROM portfolios p
...
```

**Problem:** `fund_sub_perspective_id` is an **attribute of the relationship**, not part of the relationship itself.

---

## WHY THIS IS WRONG

### Data Vault 2.0 Principle

**Links represent relationships, not relationship attributes.**

Think of it this way:
- **Link:** "Portfolio X is related to Fund Y" (the fact of the relationship)
- **Link Satellite:** "Portfolio X's relationship with Fund Y has sub-perspective Z" (attributes of that relationship)

### Real-World Analogy

**Marriage (Link):**
- Person A is married to Person B
- That's the relationship

**Marriage Certificate (Link Satellite):**
- Wedding date: 2020-06-15
- Location: New York
- Officiant: Judge Smith
- These are **attributes of the relationship**, not the relationship itself

---

## CORRECT IMPLEMENTATION

### Step 1: Clean Link (Only Hash Keys)

```sql
-- link_portfolio_fund.sql
SELECT DISTINCT
    {{ hk('p.portfolio_id') }} as hk_portfolio,
    {{ hk('p.fund_id') }} as hk_fund,
    sha2(hk_portfolio || hk_fund) as hk_link,
    p.portfolio_id,              -- Business key (for reference)
    p.fund_id,                   -- Business key (for reference)
    CURRENT_TIMESTAMP() as row_create_ts,
    p.file_name as record_source
FROM portfolios p
JOIN {{ ref('dim_fund') }} d
    ON p.fund_id = d.fund_id
-- NO fund_sub_perspective_id here!
```

**Result:**
```
hk_link    | hk_portfolio | hk_fund | portfolio_id | fund_id | row_create_ts
-----------|--------------|---------|--------------|---------|------------------
LINK_ABC   | HUB_123      | HUB_456 | 1001         | 2001    | 2024-01-15
LINK_DEF   | HUB_124      | HUB_456 | 1002         | 2001    | 2024-01-15
```

**This link says:** "Portfolio 1001 is related to Fund 2001" - that's it!

---

### Step 2: Create Link Satellite (Relationship Attributes)

```sql
-- sat_link_portfolio_fund.sql
WITH portfolio_fund_relationships AS (
    SELECT
        link.hk_link,
        sp.fund_sub_perspective_id,
        sp.fund_sub_perspective_name,
        -- Any other attributes of the portfolio-fund relationship
        CURRENT_TIMESTAMP() as row_create_ts
    FROM {{ ref('link_portfolio_fund') }} link
    JOIN {{ ref('dim_portfolios') }} p
        ON link.portfolio_id = p.portfolio_id
        AND link.fund_id = p.fund_id
    JOIN {{ ref('dim_fund') }} d
        ON p.fund_id = d.fund_id
    JOIN {{ ref('fact_fund_sub_perspective_funds') }} f
        ON d.fund_id = f.fund_id
    JOIN {{ ref('dim_fund_sub_perspective') }} sp
        ON f.fund_id = sp.fund_sub_perspective_primary_fund_id
        AND f.fund_sub_perspective_id = sp.fund_sub_perspective_id
    WHERE sp.fund_perspective_view_id = 3
)
SELECT 
    hk_link,
    fund_sub_perspective_id,
    fund_sub_perspective_name,
    row_create_ts
FROM portfolio_fund_relationships
```

**Result:**
```
hk_link    | fund_sub_perspective_id | fund_sub_perspective_name | row_create_ts
-----------|------------------------|---------------------------|------------------
LINK_ABC   | 5                      | Main Fund                 | 2024-01-15
LINK_DEF   | 5                      | Main Fund                 | 2024-01-15
```

**This satellite says:** "The Portfolio-Fund relationship has sub-perspective 5"

---

## VISUAL REPRESENTATION

### Current (Incorrect) Structure

```
┌─────────────────────────────────────┐
│     link_portfolio_fund             │
├─────────────────────────────────────┤
│ hk_link                             │
│ hk_portfolio                         │
│ hk_fund                              │
│ portfolio_id                         │
│ fund_id                              │
│ fund_sub_perspective_id  ❌ WRONG!  │
└─────────────────────────────────────┘
```

**Problem:** Link contains attributes!

---

### Correct Structure

```
┌─────────────────────────┐
│  link_portfolio_fund    │
├─────────────────────────┤
│ hk_link                 │
│ hk_portfolio            │
│ hk_fund                 │
│ portfolio_id            │
│ fund_id                 │
└─────────────────────────┘
         │
         │ (references)
         ▼
┌──────────────────────────────┐
│ sat_link_portfolio_fund      │
├──────────────────────────────┤
│ hk_link                      │
│ fund_sub_perspective_id  ✅  │
│ fund_sub_perspective_name ✅  │
│ row_create_ts                 │
└──────────────────────────────┘
```

**Correct:** Link is minimal, attributes in satellite!

---

## REAL EXAMPLE FROM YOUR CODEBASE

### Scenario: Portfolio 1001 in Fund 2001

**Current Implementation:**
```sql
-- link_portfolio_fund contains:
hk_link: LINK_ABC
hk_portfolio: HUB_123
hk_fund: HUB_456
fund_sub_perspective_id: 5  -- ❌ Shouldn't be here!
```

**Problem:** What if the sub-perspective changes over time?

**Example Timeline:**
- Jan 1, 2024: Portfolio 1001 assigned to sub-perspective 5
- Mar 15, 2024: Portfolio 1001 moved to sub-perspective 7

**With current approach:**
- You'd have to update the link (wrong!)
- Links should be insert-only
- You lose history

**With link satellite:**
```
-- sat_link_portfolio_fund
hk_link    | fund_sub_perspective_id | start_eff_ts | end_eff_ts
-----------|-------------------------|---------------|------------
LINK_ABC   | 5                       | 2024-01-01    | 2024-03-15
LINK_ABC   | 7                       | 2024-03-15    | NULL
```

**Benefits:**
- Link stays unchanged (insert-only)
- History preserved in satellite
- Can query "what was sub-perspective on date X?"

---

## WHY THIS MATTERS

### 1. Data Vault 2.0 Compliance

**Principle:** Links are insert-only and contain only hash keys.

**Your current code violates this** by having `fund_sub_perspective_id` in the link.

### 2. Flexibility

**If relationship attributes change:**
- Current approach: Update link (breaks insert-only rule)
- Link satellite: Insert new record (preserves history)

### 3. Query Performance

**Querying relationship attributes:**
```sql
-- Current (wrong)
SELECT fund_sub_perspective_id
FROM link_portfolio_fund
WHERE hk_link = 'LINK_ABC';
-- Problem: Can't track history

-- Correct
SELECT fund_sub_perspective_id
FROM sat_link_portfolio_fund
WHERE hk_link = 'LINK_ABC'
  AND start_eff_ts <= CURRENT_DATE()
  AND (end_eff_ts IS NULL OR end_eff_ts > CURRENT_DATE());
-- Can track history!
```

---

## MIGRATION PLAN

### Step 1: Create Link Satellite

```sql
-- New file: sat_link_portfolio_fund.sql
SELECT 
    link.hk_link,
    sp.fund_sub_perspective_id,
    CURRENT_TIMESTAMP() as row_create_ts
FROM {{ ref('link_portfolio_fund') }} link
-- ... join logic to get fund_sub_perspective_id ...
```

### Step 2: Refactor Link

```sql
-- Update: link_portfolio_fund.sql
-- Remove fund_sub_perspective_id
-- Keep only hash keys and business keys
```

### Step 3: Update Gold Layer

```sql
-- Update gold models that reference fund_sub_perspective_id
-- Change from: link.fund_sub_perspective_id
-- To: sat_link.fund_sub_perspective_id
```

---

## SUMMARY

**Link Satellites are for:**
- Attributes that describe the relationship
- Attributes that may change over time
- Any data that's "about" the relationship, not the relationship itself

**Links are for:**
- Hash keys only
- Business keys (for reference)
- The fact that a relationship exists

**Your `fund_sub_perspective_id` belongs in `sat_link_portfolio_fund`, not `link_portfolio_fund`!**
