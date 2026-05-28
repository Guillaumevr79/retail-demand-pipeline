SELECT
    CAST(`date` AS DATE) AS calendar_date,
    CAST(wm_yr_wk AS INT64) AS wm_yr_wk,
    CAST(weekday AS STRING) AS weekday,
    CAST(wday AS INT64) AS wday,
    CAST(month AS INT64) AS month,
    CAST(year AS INT64) AS year,
    CAST(event_name_1 AS STRING) AS event_name_1,
    CAST(event_type_1 AS STRING) AS event_type_1,
    CAST(event_name_2 AS STRING) AS event_name_2,
    CAST(event_type_2 AS STRING) AS event_type_2,
    CAST(snap_CA AS INT64)  AS snap_ca,
    CAST(snap_TX AS INT64)  AS snap_tx,
    CAST(snap_WI AS INT64)  AS snap_wi
FROM {{ source('bronze', 'm5_calendar_ext') }}