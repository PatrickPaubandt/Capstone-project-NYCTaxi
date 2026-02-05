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
