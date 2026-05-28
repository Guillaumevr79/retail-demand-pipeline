
with

source as (
    select * from {{ source('bronze', 'm5_sell_prices_ext') }}
),

renamed as (
    select
        cast(store_id as string)    as store_id,
        cast(item_id as string)     as item_id,
        cast(wm_yr_wk as int64)     as wm_yr_wk,
        cast(sell_price as float64) as sell_price
    from source
)

select * from renamed