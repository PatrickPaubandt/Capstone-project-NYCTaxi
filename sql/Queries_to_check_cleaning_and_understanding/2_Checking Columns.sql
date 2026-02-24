-- 1) dim_bid: Count rows + distincts across key fields to sanity-check uniqueness and detect duplicate/odd imports
SELECT
  COUNT(*) AS rows,
  COUNT(DISTINCT shape_area)   AS distinct_shape_area,
  COUNT(DISTINCT objectid_1)   AS distinct_objectid_1,
  COUNT(DISTINCT f_all_bi_1)   AS distinct_borough,
  COUNT(DISTINCT f_all_bi_2)   AS distinct_bid_name,
  COUNT(DISTINCT f_all_bi_6)   AS distinct_funding,
  COUNT(DISTINCT shape_leng)   AS distinct_shape_leng,
  COUNT(DISTINCT id)           AS distinct_id,
  COUNT(DISTINCT year_found)   AS distinct_year_found,
  COUNT(DISTINCT f_all_bi_3)   AS distinct_some_field3,
  COUNT(DISTINCT f_all_bi_7)   AS distinct_some_field7,
  COUNT(DISTINCT objectid_2)   AS distinct_objectid_2,
  COUNT(DISTINCT f_all_bi_4)   AS distinct_url,
  COUNT(DISTINCT shape_ar_1)   AS distinct_shape_ar_1,
  COUNT(DISTINCT shape_le_1)   AS distinct_shape_le_1,
  COUNT(DISTINCT f_all_bids)   AS distinct_f_all_bids
FROM dim_bid;

-- 2) dim_bid: List distinct BID names to confirm expected labels and spot naming duplicates
SELECT DISTINCT(f_all_bi_2)
FROM dim_bid

-- 3) vw_tableau_tip_bid: Cross-tab improvement_surcharge by payment_group to validate cleaning rules and payment segmentation
SELECT 
    improvement_surcharge, payment_group,
    COUNT(*) AS anzahl
FROM vw_tableau_tip_bid
GROUP BY improvement_surcharge, payment_group;

-- 4) vw_tableau_tip_bid: Show where airport_fee=1.75 occurs by pickup zone to verify it concentrates at airport zones (JFK/LGA)
SELECT
    airport_fee,
    pu_zone,
    COUNT(*) AS anzahl
FROM vw_tableau_tip_bid
WHERE airport_fee = 1.75
GROUP BY
    airport_fee,
    pu_zone
ORDER BY
    anzahl DESC;

-- 5) stg_yellow_trips: Check the distribution of mta_tax values to confirm which values should be kept by filters
SELECT 
    mta_tax,
    COUNT(*) AS anzahl
FROM stg_yellow_trips
GROUP BY mta_tax;


-- 6) vw_tableau_tip_bid + dim_taxi_zone: Re-derive pu_zone via join for airport_fee trips to QA zone labeling and joins
SELECT
  y.PULocationID,
  pu.Zone AS pu_zone,
  COUNT(*) AS n
FROM vw_tableau_tip_bid y
JOIN dim_taxi_zone pu
  ON pu.LocationID = y.PULocationID
WHERE y.airport_fee = 1.75
GROUP BY y.PULocationID, pu.Zone
ORDER BY n DESC;

-- 7) vw_tableau_tip_bid: Identify airport_fee trips whose pu_zone is not JFK/LGA 
--    to quantify “airport-fee but non-airport zone” edge cases.
SELECT
  y.PULocationID,
  y.pu_zone,
  COUNT(*) AS n
FROM vw_tableau_tip_bid y
WHERE y.airport_fee = 1.75
  AND y.pu_zone NOT IN ('JFK Airport', 'LaGuardia Airport')
GROUP BY y.PULocationID, y.pu_zone
ORDER BY n DESC;

-- 8) vw_tableau_tip_bid: 
--    Compute the share of airport_fee trips not picked up at JFK/LGA LocationIDs to measure potential misclassification
SELECT
  COUNT(*) AS total_airport_fee_trips,
  SUM(CASE WHEN PULocationID IN (132,138) THEN 1 ELSE 0 END) AS pu_is_jfk_or_lga,
  SUM(CASE WHEN PULocationID NOT IN (132,138) THEN 1 ELSE 0 END) AS pu_not_jfk_or_lga,
  1.0 * SUM(CASE WHEN PULocationID NOT IN (132,138) THEN 1 ELSE 0 END) / COUNT(*) AS share_not_jfk_or_lga
FROM vw_tableau_tip_bid
WHERE airport_fee = 1.75;

-- 9) vw_tableau_tip_bid + dim_taxi_zone: 
--    Check for suspicious values where improvement_surch equals 1.75 (possible typo/field mix-up vs airport_fee)
SELECT
  y.PULocationID,
  pu.Zone AS pu_zone,
  COUNT(*) AS n
FROM vw_tableau_tip_bid y
JOIN dim_taxi_zone pu
  ON pu.LocationID = y.PULocationID
WHERE y.improvement_surch = 1.75
GROUP BY y.PULocationID, pu.Zone
ORDER BY n DESC;

-- 10)  vw_tableau_tip_bid: 
--      List pickup zones with improvement_surcharge < 1.00 to spot anomalous surcharge values that should be filtered out.
SELECT
    pu_zone,
    improvement_surcharge,
    COUNT(*) AS anzahl
FROM vw_tableau_tip_bid
WHERE improvement_surcharge < 1.00
GROUP BY
    pu_zone,
    improvement_surcharge
ORDER BY
    anzahl DESC;

-- 11)  stg_yellow_trips: 
--      Profile improvement_surcharge=0.00 by VendorID/RatecodeID/payment_type to understand which segments produce those anomalies
SELECT
  VendorID,
  RatecodeID,
  payment_type,
  COUNT(*) AS n
FROM stg_yellow_trips
WHERE improvement_surcharge = 0.00
GROUP BY VendorID, RatecodeID, payment_type
ORDER BY n DESC;

-- 12)vw_tableau_tip_bid: 
--    Find negative tip_rate_fare values to detect calculation/data issues (e.g., negative tips or bad denominators).
SELECT tip_rate_fare
FROM vw_tableau_tip_bid
Where tip_rate_fare < 0;

-- 13)  vw_tableau_tip_bid: 
--      Recompute and compare tip_rate_fare vs tip_rate_fare_pct to validate percent scaling and derived KPI consistency.
SELECT
  ROUND( ((tip_rate_fare * 100) - tip_rate_fare_pct)::numeric, 1 ) AS test_tiprate_fare,
  *
FROM vw_tableau_tip_bid
WHERE tip_rate_fare < 0
  AND ROUND( ((tip_rate_fare * 100) - tip_rate_fare_pct)::numeric, 1 ) <> 0;

-- 14)vw_tableau_tip_bid: 
--    For improvement_surcharge=0.00 and suspicious PU zones, inspect PU→DO pairs to see if bad labels/clusters explain the anomaly.
SELECT
  pu_zone,
  do_zone,
  COUNT(*) AS cnt
FROM vw_tableau_tip_bid
WHERE improvement_surcharge = 0.00 AND pu_zone ILIKE '%outsi%'
GROUP BY pu_zone, do_zone
ORDER BY cnt DESC;

-- 15)vw_tableau_tip_bid:
--    Count how many trips remain after enforcing improvement_surcharge=1.00 to confirm the final cleaned population size.
SELECT
  COUNT(*) AS cnt
FROM vw_tableau_tip_bid
WHERE improvement_surcharge = 1.00 



