with daily_metrics as (
    SELECT
    DATE(date_id, 'YYYYMMDD') as as_of_date,
    sha2(upper(trim(fid.source_table_col_val))) as hk_fund,
    c.currency_code,
    SUM(
        CASE
            WHEN t.metric_id in (12, 13, 14, 15, 16, 17, 18, 185, 214, 215) THEN t.amount
            WHEN t.metric_id in (40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63) THEN -1*t.amount
            WHEN t.metric_id in (83, 86, 87, 88, 89, 90, 91, 92, 93, 94, 96, 103, 104, 105, 106, 107, 110, 111, 120, 108, 109, 164, 119, 95, 85, 98, 100, 102, 121, 122, 123, 124, 125, 126, 127, 128, 129, 131, 133, 84, 97, 99, 101, 112, 113, 114, 115, 116, 117, 118, 130, 132, 233, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 234, 235, 236, 237, 238, 239, 240, 241, 245, 246, 247, 248, 249, 347, 366, 367, 368, 369, 372, 375, 371, 374, 377, 370, 373, 376, 378, 379, 380, 382, 384, 386, 381, 383, 385, 398, 399, 400, 346, 85, 514, 94, 510, 96, 515, 347, 485, 108, 460, 111, 120, 517, 459, 460, 461, 462, 463, 464, 465) 
                AND DATE(date_id, 'YYYYMMDD') <= DATE(f.lock_date, 'YYYYMMDD') THEN t.amount
            ELSE 0
        END
    ) as nav,
    0 as tvpi,
    0 as irr_gross,
    0 as irr_net,
    SUM(
        CASE
            WHEN t.metric_id in (42, 40, 41, 46, 43, 45, 47, 48, 44, 49, 54, 55, 56, 57, 58, 59, 61, 60, 50, 51, 52, 53, 62, 63, 323, 324, 325, 326, 327, 328) THEN t.amount
            ELSE 0
        END
    ) as distributions,
    SUM(
        CASE
            WHEN t.metric_id in (12, 13, 14, 15, 16, 17, 18, 185, 214, 215) THEN t.amount
            ELSE 0
        END
    ) as contributions,
    nav + distributions as total_value,
    0 as commitments,
    0 as capital_called,
    0 as gain_loss,
    0 as pme_irr_1,
    0 as pme_irr_2,
    0 as pme_irr_msciaw,
    CURRENT_TIMESTAMP() as load_dt,
    t.file_name as record_source

    FROM (
        SELECT * FROM {{ source('hv_source', 'fact_investor_transactions') }} WHERE investor_type = 'LP'
    ) t
    JOIN {{ source('hv_source', 'currency') }} c
        ON t.currency_id = c.currency_id
    JOIN {{ source('hv_source', 'global_edw_key_to_iqid') }} fid
        ON t.fund_id = fid.edw_key AND fid.source_table = 'fund_xref'
    JOIN {{ source('hv_source', 'dim_fund') }} f
        ON t.fund_id = f.fund_id
    GROUP BY as_of_date, hk_fund, currency_code, t.file_name
)

SELECT 
    as_of_date,
    hk_fund,
    currency_code,
    SUM(nav) OVER (
        PARTITION BY hk_fund, currency_code
        ORDER BY as_of_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) as nav,
    tvpi,
    irr_gross,
    irr_net,
    SUM(distributions) OVER (
        PARTITION BY hk_fund, currency_code
        ORDER BY as_of_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) as distributions,
    SUM(contributions) OVER (
        PARTITION BY hk_fund, currency_code
        ORDER BY as_of_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) as contributions,
    SUM(total_value) OVER (
        PARTITION BY hk_fund, currency_code
        ORDER BY as_of_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) as total_value,
    commitments,
    capital_called,
    gain_loss,
    pme_irr_1,
    pme_irr_2,
    pme_irr_msciaw,
    HEX_ENCODE(HASH(as_of_date, hk_fund, currency_code, nav, tvpi, irr_gross, irr_net, distributions, contributions, total_value, commitments, capital_called, gain_loss, pme_irr_1, pme_irr_2, pme_irr_msciaw)) as skey,
    load_dt,
    record_source
FROM (daily_metrics)
ORDER BY as_of_date
