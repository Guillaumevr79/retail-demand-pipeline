
SELECT
    'CA' AS state_id,
    CAST(date_val AS DATE) AS weather_date,
    CAST(temp_val AS FLOAT64) AS temperature_max,
    CAST(precip_val AS FLOAT64) AS precipitation_sum
FROM {{ source('bronze', 'weather_california_ext') }},
UNNEST(JSON_VALUE_ARRAY(time)) AS date_val WITH OFFSET pos
JOIN UNNEST(JSON_VALUE_ARRAY(temperature_2m_max)) AS temp_val WITH OFFSET pos2 ON pos = pos2
JOIN UNNEST(JSON_VALUE_ARRAY(precipitation_sum)) AS precip_val WITH OFFSET pos3 ON pos = pos3

UNION ALL

SELECT
    'TX' AS state_id,
    CAST(date_val AS DATE) AS weather_date,
    CAST(temp_val AS FLOAT64) AS temperature_max,
    CAST(precip_val AS FLOAT64) AS precipitation_sum
FROM {{ source('bronze', 'weather_texas_ext') }},
UNNEST(JSON_VALUE_ARRAY(time)) AS date_val WITH OFFSET pos
JOIN UNNEST(JSON_VALUE_ARRAY(temperature_2m_max)) AS temp_val WITH OFFSET pos2 ON pos = pos2
JOIN UNNEST(JSON_VALUE_ARRAY(precipitation_sum)) AS precip_val WITH OFFSET pos3 ON pos = pos3

UNION ALL

SELECT
    'WI' AS state_id,
    CAST(date_val AS DATE) AS weather_date,
    CAST(temp_val AS FLOAT64) AS temperature_max,
    CAST(precip_val AS FLOAT64) AS precipitation_sum
FROM {{ source('bronze', 'weather_wisconsin_ext') }},
UNNEST(JSON_VALUE_ARRAY(time)) AS date_val WITH OFFSET pos
JOIN UNNEST(JSON_VALUE_ARRAY(temperature_2m_max)) AS temp_val WITH OFFSET pos2 ON pos = pos2
JOIN UNNEST(JSON_VALUE_ARRAY(precipitation_sum)) AS precip_val WITH OFFSET pos3 ON pos = pos3