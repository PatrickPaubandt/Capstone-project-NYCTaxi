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

SELECT DISTINCT(f_all_bi_2)
FROM dim_bid

SELECT 
    improvement_surcharge, payment_group,
    COUNT(*) AS anzahl
FROM vw_tableau_tip_bid
GROUP BY improvement_surcharge, payment_group;


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


SELECT 
    mta_tax,
    COUNT(*) AS anzahl
FROM stg_yellow_trips
GROUP BY mta_tax;



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

SELECT
  y.PULocationID,
  y.pu_zone,
  COUNT(*) AS n
FROM vw_tableau_tip_bid y
WHERE y.airport_fee = 1.75
  AND y.pu_zone NOT IN ('JFK Airport', 'LaGuardia Airport')
GROUP BY y.PULocationID, y.pu_zone
ORDER BY n DESC;

SELECT
  COUNT(*) AS total_airport_fee_trips,
  SUM(CASE WHEN PULocationID IN (132,138) THEN 1 ELSE 0 END) AS pu_is_jfk_or_lga,
  SUM(CASE WHEN PULocationID NOT IN (132,138) THEN 1 ELSE 0 END) AS pu_not_jfk_or_lga,
  1.0 * SUM(CASE WHEN PULocationID NOT IN (132,138) THEN 1 ELSE 0 END) / COUNT(*) AS share_not_jfk_or_lga
FROM vw_tableau_tip_bid
WHERE airport_fee = 1.75;

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


SELECT
  VendorID,
  RatecodeID,
  payment_type,
  COUNT(*) AS n
FROM stg_yellow_trips
WHERE improvement_surcharge = 0.00
GROUP BY VendorID, RatecodeID, payment_type
ORDER BY n DESC;

SELECT tip_rate_fare
FROM vw_tableau_tip_bid
Where tip_rate_fare < 0;

SELECT
  ROUND( ((tip_rate_fare * 100) - tip_rate_fare_pct)::numeric, 1 ) AS test_tiprate_fare,
  *
FROM vw_tableau_tip_bid
WHERE tip_rate_fare < 0
  AND ROUND( ((tip_rate_fare * 100) - tip_rate_fare_pct)::numeric, 1 ) <> 0;

SELECT
  pu_zone,
  do_zone,
  COUNT(*) AS cnt
FROM vw_tableau_tip_bid
WHERE improvement_surcharge = 0.00 AND pu_zone ILIKE '%outsi%'
GROUP BY pu_zone, do_zone
ORDER BY cnt DESC;

SELECT
  COUNT(*) AS cnt
FROM vw_tableau_tip_bid
WHERE improvement_surcharge = 1.00 



