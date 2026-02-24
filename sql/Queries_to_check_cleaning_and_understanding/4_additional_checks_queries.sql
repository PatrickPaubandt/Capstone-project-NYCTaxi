-- 1) Compare average tip rate by passenger_count to see whether group size correlates with tipping behavior (using tip_amount/total_amount).
SELECT
  passenger_count,
  COUNT(*) AS trip_count,
  ROUND(AVG(tip_amount / NULLIF(total_amount, 0))::numeric, 3) AS avg_tip_rate
FROM stg_yellow_trips
WHERE total_amount IS NOT NULL
  AND total_amount <> 0
  AND tip_amount IS NOT NULL
GROUP BY passenger_count
ORDER BY passenger_count;

-- 2) Add the median tip rate by passenger_count to reduce sensitivity to outliers and confirm whether the pattern holds beyond the mean.
SELECT
  passenger_count,
  COUNT(*) AS trip_count,
  ROUND(AVG(tip_amount / NULLIF(total_amount, 0))::numeric, 3) AS avg_tip_rate,
  ROUND(
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY (tip_amount / NULLIF(total_amount, 0)))::numeric,
    3
  ) AS median_tip_rate
FROM stg_yellow_trips
WHERE total_amount IS NOT NULL
  AND total_amount <> 0
  AND tip_amount IS NOT NULL
GROUP BY passenger_count
ORDER BY passenger_count;

-- 1) Get the total row count of the Tableau-facing BID-enriched view as a baseline for QA and later comparisons.
SELECT COUNT(*)
FROM vw_tableau_tip_bid;

-- 2) Count how many rows have missing BID enrichment on pickup vs dropoff (NULL pu_bid_count / do_bid_count) to assess join coverage.
SELECT
  COUNT(*) AS rows,
  SUM(CASE WHEN pu_bid_count IS NULL THEN 1 ELSE 0 END) AS pu_bid_nulls,
  SUM(CASE WHEN do_bid_count IS NULL THEN 1 ELSE 0 END) AS do_bid_nulls
FROM s_patrickpaubandt.vw_tableau_tip_bid;

-- 3) List the top pickup zones/LocationIDs with missing pu_bid_count to identify which taxi zones are not mapped in dim_zone_bid.
SELECT
  pulocationid,
  pu_zone,
  COUNT(*) AS trips
FROM s_patrickpaubandt.vw_tableau_tip_bid
WHERE pu_bid_count IS NULL
GROUP BY pulocationid, pu_zone
ORDER BY trips DESC
LIMIT 20;

-- 4) Verify whether missing BID fields are caused by NULL LocationIDs in trip data by counting NULL PU/DO location IDs.
SELECT
  SUM(CASE WHEN pulocationid IS NULL THEN 1 ELSE 0 END) AS pu_id_nulls,
  SUM(CASE WHEN dolocationid IS NULL THEN 1 ELSE 0 END) AS do_id_nulls
FROM s_patrickpaubandt.vw_tableau_tip_bid;

-- 5) Quick text lookup in dim_bid (e.g., Queens) to validate borough/name strings and confirm the BID source contains expected entries.
SELECT
  f_all_bi_1,
  f_all_bi_2
FROM dim_bid
WHERE f_all_bi_1 LIKE '%Queen%';

-- 6) Find taxi zones present in dim_taxi_zone but missing in dim_zone_bid to locate the exact unmapped LocationIDs causing NULL BID enrichment.
SELECT
  z.locationid,
  z.borough,
  z.zone
FROM s_patrickpaubandt.dim_taxi_zone z
LEFT JOIN s_patrickpaubandt.dim_zone_bid b
  ON b.locationid = z.locationid
WHERE b.locationid IS NULL
ORDER BY z.locationid;

-- 7) Insert default zero-BID rows for missing LocationIDs so every taxi zone has a dim_zone_bid record and joins stop producing NULLs.
INSERT INTO s_patrickpaubandt.dim_zone_bid
  (locationid, borough, zone, bid_count, has_bid, overlap_share, overlap_share_pct)
SELECT
  z.locationid,
  z.borough,
  z.zone,
  0 AS bid_count,
  0 AS has_bid,
  0::double precision AS overlap_share,
  0::double precision AS overlap_share_pct
FROM s_patrickpaubandt.dim_taxi_zone z
LEFT JOIN s_patrickpaubandt.dim_zone_bid b
  ON b.locationid = z.locationid
WHERE b.locationid IS NULL;

-- 8) Re-run the NULL-count QA after backfilling dim_zone_bid to confirm pickup/dropoff BID fields are now fully populated.
SELECT
  COUNT(*) AS rows,
  SUM(CASE WHEN pu_bid_count IS NULL THEN 1 ELSE 0 END) AS pu_bid_nulls,
  SUM(CASE WHEN do_bid_count IS NULL THEN 1 ELSE 0 END) AS do_bid_nulls
FROM s_patrickpaubandt.vw_tableau_tip_bid;