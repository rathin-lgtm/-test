# Data Vault Modeling Standards - Meeting Preparation

**Date:** [Meeting Date]  
**Attendees:** [Director], [Your Name], [Others]  
**Purpose:** Align on Data Vault 2.0 modeling standards and implementation approach

---

## Executive Summary

We've reviewed the proposed modeling guidelines against our current implementation and industry best practices. **Most guidelines align well with Data Vault 2.0 standards**, but there are several areas requiring clarification and some technical concerns that need discussion.

**Status:**
- ✅ **Agreed:** 6 items (ready to implement)
- ⚠️ **Needs Discussion:** 4 items (require business input)
- ❌ **Technical Concerns:** 3 items (need correction/clarification)

---

## ✅ AGREED POINTS (Ready to Implement)

### 1. REF Pattern for Static Reference Data

**Guideline:**
> "Entities that have non-changing data - typically code and descriptions or static data like countries, currencies"

**Agreement:** ✅ **FULLY AGREE**

**Implementation Plan:**
- Keep `currency`, `calendar`, `calendar_month`, `calendar_quarter` as simple lookup tables in Bronze layer
- No hub/satellite structure needed for true reference data
- These are dimension tables, not business entities

**Rationale:**
- Reference data doesn't have business keys that change
- No need for history tracking
- Simpler structure = better performance
- Aligns with DV2.0 best practices

**Action Items:**
- Document REF pattern in architecture docs
- Create naming convention: `ref_currency`, `ref_calendar` (optional)

---

### 2. Hub Creation Criteria

**Guideline:**
> "Only create hubs for business entities (fund, investor, portfolio)"

**Agreement:** ✅ **FULLY AGREE**

**Current Implementation:**
- ✅ `hub_fund` - Business entity
- ✅ `hub_investor` - Business entity  
- ✅ `hub_portfolio` - Business entity
- ✅ `hub_company` - Business entity
- ✅ `hub_holding` - Business entity

**Rationale:**
- Hubs represent core business concepts that have relationships
- Reference data (currency, calendar) are NOT business entities
- This keeps the model clean and maintainable

---

### 3. Metrics Satellites - Point-in-Time Snapshots

**Guideline:**
> "Keep current approach for metrics satellites (point-in-time snapshots)"

**Agreement:** ✅ **FULLY AGREE**

**Current Implementation:**
- `sat_fund_metrics` - Monthly snapshots with `as_of_date`
- `sat_portfolio_metrics` - Monthly snapshots
- `sat_investor_fund_metrics` - Point-in-time metrics

**Why This Works:**
- Metrics are naturally time-series data
- Each `as_of_date` represents a complete snapshot
- No need for `start_eff_ts`/`end_eff_ts` - date is the effective timestamp
- Simpler queries: `WHERE as_of_date = '2024-01-31'`

**Technical Note:**
- Current approach uses `hk_key` (row hash) for deduplication
- This prevents duplicate snapshots for same `as_of_date`
- More efficient than effective dating for time-series data

---

### 4. Source System Code - Future-Proofing

**Guideline:**
> "Source System Code table - Future-proofs for multi-source scenarios"

**Agreement:** ✅ **AGREE WITH ENHANCEMENT**

**Current State:**
- Only `record_source` (file name) tracked
- All data currently from single source: `HARBOURVIEW_EDW`

**Proposed Enhancement:**
- Add `source_system_cd` column to all hubs
- Default to `'HARBOURVIEW_EDW'` for now
- Add unique constraint: `(business_key, source_system_cd)`

**Benefits:**
- Ready for multi-source scenarios (e.g., eFront, Salesforce)
- Proper data lineage tracking
- Prevents key collisions across systems

**Implementation:**
```sql
-- Example hub structure
SELECT 
    {{ hk('fund_id') }} as hk_fund,
    fund_id,
    'HARBOURVIEW_EDW' as source_system_cd,  -- NEW
    CURRENT_TIMESTAMP() as row_create_ts,
    file_name as record_source
FROM ...
```

**Action Items:**
- Add `source_system_cd` to all 5 hubs
- Update unique constraints
- Document in schema

---

### 5. Link Satellites for Relationship Attributes

**Guideline:**
> "Links may have their own satellite to capture attributes of the relationship"

**Agreement:** ✅ **FULLY AGREE - NEEDS IMPLEMENTATION**

**Current Issue:**
- `link_portfolio_fund` contains `fund_sub_perspective_id` directly in link
- This violates DV2.0 principle: links should only contain hash keys

**Correct Approach:**
- Create `sat_link_portfolio_fund` for relationship attributes
- Move `fund_sub_perspective_id` to satellite
- Keep link minimal: only `hk_link`, `hk_portfolio`, `hk_fund`

**Example:**
```sql
-- Link (minimal)
SELECT 
    hk_link,
    hk_portfolio,
    hk_fund,
    row_create_ts
FROM ...

-- Link Satellite (attributes)
SELECT 
    hk_link,
    fund_sub_perspective_id,
    row_create_ts,
    ...
FROM ...
```

**Action Items:**
- Refactor `link_portfolio_fund` to remove attributes
- Create `sat_link_portfolio_fund`
- Review other links for similar issues

---

### 6. Denormalization Avoidance

**Guideline:**
> "Denormalization should be avoided... fund table can have currency code but not currency short name, currency symbol etc."

**Agreement:** ✅ **ALREADY IMPLEMENTED**

**Current State:**
- Hubs contain only business keys
- No denormalized attributes in hubs
- Currency details stay in `ref_currency` table

**Status:** ✅ No action needed

---

## ⚠️ NEEDS DISCUSSION (Require Business Input)

### 1. Effective Dating for Attributes Satellites

**Guideline:**
> "Consider effective dating for attributes satellites if historical queries are required"

**Question:** ❓ **DO WE NEED HISTORICAL QUERIES?**

**Current Implementation:**
- Attributes satellites use `hk_key` (row hash) for change detection
- No explicit `start_eff_ts`/`end_eff_ts`
- Current state only (latest record per `hk_fund`)

**Two Approaches:**

#### Option A: Current Approach (Snapshot-based)
```sql
-- Get current fund attributes
SELECT * FROM sat_fund_attributes
WHERE hk_key = (
    SELECT MAX(hk_key) FROM sat_fund_attributes 
    WHERE hk_fund = ?
)
```

**Pros:**
- Simpler implementation
- Faster queries (no date range logic)
- Sufficient if only current state needed

**Cons:**
- Cannot query "what was fund name on 2023-01-01?"
- No historical tracking

#### Option B: Effective Dating (Director's Approach)
```sql
-- Structure
hk_fund, fund_name, start_eff_ts, end_eff_ts, delete_ind

-- Query historical
SELECT * FROM sat_fund_attributes
WHERE hk_fund = ?
  AND start_eff_ts <= '2023-01-01'
  AND (end_eff_ts IS NULL OR end_eff_ts > '2023-01-01')
```

**Pros:**
- Full historical tracking
- Can query any point in time
- Standard SCD Type 2 pattern

**Cons:**
- More complex queries
- Slower performance
- Requires `end_eff_ts` maintenance

**Decision Needed:**
- Do business users need historical queries for attributes?
- Examples: "What was the fund name when we made investment X?"
- If yes → implement effective dating
- If no → keep current approach

**Recommendation:** Start with current approach, add effective dating later if needed (less disruptive than removing it)

---

### 2. Delete Indicator (Soft Deletes)

**Guideline:**
> "Add delete_ind if soft deletes are needed"

**Question:** ❓ **DO WE HAVE SOFT DELETES?**

**Current Implementation:**
- No `delete_ind` column
- Deletes handled via CDC in Bronze layer (`last_operation_ind = 'D'`)

**Scenarios to Consider:**
1. **Hard Deletes:** Record removed from source → removed from vault
2. **Soft Deletes:** Record marked as deleted but kept for audit

**Questions:**
- Do we need to track deleted entities for audit purposes?
- Example: "Show me all funds that were deleted in 2023"
- If yes → add `delete_ind`
- If no → current approach sufficient

**Recommendation:** Add `delete_ind` as nullable column (default NULL), populate when source indicates deletion

---

### 3. Naming Convention - Column Suffixes

**Guideline:**
> "Column names should end with class word like HK, ID, CD, NM, DSC, AMT, PCT, TXT, NBR, DT, TS, IND"

**Question:** ❓ **STANDARDIZE NOW OR PLAN MIGRATION?**

**Current Implementation:**
- Mixed naming: `hk_fund`, `fund_name`, `load_dt`
- Director wants: `fund_hk`, `fund_nm`, `row_create_ts`

**Impact Analysis:**
- **Low Impact:** New models only
- **High Impact:** Refactor all existing models + downstream dependencies
- **Breaking Change:** All Gold layer models reference Silver columns

**Options:**

#### Option A: Adopt New Standard (Full Migration)
- Refactor all 50+ models
- Update all Gold layer references
- Requires coordinated deployment
- **Timeline:** 2-3 sprints

#### Option B: Hybrid Approach
- New models use new standard
- Existing models keep current naming
- Gradual migration over time
- **Timeline:** 6+ months

#### Option C: Keep Current Standard
- Current naming is clear and consistent
- No business value in changing
- Focus effort on functional improvements

**Recommendation:** **Option B (Hybrid)** - Standardize new models, migrate existing gradually

**Talking Point:** "Naming is cosmetic. Should we prioritize functional improvements (link satellites, source tracking) over naming changes?"

---

### 4. Table Naming - Lowercase Confirmation

**Guideline:**
> "Table name in lower case? (tbd)"

**Current Implementation:**
- ✅ All tables lowercase: `hub_fund`, `sat_fund_attributes`
- ✅ All columns lowercase: `hk_fund`, `fund_name`

**Agreement:** ✅ **ALREADY COMPLIANT**

**Action:** Confirm with director that lowercase is approved standard

---

## ❌ TECHNICAL CONCERNS (Need Correction/Clarification)

### 1. Multi-Active Satellites - Misunderstanding

**Director's Guideline:**
> "Multi active satellites should be an exception"

**Current Implementation:**
- ✅ Already prevents multi-active via `hk_key` uniqueness constraint
- ✅ Each `(hk_fund, hk_key)` combination is unique

**Concern:** Director's statement is correct, but our implementation already enforces this. No change needed.

**Clarification Needed:** Is director aware we already prevent multi-active? Or is this a preventive guideline?

---

### 2. Satellite Primary Key Definition

**Director's Guideline:**
> "Unique primary key on entity_hk + start_eff_ts"

**Technical Issue:** ⚠️ **INCOMPLETE SPECIFICATION**

**Problem:**
- If using effective dating, PK should be `(entity_hk, start_eff_ts)` ✅
- If using current approach (row hash), PK should be `(entity_hk, hk_key)` ✅
- Director's guideline assumes effective dating, but we use row hash

**Current Implementation:**
```sql
-- We use hk_key for uniqueness
PRIMARY KEY (hk_fund, hk_key)
```

**If We Switch to Effective Dating:**
```sql
-- Would need to change to
PRIMARY KEY (hk_fund, start_eff_ts)
```

**Clarification Needed:**
- Does director want us to switch to effective dating?
- Or is guideline conditional on approach chosen?
- Need to align on approach before defining PKs

**Recommendation:** Discuss effective dating decision first (see section above), then define PK strategy

---

### 3. Hash Value Column Naming

**Director's Guideline:**
> "hash_value_id (or similar name) populated by hashing entity_key + all attributes"

**Current Implementation:**
- Column name: `hk_key`
- Purpose: Row-level hash for change detection
- Formula: `HEX_ENCODE(TO_CHAR(HASH(OBJECT_CONSTRUCT_KEEP_NULL(* EXCLUDE (load_dt))))`

**Technical Note:**
- Director suggests `hash_value_id` but our `hk_key` serves same purpose
- "ID" suffix implies identifier, but this is a hash value
- Better naming: `hash_value` or `row_hash` (not "ID")

**Recommendation:**
- Keep `hk_key` or rename to `row_hash` (more descriptive)
- Avoid `hash_value_id` (misleading suffix)

**Talking Point:** "`hk_key` is more descriptive than `hash_value_id`. The 'ID' suffix implies an identifier, but this is a hash value for change detection."

---

## 📋 IMPLEMENTATION PRIORITY

### Phase 1: Quick Wins (1-2 weeks)
1. ✅ Add `source_system_cd` to hubs
2. ✅ Create link satellites (refactor `link_portfolio_fund`)
3. ✅ Document REF pattern
4. ✅ Rename `load_dt` → `row_create_ts` (cosmetic)

### Phase 2: Business Decisions (Requires Input)
1. ⚠️ Decide on effective dating for attributes
2. ⚠️ Decide on `delete_ind` requirement
3. ⚠️ Confirm naming convention approach

### Phase 3: Structural Changes (If Approved)
1. ⚠️ Implement effective dating (if approved)
2. ⚠️ Add `delete_ind` (if approved)
3. ⚠️ Naming standardization (if approved)

---

## 🎯 KEY TALKING POINTS

### Opening Statement
> "We've reviewed the guidelines against our current implementation and Data Vault 2.0 best practices. Most align well, but we need to make some decisions together on a few items."

### For Effective Dating Discussion
> "Effective dating adds complexity. Before we implement it, we need to understand: do business users need to query historical attributes? For example, 'What was the fund name on 2023-01-01?' If not, our current snapshot approach is simpler and faster."

### For Naming Convention
> "Naming changes require refactoring 50+ models and all downstream dependencies. Should we prioritize functional improvements (link satellites, source tracking) over cosmetic naming changes? We can standardize new models and migrate existing gradually."

### For Technical Concerns
> "The guideline on primary keys assumes effective dating, but we currently use row hash. We should align on the approach first, then define the PK strategy. Also, `hash_value_id` is misleading - `hk_key` or `row_hash` is more descriptive."

---

## 📊 DECISION MATRIX

| Item | Status | Decision Needed | Impact | Timeline |
|------|--------|----------------|--------|----------|
| REF Pattern | ✅ Agreed | None | Low | Immediate |
| Hub Criteria | ✅ Agreed | None | Low | Immediate |
| Metrics Snapshots | ✅ Agreed | None | None | N/A |
| Source System Code | ✅ Agreed | None | Medium | 1 week |
| Link Satellites | ✅ Agreed | None | Medium | 2 weeks |
| Effective Dating | ⚠️ Discussion | Business need? | High | 3-4 weeks |
| Delete Indicator | ⚠️ Discussion | Audit requirement? | Low | 1 week |
| Naming Convention | ⚠️ Discussion | Standardize approach | High | 2-3 sprints |
| Multi-Active | ✅ Already compliant | None | None | N/A |
| PK Definition | ❌ Needs clarification | Approach alignment | Medium | TBD |
| Hash Column Name | ❌ Technical concern | Naming preference | Low | TBD |

---

## ✅ ACTION ITEMS FOR MEETING

1. **Confirm REF pattern** for currency, calendar ✅
2. **Approve source_system_cd** addition to hubs ✅
3. **Approve link satellites** implementation ✅
4. **Decide on effective dating** - get business requirements ⚠️
5. **Decide on delete_ind** - get audit requirements ⚠️
6. **Align on naming convention** approach (full migration vs. hybrid) ⚠️
7. **Clarify PK strategy** based on effective dating decision ❌
8. **Confirm hash column naming** preference ❌

---

## 📝 NOTES SECTION

_Use this space during the meeting to capture decisions and action items_

### Decisions Made:
- [ ] 
- [ ] 
- [ ] 

### Action Items:
- [ ] 
- [ ] 
- [ ] 

### Follow-up Questions:
- [ ] 
- [ ] 

---

## 🔗 REFERENCES

- Data Vault 2.0 Methodology: [Linstedt, Dan - Data Vault 2.0 Handbook]
- Current Architecture: `/docs/architecture.md`
- Data Dictionary: `/docs/data-dictionary.md`

---

**Prepared by:** [Your Name]  
**Date:** [Date]  
**Version:** 1.0
