SELECT
    CAST(store_id AS STRING)    AS store_id,
    CAST(item_id AS STRING)     AS item_id,
    CAST(wm_yr_wk AS INT64)     AS wm_yr_wk,
    CAST(sell_price AS FLOAT64) AS sell_price
FROM {{ source('bronze', 'm5_sell_prices_ext') }}