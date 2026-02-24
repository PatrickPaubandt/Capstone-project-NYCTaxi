# Daily work-logs

### 02.02.2025 Monday
* Start of the Capstone Project NYC Yellow Taxi Data, after another Capstone topic idea was rejected (Football Market vs. Model)
* Set up the project repo structure (env file + gitignore) and confirmed the Postgres connection basics
* Loaded the Taxi Zone lookup table (dim_taxi_zone) into your schema and verified it (265 rows)
* Created a first staging table for Yellow Taxi trips and tested the table schema + indexes
* Ran an initial 100k “smoke test” import from the September 2025 Parquet file to validate the end-to-end flow (download → read → insert)

### 03.02.2025 Tuesday
* Debugged import issues caused by notebook state / cell order (e.g., engine not defined, wrong schema variable names)
* Discovered the key problem: critical fields (PULocationID/DOLocationID, VendorID, RatecodeID) were ending up as NULL in staging due to an incorrect dataframe state being inserted.
* Fixed this by:
    * truncating staging table
    * rebuilding df 
    * adding stop-mechanism (stop if LocationIDs are mostly NULL)
    * Validating insert immediately (n, pu_nulls do_nulls)
* Rebuilt the clean view and verified that Geo joins worked (top pickup zones included JFK/LGA etc.)
* Started Tableau prototyping with the 100k sample and clarified that the sample is time-biased (first rows → mostly early-month days).

### 04.02.2025 Wednesday
* Improved the analytics design for Tableau:
    * discussed passenger_count reliability (usable with caution)
    * clarified tip rate denominator choices (fare-based vs pre-tip total-based)
    * created an “extras before tip” metric concept ((total_amount - tip_amount) - fare_amount) for testing the impact of fees on tipping
* Planned the Full Load workflow cleanly:
    * separate folders for test vs full load notebooks (Repo: Notebooks/etl/)
    * keep dim_taxi_zone
    * rebuild staging via DDL
    * full-month import + validations
    * final cleaned/feature view for Tableau
* Executed the full September 2025 load into stg_yellow_trips using batch inserts (200k) with progress logs
* Ran post-load validations:
    * 4,251,015 rows loaded
    * critical nulls all 0
    * reviewed date coverage and payment_type distribution
* Prepared the next step: rebuilding vw_yellow_clean_tip and vw_tableau_tip to include surcharge fields and pre-tip/extras features, then reconnecting Tableau to the updated view

### 05.02.2025 Thursday

* Identified and integrated an external context dataset to enrich zone-level analysis:

    * brainstormed additional datasets (e.g., income / tourism proxies) and decided to use NYC Business Improvement Districts (BIDs) as a “commercial activity” signal

* Pulled BID data from NYC Open Data (Socrata API):

    * resolved dataset ID confusion (ejxk-d93y vs 7jdm-inj8) by switching to the correct endpoint

    * implemented a full extract with paging and created:

        * bids_raw (JSONB snapshot for traceability)

        * dim_bid (flattened lookup-style table)

    * fixed Postgres load errors caused by nested MultiPolygon coordinate arrays by storing geometry fields as JSONB

* Built zone-level BID enrichment without PostGIS:

    * confirmed PostGIS not available and installed GeoPandas

    * loaded Taxi Zone polygons (shapefile) + BID polygons (GeoJSON) and aligned CRS (EPSG:2263)

    * created dim_zone_bid via spatial join:

        * added deduplication logic (ZoneID + BID key) to avoid double counting

        * calculated bid_count, has_bid, and overlap_share / overlap_share_pct (share of zone area covered by BIDs)

    * validated results (Top overlap zones were Manhattan-heavy: Battery Park, WTC, Midtown, Times Sq, etc.)

* Integrated BID features into the Tableau layer:

    * created vw_tableau_tip_bid by joining BID metrics onto vw_tableau_tip for both pickup and dropoff zones (pu_* and do_* fields)

    * investigated remaining NULLs in BID fields and found they were caused by missing LocationIDs in dim_zone_bid (e.g., 57, 104, 105, 264, 265)

    * completed dim_zone_bid for all dim_taxi_zone LocationIDs (defaulting missing zones to 0) and revalidated that PU/DO BID nulls = 0


### 06.02.2026 Friday
* Continued the BID enrichment work and stabilized the Tableau-facing layer:
    * created / updated `vw_tableau_tip_bid` by joining `dim_zone_bid` onto `vw_tableau_tip` for both pickup and dropoff zones (`pu_*` / `do_*` fields)
    * ran QA checks on BID joins (row count + NULL checks for PU/DO BID fields)
    * traced remaining NULLs to Taxi Zone IDs missing in `dim_zone_bid` (not to NULL LocationIDs in trip data)
    * compared `dim_taxi_zone` vs `dim_zone_bid` and inserted missing zone IDs (e.g., 57, 104, 105, 264, 265) with default 0 values
    * revalidated: `pu_bid_nulls = 0` and `do_bid_nulls = 0` across the full dataset

### 09.02.2025 Monday
* Day off

### 10.02.2026 Tuesday

* Reviewed and tightened data cleaning rules for surcharge fields used in the Tableau layer:

    * decided to drop trips where improvement_surcharge is not 1.00 (invalid values like 0.00 / 0.30)

    * decided to drop trips where mta_tax is not in (0.00, 0.50) (remove implausible outliers)

* Updated the Tableau-facing view definition accordingly:

    * removed redundant percent fields (tip_rate_fare_pct, tip_rate_pretip_pct) to avoid duplicated KPIs in Tableau

    * learned/handled the Postgres limitation that CREATE OR REPLACE VIEW cannot remove columns → used drop + recreate approach for the affected views

* Validated that the Tableau layer remains consistent after changes:

    * confirmed row counts and key fields behave as expected

    * ensured vw_tableau_tip_bid still joins BID enrichment correctly after the rebuild

    * updated documentation


### 11.02.2026 Wednesday

* Continued hypothesis preparation in Tableau and standardized an outlier-handling approach for tip-rate KPIs:

    * investigated unusually high Unknown/Other payment shares in certain pickup zones and validated the root cause in SQL:

        * confirmed that payment_type = 0 dominates in specific outer-borough zones (≈95–99%), meaning those records are Flex Fare trips (not missing/unknown payments)
        * decided to focus the tipping analysis on Card-only trips (payment_type = 1) to ensure tip recording is comparable and reliable

* implemented and validated an outlier strategy that avoids trip-level boxplots (performance constraints):

    * computed percentiles for tip_rate_fare on Card-only trips in PostgreSQL (p95 ≈ 0.4167, p99 ≈ 0.5389, max = 20000, n = 2,520,939)

    * created a Tableau parameter for the cap threshold (P99) and built a winsorized metric (tip_rate_fare_capped) to reduce extreme-value distortion without deleting trips

    * ran sanity checks in Tableau:
        * compared overall averages pre/post cap (avg raw ~26.7% vs capped ~25.1%)
        * checked borough-level differences and observed stronger distortion in small/special segments (e.g., EWR / Staten Island), reinforcing the need for caps and optional minimum-sample thresholds

* prepared the hypothesis testing workflow:

    * agreed to use capped tip-rate metrics as default in hypothesis charts

    * noted that additional guardrails (e.g., excluding NULL/Unknown boroughs or enforcing minimum trip counts per zone) may be applied to avoid misleading small-sample effects


### 12.02.2026 Thursday

Hypothesis Airport: 
We tested the Airport vs. Non-Airport tipping hypothesis in several steps. First, we compared overall average tip rates (card-only) and initially saw no clear advantage for airport trips. We then discovered that airport rides have a much higher average fare, meaning the raw averages mix different trip populations and can mask effects.

To control for this, we created price-level bins and compared airport vs. non-airport within the same bin: fare_amount bins for tip_rate_fare (capped) and pretip_total bins for tip_rate_pretip (capped) (switching from total_amount to pretip_total because it matches the metric definition). We also applied a minimum trip-count filter per bin using CNT(Pickup Date) to reduce small-sample noise. After binning and filtering, we observed that airport trips tend to have slightly higher tip rates in most comparable bins, especially in the low-to-mid price ranges, and the capped vs. uncapped lines were generally similar—suggesting the pattern is not driven by extreme outliers.

Airport hypothesis — what we did (English summary)

Initial check (overall averages, card-only):

We started by comparing overall average tip rates for airport vs non-airport trips.

At first glance, this suggested that airport trips do not meaningfully outperform non-airport trips on tip rate (the difference looked small / not clearly higher).

Why that result was misleading (fare structure / compositional effect):

We then checked the average fare level by segment and found that airport trips have a much higher average fare amount.

Because tip rate behavior changes with fare size (tip rates typically decline as fares increase), comparing raw averages mixes two structurally different populations and can hide real effects.

Controlled comparison using bins (fair comparison):

To control for this, we created fare-level bins and compared airport vs non-airport within the same fare context:

Fare Amount (bin) for Tip Rate Fare (Capped) (and uncapped as a sanity check)

Later, we improved the pretip analysis by using Pretip Total (bin) (instead of Total Amount) for Tip Rate Pretip (Capped), because tip_rate_pretip is defined relative to pre-tip cost.

We also applied a minimum trip-count threshold per bin using CNT(Pickup Date) to reduce noise and prevent small-sample spikes.

Key finding after controlling for fare level:

Once binned (and especially after applying a minimum count per bin), we observed that airport trips show higher tip rates in most comparable bins, particularly in the low-to-mid fare/pretip ranges.

The “capped” vs “uncapped” lines were very close most of the time, indicating that the pattern is not driven by extreme outliers, but reflects the typical behavior.

Bottom line:

The airport effect is not obvious in raw averages due to airport trips having much higher fares.

After controlling for fare/pretip levels via bins, the airport segment tends to tip slightly higher in comparable contexts.

### 12.02.2026 Friday

We extended the NYC Yellow Taxi pipeline from a single-month load (Sep 2025) to a multi-month load (Jul–Sep 2025) and redesigned the import to match the analysis scope. During ingestion, we enforced card-only trips (payment_type = 1), dropped unneeded columns (passenger_count, store_and_fwd_flag), and added data-quality filters (positive distance/fare/total-pretip, dropoff after pickup, non-negative tips). We then validated each month with row counts, date coverage, NULL checks, and payment sanity; discovered a few timestamp outliers (e.g., 2009 dates and pickups outside the target month), and removed them via SQL cleanup by keeping only pickups within each file’s month. Finally, we updated vw_yellow_clean_tip by removing the hardcoded month boundary, adding a max trip duration cap (≤ 6 hours), and applying agreed surcharge sanity filters (improvement_surcharge = 1.00 and mta_tax IN (0.00, 0.50)), so the clean view now supports consistent analysis across all imported months.

### 14.02.2026 Monday

On Monday (2026-02-16) the work focused on the Stress/Frustration hypothesis (H2) and on clarifying why tipping patterns are often dominated by trip size.

Stress/Frustration (H2)

* Defined a stress proxy using minutes per mile: duration_per_mile = Duration Min / Trip Distance
* Corrected the earlier “wrong direction” formula (distance/duration is speed, not duration-per-mile).
* Checked plausibility and applied practical analysis guards (e.g., only distance > 0, duration > 0, and trimming extreme tails such as duration_per_mile <= 30).
* Built Tableau views to test stress effects on:
    * Tip rate (%) (using capped tip-rate fields for robustness)
    * Tipping probability (is_tipped)
* Main takeaway: stress showed a clearer negative relationship with is_tipped than with tip%, which appeared comparatively flat once trip size was controlled.

Tipping mechanics follow-up (why trip size drives tip%)

* Built visuals to explain the “trip size dominates tip%” effect:
    * Tip Amount vs Pretip Total (avg + median)
    * Implied fixed-tip overlays ($2 / $3 / $5 expressed as % of pretip total)
    * Heatmap controlling for trip size × stress
* Found strong evidence that for small fares, tipping behavior is often discrete/default-driven (not purely proportional), with a pronounced $2 “default/minimum” pattern in the low-pretip range.

Set up the next step

* Decided the next hypothesis should test BID context (Business Improvement District exposure):
    * Start with Pickup BID (pu_* fields), then Dropoff BID (do_* fields if available).
    * Always control for trip size using Pretip Total Bucket (Stakeholder) or Pretip Total (bin).

Useful column names referenced

* Outcomes: tip_amount, is_tipped, tip_rate_pretip, tip_rate_pretip_capped
* Trip size: pretip_total, Pretip Total (bin), Pretip Total Bucket (Stakeholder)
* Stress: duration_min, trip_distance, duration_per_mile, duration_per_mile (bin)
* BID: pu_has_bid, pu_bid_count, pu_bid_overlap_share, pu_bid_overlap_share_pct (plus analogous do_* if present)
* Main Tableau view: vw_tableau_tip_bid

### 15.02.2025 Tuesday

* build a first story after analysing and testing the hypothesis
* presented the story to my teacher
* gettign feedback