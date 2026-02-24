-- Delete Existing Views

DROP VIEW IF EXISTS s_patrickpaubandt.vw_yellow_clean_tip;

DROP VIEW IF EXISTS s_patrickpaubandt.vw_tableau_tip_bid;

DROP VIEW IF EXISTS s_patrickpaubandt.vw_tableau_tip



-- Create or Replace View vw_yellow_clean_tip

CREATE OR REPLACE VIEW s_patrickpaubandt.vw_yellow_clean_tip AS
SELECT
    t.vendorid,
    t.tpep_pickup_datetime,
    t.tpep_dropoff_datetime,
    t.passenger_count,
    t.trip_distance,
    t.ratecodeid,
    t.store_and_fwd_flag,
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

FROM s_patrickpaubandt.stg_yellow_trips t
LEFT JOIN s_patrickpaubandt.dim_taxi_zone pu ON t.pulocationid = pu.locationid
LEFT JOIN s_patrickpaubandt.dim_taxi_zone do_ ON t.dolocationid = do_.locationid
WHERE
    -- month boundary by pickup datetime (September 2025)
    t.tpep_pickup_datetime >= TIMESTAMP '2025-09-01'
    AND t.tpep_pickup_datetime <  TIMESTAMP '2025-10-01'

    -- plausibility rules
    AND t.tpep_pickup_datetime IS NOT NULL
    AND t.tpep_dropoff_datetime IS NOT NULL
    AND t.tpep_dropoff_datetime > t.tpep_pickup_datetime
    AND t.fare_amount > 0
    AND t.trip_distance > 0
    AND t.tip_amount >= 0
    AND (t.total_amount - t.tip_amount) > 0;
    
-- Create View tableau_tip 

CREATE VIEW s_patrickpaubandt.vw_tableau_tip AS
SELECT
    pickup_date,
    pickup_month,
    pickup_hour,
    pickup_dow,
    CASE pickup_dow
      WHEN 0 THEN 'Sun'
      WHEN 1 THEN 'Mon'
      WHEN 2 THEN 'Tue'
      WHEN 3 THEN 'Wed'
      WHEN 4 THEN 'Thu'
      WHEN 5 THEN 'Fri'
      WHEN 6 THEN 'Sat'
    END AS pickup_dow_name,

    -- core trip measures
    trip_distance,
    duration_min,
    passenger_count,

    -- amounts
    fare_amount,
    extra,
    mta_tax,
    improvement_surcharge,
    congestion_surcharge,
    airport_fee,
    cbd_congestion_fee,
    tolls_amount,
    pretip_total,
    extras_pretip,
    total_amount,

    -- tip measures (pct columns removed)
    tip_amount,
    tip_rate_fare,
    tip_rate_pretip,
    is_tipped,

    -- payment + geo
    payment_type,
    payment_group,
    pulocationid,
    pu_borough,
    pu_zone,
    dolocationid,
    do_borough,
    do_zone,

    CASE
      WHEN pu_zone ILIKE '%JFK%' OR do_zone ILIKE '%JFK%' THEN 1
      WHEN pu_zone ILIKE '%LaGuardia%' OR do_zone ILIKE '%LaGuardia%' THEN 1
      WHEN pu_borough = 'EWR' OR do_borough = 'EWR' THEN 1
      ELSE 0
    END AS is_airport_trip,

    source_file
FROM s_patrickpaubandt.vw_yellow_clean_tip
WHERE
    improvement_surcharge = 1.00
    AND mta_tax IN (0.00, 0.50);
    
    
    
    
    
    

-- create vw_tableau_tip_bid 
CREATE VIEW s_patrickpaubandt.vw_tableau_tip_bid AS
SELECT
    t.*,
    pu.bid_count           AS pu_bid_count,
    pu.has_bid             AS pu_has_bid,
    pu.overlap_share       AS pu_bid_overlap_share,
    pu.overlap_share_pct   AS pu_bid_overlap_share_pct,
    do_.bid_count          AS do_bid_count,
    do_.has_bid            AS do_has_bid,
    do_.overlap_share      AS do_bid_overlap_share,
    do_.overlap_share_pct  AS do_bid_overlap_share_pct
FROM s_patrickpaubandt.vw_tableau_tip t
LEFT JOIN s_patrickpaubandt.dim_zone_bid pu
    ON pu.locationid = t.pulocationid
LEFT JOIN s_patrickpaubandt.dim_zone_bid do_
    ON do_.locationid = t.dolocationid;







