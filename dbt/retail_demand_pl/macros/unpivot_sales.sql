{% macro generate_unpivot_sales() %}


SELECT
    CAST(id AS STRING) AS id,
    CAST(item_id AS STRING) AS item_id,
    CAST(dept_id AS STRING) AS dept_id,
    CAST(cat_id AS STRING) AS cat_id,
    CAST(store_id AS STRING) AS store_id,
    CAST(state_id AS STRING) AS state_id,
    day,
    CAST(sales AS FLOAT64)   AS sales
FROM {{ source('bronze', 'm5_sales_ext') }}
UNPIVOT (sales FOR day IN (
    {% for i in range(1, 1914) %}
        d_{{ i }}{% if not loop.last %},{% endif %}
    {% endfor %}
))

{% endmacro %}