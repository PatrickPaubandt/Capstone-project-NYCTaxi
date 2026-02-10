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