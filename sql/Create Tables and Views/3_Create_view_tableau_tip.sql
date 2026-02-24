/*
Tableau View
------------
For Tableau, a dedicated view is provided that includes all required raw and feature fields
(time features, geo labels, amount columns including fees, pretip_total, extras_pretip, and
two tip rates: one based on fare and one based on the pre-tip total amount).

This keeps KPI definitions centrally consistent in SQL, while Tableau can focus on
visualization and interactivity.
*/

CREATE OR REPLACE VIEW {PG_SCHEMA}.vw_tableau_tip AS
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

    -- tip measures
    tip_amount,
    tip_rate_fare,
    (tip_rate_fare * 100.0) AS tip_rate_fare_pct,
    tip_rate_pretip,
    (tip_rate_pretip * 100.0) AS tip_rate_pretip_pct,
    is_tipped,

    -- payment + geo
    pulocationid,
    pu_borough,
    pu_zone,
    dolocationid,
    do_borough,
    do_zone,

    CASE
      WHEN pu_zone ILIKE '%JFK%' OR do_zone ILIKE '%JFK%' THEN 1
      WHEN pu_zone ILIKE '%LaGuardia%' OR do_zone ILIKE '%LaGuardia%' THEN 1
      ELSE 0
    END AS is_airport_trip,

    source_file
FROM {PG_SCHEMA}.vw_yellow_clean_tip;
