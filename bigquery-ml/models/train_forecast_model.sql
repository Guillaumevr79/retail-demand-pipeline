-- Entraînement du modèle ARIMA_PLUS sur les ventes M5
-- Horizon : 28 jours (conforme à la compétition M5)
-- Séries temporelles : par item_id + store_id (42k séries)
-- Durée estimée : 10-20 minutes

CREATE OR REPLACE MODEL `retail-demand-pipeline.retail_demand_pl_dataset.m5_forecast_model`
OPTIONS (
    model_type = 'ARIMA_PLUS',
    time_series_timestamp_col = 'calendar_date',
    time_series_data_col = 'sales',
    time_series_id_col = ['item_id', 'store_id'],
    horizon = 28,
    auto_arima = true,
    data_frequency = 'AUTO_FREQUENCY',
    decompose_time_series = true
) AS
select
    calendar_date,
    item_id,
    store_id,
    sales
from `retail-demand-pipeline.retail_demand_pl_dataset.fct_demand_features`
where sales is not null