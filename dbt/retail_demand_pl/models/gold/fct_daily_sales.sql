
with

sales as (
    select * from {{ ref('stg_m5_sales') }}
),

calendar as (
    select * from {{ ref('stg_m5_calendar') }}
),

sell_prices as (
    select * from {{ ref('stg_m5_sell_prices') }}
),

weather as (
    select * from {{ ref('stg_weather') }}
),

sales_with_calendar as (
    select
        sales.id            as sale_id,
        sales.item_id,
        sales.dept_id,
        sales.cat_id,
        sales.store_id,
        sales.state_id,
        sales.day           as day_id,
        sales.sales,
        calendar.calendar_date,
        calendar.wm_yr_wk,
        calendar.weekday,
        calendar.wday,
        calendar.month,
        calendar.year,
        calendar.event_name_1,
        calendar.event_type_1,
        calendar.event_name_2,
        calendar.event_type_2,
        calendar.snap_ca,
        calendar.snap_tx,
        calendar.snap_wi
    from sales
    left join calendar
        on concat('d_', cast(
            date_diff(calendar.calendar_date, date '2011-01-29', day) + 1
            as string)) = sales.day
),

sales_with_prices as (
    select
        sales_with_calendar.*,
        sell_prices.sell_price
    from sales_with_calendar
    left join sell_prices
        on sales_with_calendar.store_id = sell_prices.store_id
        and sales_with_calendar.item_id = sell_prices.item_id
        and sales_with_calendar.wm_yr_wk = sell_prices.wm_yr_wk
),

final as (
    select
        sales_with_prices.*,
        weather.temperature_max,
        weather.precipitation_sum
    from sales_with_prices
    left join weather
        on sales_with_prices.state_id = weather.state_id
        and sales_with_prices.calendar_date = weather.weather_date
)

select * from final