
with

source as (
    select * from {{ source('bronze', 'm5_calendar_ext') }}
),

renamed as (
    select
        cast(`date` as date) as calendar_date,
        cast(wm_yr_wk as int64) as wm_yr_wk,
        cast(weekday as string) as weekday,
        cast(wday as int64) as wday,
        cast(month as int64) as month,
        cast(year as int64) as year,
        cast(d as string) as day_id,
        cast(event_name_1 as string)  as event_name_1,
        cast(event_type_1 as string)  as event_type_1,
        cast(event_name_2 as string)  as event_name_2,
        cast(event_type_2 as string)  as event_type_2,
        cast(snap_CA as int64) as snap_ca,
        cast(snap_TX as int64) as snap_tx,
        cast(snap_WI as int64) as snap_wi
    from source
)

select * from renamed