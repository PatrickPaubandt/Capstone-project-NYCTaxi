-- 99 percentil for tip_rate_pretip winsorizing
SELECT
  percentile_cont(0.01) WITHIN GROUP (ORDER BY tip_rate_pretip) AS p01_tip_rate_pretip,
  percentile_cont(0.99) WITHIN GROUP (ORDER BY tip_rate_pretip) AS p99_tip_rate_pretip,
  MAX(tip_rate_pretip) AS max_tip_rate_pretip,
  COUNT(*) AS n
FROM s_patrickpaubandt.vw_tableau_tip_bid
Where tip_rate_pretip IS NOT NULL;

--p01_tip_rate_pretip|p99_tip_rate_pretip|max_tip_rate_pretip 
-------------------+-------------------+--------------------
--                0.0| 0.3005464480874317|113.6363636363636364

-- 99 percentil for duration_min winsorizing
SELECT
  percentile_cont(0.95) WITHIN GROUP (ORDER BY duration_min) AS p95_duration_min,
  percentile_cont(0.99) WITHIN GROUP (ORDER BY duration_min) AS p99_duration_min,
  MAX(duration_min) AS max_duration_min,
  COUNT(*) AS n
FROM s_patrickpaubandt.vw_tableau_tip_bid
WHERE  duration_min IS NOT NULL;


--p95_duration_min |p99_duration_min |max_duration_min  |n      |
-----------------+-----------------+------------------+-------+
--43.86666666666667|71.36666666666666|359.18333333333334|6795596|

-- 99 percentil for trip_distance winsorizing

SELECT
  percentile_cont(0.01) WITHIN GROUP (ORDER BY trip_distance) AS p01_trip_distance,
  percentile_cont(0.99) WITHIN GROUP (ORDER BY trip_distance) AS p99_trip_distance,
  MAX(trip_distance) AS max_trip_distance,
  COUNT(*) AS n
FROM s_patrickpaubandt.vw_tableau_tip_bid
WHERE  trip_distance IS NOT NULL;

--p95_trip_distance|p99_trip_distance|max_trip_distance|n      |
-----------------+-----------------+-----------------+-------+
--             15.5|            20.97|         11931.78|6795596|


-- 99 percentil for total_amount winsorizing

SELECT
  percentile_cont(0.01) WITHIN GROUP (ORDER BY total_amount) AS p01_total_amount,
  percentile_cont(0.99) WITHIN GROUP (ORDER BY total_amount) AS p99_total_amount,
  MAX(total_amount) AS max_total_amount,
  COUNT(*) AS n
FROM s_patrickpaubandt.vw_tableau_tip_bid
WHERE  total_amount IS NOT NULL;

--p95_total_amount|p99_total_amount|max_total_amount|n      |
----------------+----------------+----------------+-------+
--            89.7|          116.63|         2403.01|6795596|