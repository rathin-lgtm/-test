{% macro irr_calendar() %}
/* IRR calcs in HVW have a pattern of mapping to a rollback calendar. This is used for both fund and portfolio IRRs.
This data sources from a system called HV reference -- in the future we should replace this by self-generating a calendar with date functions or design queries to not require it.
 */
SELECT 
    txn.date_id as rollup_date_id, 
    rd.date_id as rollup_to_date_id,
    DATEADD(year, 0, DATE(case when txn.date_id = -1 then NULL else txn.date_id end, 'YYYYMMDD')) as Date_fact,
    DATEADD(year, 0, DATE(case when rd.date_id = -1 then NULL else rd.date_id end, 'YYYYMMDD')) as Date_Dim,
    LAST_DAY(DATEADD(year, -1, DATE(case when rd.date_id = -1 then NULL else rd.date_id end, 'YYYYMMDD'))) as Date_1_Year,
    LAST_DAY(DATEADD(year, -2, DATE(case when rd.date_id = -1 then NULL else rd.date_id end, 'YYYYMMDD'))) as Date_2_Year,
    LAST_DAY(DATEADD(year, -3, DATE(case when rd.date_id = -1 then NULL else rd.date_id end, 'YYYYMMDD'))) as Date_3_Year,
    LAST_DAY(DATEADD(year, -4, DATE(case when rd.date_id = -1 then NULL else rd.date_id end, 'YYYYMMDD'))) as Date_4_Year,
    LAST_DAY(DATEADD(year, -5, DATE(case when rd.date_id = -1 then NULL else rd.date_id end, 'YYYYMMDD'))) as Date_5_Year,
    LAST_DAY(DATEADD(year, -7, DATE(case when rd.date_id = -1 then NULL else rd.date_id end, 'YYYYMMDD'))) as Date_7_Year,
    LAST_DAY(DATEADD(year, -10, DATE(case when rd.date_id = -1 then NULL else rd.date_id end, 'YYYYMMDD'))) as Date_10_Year,
    LAST_DAY(DATEADD(year, -15, DATE(case when rd.date_id = -1 then NULL else rd.date_id end, 'YYYYMMDD'))) as Date_15_Year
FROM {{ ref('calendar') }} txn
JOIN  (
    SELECT * 
    FROM {{ ref('calendar') }} 
    WHERE DATE_ID IN (
        SELECT month_end_date 
        FROM {{ ref('calendar_month') }} 
        WHERE month_id <> -1
    ) OR Date_ID IN (
        SELECT quarter_id 
        FROM {{ ref('calendar_quarter') }} 
        WHERE quarter_counter = 1
    )) rd
ON txn.date_id <= rd.date_id
UNION
SELECT 
    cal.date_id as rollup_date_id,
    cal.date_id as rollup_to_date_id,
    DATEADD(year, 0, DATE(case when cal.date_id = -1 then NULL else cal.date_id end, 'YYYYMMDD')) as Date_fact,
    DATEADD(year, 0, DATE(case when cal.date_id = -1 then NULL else cal.date_id end, 'YYYYMMDD')) as Date_Dim,
    LAST_DAY(DATEADD(year, -1, DATE(case when cal.date_id = -1 then NULL else cal.date_id end, 'YYYYMMDD'))) as Date_1_Year,
    LAST_DAY(DATEADD(year, -2, DATE(case when cal.date_id = -1 then NULL else cal.date_id end, 'YYYYMMDD'))) as Date_2_Year,
    LAST_DAY(DATEADD(year, -3, DATE(case when cal.date_id = -1 then NULL else cal.date_id end, 'YYYYMMDD'))) as Date_3_Year,
    LAST_DAY(DATEADD(year, -4, DATE(case when cal.date_id = -1 then NULL else cal.date_id end, 'YYYYMMDD'))) as Date_4_Year,
    LAST_DAY(DATEADD(year, -5, DATE(case when cal.date_id = -1 then NULL else cal.date_id end, 'YYYYMMDD'))) as Date_5_Year,
    LAST_DAY(DATEADD(year, -7, DATE(case when cal.date_id = -1 then NULL else cal.date_id end, 'YYYYMMDD'))) as Date_7_Year,
    LAST_DAY(DATEADD(year, -10, DATE(case when cal.date_id = -1 then NULL else cal.date_id end, 'YYYYMMDD'))) as Date_10_Year,
    LAST_DAY(DATEADD(year, -15, DATE(case when cal.date_id = -1 then NULL else cal.date_id end, 'YYYYMMDD'))) as Date_15_Year
FROM {{ ref('calendar') }} cal 
WHERE DATE_ID in (
    SELECT month_end_date
    FROM {{ ref('calendar_month') }}
    WHERE month_id <> -1
) OR Date_ID in (
    SELECT quarter_id 
    FROM {{ ref('calendar_quarter') }}
    WHERE quarter_counter = 1
)                         
{% endmacro %}