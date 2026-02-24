-- DDL Data Definition Language: Create raw Staging Table

DROP TABLE IF EXISTS {PG_SCHEMA}.stg_yellow_trips;

CREATE TABLE {PG_SCHEMA}.stg_yellow_trips (
  vendorid                 SMALLINT,
  tpep_pickup_datetime     TIMESTAMP,
  tpep_dropoff_datetime    TIMESTAMP,
  passenger_count          SMALLINT,
  trip_distance            DOUBLE PRECISION,
  ratecodeid               SMALLINT,
  store_and_fwd_flag       TEXT,
  pulocationid             INTEGER,
  dolocationid             INTEGER,
  payment_type             SMALLINT,
  fare_amount              NUMERIC(10,2),
  extra                    NUMERIC(10,2),
  mta_tax                  NUMERIC(10,2),
  tip_amount               NUMERIC(10,2),
  tolls_amount             NUMERIC(10,2),
  improvement_surcharge    NUMERIC(10,2),
  total_amount             NUMERIC(10,2),
  congestion_surcharge     NUMERIC(10,2),
  airport_fee              NUMERIC(10,2),
  cbd_congestion_fee       NUMERIC(10,2),

  -- metadata for reproducibility
  source_file              TEXT NOT NULL,
  ingested_at              TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ix_stg_yellow_pickup_dt
  ON {PG_SCHEMA}.stg_yellow_trips (tpep_pickup_datetime);

CREATE INDEX IF NOT EXISTS ix_stg_yellow_pu_do
  ON {PG_SCHEMA}.stg_yellow_trips (pulocationid, dolocationid);

CREATE INDEX IF NOT EXISTS ix_stg_yellow_source_file
  ON {PG_SCHEMA}.stg_yellow_trips (source_file);

  /*
To populate the raw table with data, run the Python script located at:
ETL/Notebooks/03.1_load_yellow_2025_07-09_full

This notebook performs the full load for the specified period and inserts the
records into the raw/staging layer used by the downstream SQL views.
*/