
with

daily_sales as (
    select * from {{ ref('fct_daily_sales') }}
),

sales_with_lags as (
    select
        sale_id,
        item_id,
        dept_id,
        cat_id,
        store_id,
        state_id,
        calendar_date,
        day_id,
        sales,
        sell_price,
        temperature_max,
        precipitation_sum,
        event_name_1,
        event_type_1,
        snap_ca,
        snap_tx,
        snap_wi,
        month,
        year,
        wday,

-- Lags
lag(sales, 7) over (
    partition by
        item_id,
        store_id
    order by calendar_date
) as sales_lag_7,
lag(sales, 14) over (
    partition by
        item_id,
        store_id
    order by calendar_date
) as sales_lag_14,
lag(sales, 28) over (
    partition by
        item_id,
        store_id
    order by calendar_date
) as sales_lag_28,

-- Rolling averages
avg(sales) over (
    partition by
        item_id,
        store_id
    order by
        calendar_date rows between 6 preceding
        and current row
) as rolling_avg_7d,
avg(sales) over (
    partition by
        item_id,
        store_id
    order by
        calendar_date rows between 27 preceding
        and current row
) as rolling_avg_28d,

-- Rolling std

stddev(sales) over (
            partition by item_id, store_id
            order by calendar_date
            rows between 27 preceding and current row
        ) as rolling_std_28d

    from daily_sales
),

final as (
    select
        *,
        -- Indicateur événement
        case
            when event_name_1 is not null then 1
            else 0
        end as has_event,

-- SNAP applicable par état

case state_id
            when 'CA' then snap_ca
            when 'TX' then snap_tx
            when 'WI' then snap_wi
            else 0
        end as snap_applicable

    from sales_with_lags
)

select * from final