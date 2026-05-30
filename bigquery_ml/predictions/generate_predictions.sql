-- Génération des prédictions sur 28 jours
-- Output : item_id, store_id, forecast_timestamp, forecast_value, prediction_interval

select
    item_id,
    store_id,
    forecast_timestamp,
    forecast_value,
    prediction_interval_lower_bound,
    prediction_interval_upper_bound
from ml.forecast (
        model `retail-demand-pipeline.retail_demand_pl_dataset.m5_forecast_model`, struct (
            28 as horizon, 0.9 as confidence_level
        )
    )
order by
    item_id,
    store_id,
    forecast_timestamp