-- fund_hier eqwuates to fund_network_path
-- every fund-subperspective_id can have multiple fund_hier, percentage and amount
-- a fund hier consists of a primary fund and the initial few letters denote the feeder fund

WITH fund_hier_columns AS (
  SELECT ivo.L29_id, 
    fspfn.fund_sub_perspective_id, 
    ivo.fund_hier_id, 
    ivo.fund_hier,
    max(ivo.hier_percentage) hier_percentage
  FROM {{ source('bronze_from_harborview_edw', 'fund_hiers_pct_hist') }} ivo 
  JOIN {{ source('bronze_from_harborview_edw', 'fact_fund_sub_perspective_fund_network_paths') }} fspfn 
    ON ivo.fund_hier_id = fspfn.fund_hier_id
  WHERE ivo.ownership_quarter_seq = 0
  GROUP BY ivo.L29_id, fspfn.fund_sub_perspective_id, ivo.fund_hier_id, ivo.fund_hier
),
final_fund_network_path as (
  SELECT fh.fund_sub_perspective_id, 
    fh.hier_percentage, 
    cv.amount * fh.hier_percentage hier_amount,
    fh.fund_hier_id, 
    fh.fund_hier,
    current_date() as load_dt
  FROM fund_hier_columns fh
  JOIN {{ source('bronze_from_harborview_edw', 'fact_company_valuation') }} cv
    ON fh.L29_id = cv.fund_id
)

{{ append_hk_key_column('final_fund_network_path') }}