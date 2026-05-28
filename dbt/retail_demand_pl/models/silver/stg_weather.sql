
with

california_source as (
    select * from {{ source('bronze', 'weather_california_ext') }}
),

texas_source as (
    select * from {{ source('bronze', 'weather_texas_ext') }}
),

wisconsin_source as (
    select * from {{ source('bronze', 'weather_wisconsin_ext') }}
),

california_unnested as (
    select
        'CA'                                                        as state_id,
        cast(date_val as date)                                      as weather_date,
        cast(temp_val as float64)                                   as temperature_max,
        cast(precip_val as float64)                                 as precipitation_sum
    from california_source,
    unnest(json_value_array(_airbyte_data, '$.time')) as date_val with offset pos
    join unnest(json_value_array(_airbyte_data, '$.temperature_2m_max')) as temp_val with offset pos2 on pos = pos2
    join unnest(json_value_array(_airbyte_data, '$.precipitation_sum')) as precip_val with offset pos3 on pos = pos3
),

texas_unnested as (
    select
        'TX'                                                        as state_id,
        cast(date_val as date)                                      as weather_date,
        cast(temp_val as float64)                                   as temperature_max,
        cast(precip_val as float64)                                 as precipitation_sum
    from texas_source,
    unnest(json_value_array(_airbyte_data, '$.time')) as date_val with offset pos
    join unnest(json_value_array(_airbyte_data, '$.temperature_2m_max')) as temp_val with offset pos2 on pos = pos2
    join unnest(json_value_array(_airbyte_data, '$.precipitation_sum')) as precip_val with offset pos3 on pos = pos3
),

wisconsin_unnested as (
    select
        'WI'                                                        as state_id,
        cast(date_val as date)                                      as weather_date,
        cast(temp_val as float64)                                   as temperature_max,
        cast(precip_val as float64)                                 as precipitation_sum
    from wisconsin_source,
    unnest(json_value_array(_airbyte_data, '$.time')) as date_val with offset pos
    join unnest(json_value_array(_airbyte_data, '$.temperature_2m_max')) as temp_val with offset pos2 on pos = pos2
    join unnest(json_value_array(_airbyte_data, '$.precipitation_sum')) as precip_val with offset pos3 on pos = pos3
),

all_states as (
    select * from california_unnested
    union all
    select * from texas_unnested
    union all
    select * from wisconsin_unnested
)

select * from all_states