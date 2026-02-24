/*
Clean View / Rules
------------------
This script creates or replaces the Postgres view vw_yellow_clean_tip from stg_yellow_trips
and enriches it with pickup/drop-off zone info by joining dim_taxi_zone (PU + DO).

It adds derived fields for time, duration, pre-tip totals, and tipping KPIs
(e.g., pretip_total, is_tipped, tip_rate_fare, tip_rate_pretip).

It also filters out invalid trips using plausibility rules:
- valid timestamps
- max duration 6h
- positive fare and distance
- non-negative tips
- positive pre-tip total

Surcharges are validated by enforcing:
- improvement_surcharge = 1.00
- mta_tax in (0.00, 0.50)
*/

CREATE OR REPLACE VIEW {PG_SCHEMA}.vw_yellow_clean_tip AS
SELECT
    t.vendorid,
    t.tpep_pickup_datetime,
    t.tpep_dropoff_datetime,
    t.passenger_count,
    t.trip_distance,
    t.ratecodeid,
    t.pulocationid,
    t.dolocationid,
    t.payment_type,
    t.fare_amount,
    t.extra,
    t.mta_tax,
    t.tip_amount,
    t.tolls_amount,
    t.improvement_surcharge,
    t.total_amount,
    t.congestion_surcharge,
    t.airport_fee,
    t.cbd_congestion_fee,
    t.source_file,
    t.ingested_at,

    -- time features
    EXTRACT(HOUR FROM t.tpep_pickup_datetime)::int AS pickup_hour,
    EXTRACT(DOW  FROM t.tpep_pickup_datetime)::int AS pickup_dow,
    DATE_TRUNC('day', t.tpep_pickup_datetime)::date AS pickup_date,
    DATE_TRUNC('month', t.tpep_pickup_datetime)::date AS pickup_month,

    -- duration (min)
    EXTRACT(EPOCH FROM (t.tpep_dropoff_datetime - t.tpep_pickup_datetime)) / 60.0 AS duration_min,

    -- totals
    (t.total_amount - t.tip_amount) AS pretip_total,
    ((t.total_amount - t.tip_amount) - t.fare_amount) AS extras_pretip,

    -- tip KPIs
    (t.tip_amount > 0)::int AS is_tipped,
    CASE WHEN t.fare_amount > 0 THEN (t.tip_amount / t.fare_amount) END AS tip_rate_fare,
    CASE WHEN (t.total_amount - t.tip_amount) > 0 THEN (t.tip_amount / (t.total_amount - t.tip_amount)) END AS tip_rate_pretip,

    -- geo joins
    pu.borough AS pu_borough,
    pu.zone    AS pu_zone,
    pu.service_zone AS pu_service_zone,
    do_.borough AS do_borough,
    do_.zone    AS do_zone,
    do_.service_zone AS do_service_zone

FROM {PG_SCHEMA}.stg_yellow_trips t
LEFT JOIN {PG_SCHEMA}.dim_taxi_zone pu ON t.pulocationid = pu.locationid
LEFT JOIN {PG_SCHEMA}.dim_taxi_zone do_ ON t.dolocationid = do_.locationid
WHERE
    -- plausibility rules
    t.tpep_pickup_datetime IS NOT NULL
    AND t.tpep_dropoff_datetime IS NOT NULL
    AND t.tpep_dropoff_datetime > t.tpep_pickup_datetime
    AND (t.tpep_dropoff_datetime - t.tpep_pickup_datetime) <= INTERVAL '6 hours'
    AND t.fare_amount > 0
    AND t.trip_distance > 0
    AND t.tip_amount >= 0
    AND (t.total_amount - t.tip_amount) > 0

    -- surcharge sanity (as agreed)
    AND t.improvement_surcharge = 1.00
    AND t.mta_tax IN (0.00, 0.50);

