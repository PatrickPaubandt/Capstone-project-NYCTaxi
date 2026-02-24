# Technical Notes — NYC Yellow Taxi Tipping

This document describes the reproducible, SQL-first pipeline used to clean, enrich, and serve NYC Yellow Taxi trip data for analysis in Tableau.

## 1) Data & assumptions

### Source
- NYC TLC Yellow Taxi monthly trip files (Parquet)

### Window used in the capstone
- Jul–Sep 2025

### Payment-type caveat
Tip fields are **reliable for card payments**. Cash tips are often missing/underreported in TLC data.
Therefore, stakeholder-facing analyses typically use card-only filters in the Tableau-facing layer.

---

## 2) Database layers (PostgreSQL)

### A) Raw / staging
- Raw trip rows are loaded into a staging table (commonly named like `stg_yellow_trips`).
- Include ingestion metadata such as:
  - `source_file` (idempotency / auditing)
  - `ingested_at` (load timestamp)

### B) Clean analytical view (core)
Primary goal: filter implausible rows and create consistent derived features.

Common view name:
- `vw_yellow_clean_tip`

#### Cleaning rules (core filters)
Typical filters applied:
- `fare_amount > 0`
- `trip_distance > 0`
- `tip_amount >= 0`
- `tpep_dropoff_datetime > tpep_pickup_datetime`
- `improvement_surcharge = 1.00`
- `mta_tax IN (0.00, 0.50)`
- `(total_amount - tip_amount) > 0`  (pre-tip total must be valid)

> These rules are intentionally conservative to keep a stakeholder-safe dataset.

---

## 3) Feature engineering

### Time features
Derived from pickup time:
- `pickup_hour`
- `pickup_dow`
- `pickup_date`
- `pickup_month`

Trip duration:
- `duration_min` = minutes between pickup and dropoff

### Financial features
- `pretip_total = total_amount - tip_amount`
- `extras_pretip = pretip_total - fare_amount` (surcharges, tolls, etc., excluding tip)

### Tipping KPIs
- `is_tipped = (tip_amount > 0)`
- `tip_rate_fare = tip_amount / fare_amount`
- `tip_rate_pretip = tip_amount / pretip_total`

### Outlier handling (winsorization)
Tip-rate distributions have extreme tails, often driven by small denominators.
To keep analyses stable and readable:
- `tip_rate_pretip_capped` = tip_rate_pretip capped at **P99** (computed on card-only data)

---

## 4) Tableau-facing semantic layer

Goal: provide a stable “one-stop” view with:
- cleaned + engineered fields
- stakeholder-friendly buckets
- enrichment columns (BID / airport flags, etc.)

Common views:
- `vw_tableau_tip` (Tableau-optimized layer)
- `vw_tableau_tip_bid` (adds BID enrichment for pickup and dropoff context)

### Stakeholder bucketing (trip size)
Key guardrail:
Comparisons should be controlled for trip size using a bucket field such as:
- `pretip_total_bucket` (shown in Tableau as “Pretip Total Bucket (Stakeholder)”)
This avoids misleading averages caused by discrete “default tip” behavior on small rides.

---

## 5) BID enrichment (context)

### Why BID?
To test whether neighborhood “commercial context” is associated with tipping differences.

### Method (no PostGIS)
- BID geometries are collected from NYC Open Data.
- Spatial intersection is performed in Python (GeoPandas).
- Output dimension table:
  - `dim_zone_bid`

### Typical fields in `dim_zone_bid`
- `has_bid` (0/1)
- `bid_count` (how many BIDs overlap a Taxi Zone)
- `overlap_share` / `overlap_share_pct` (share of zone covered by BID polygons)

### Joining into Tableau
`vw_tableau_tip_bid` joins BID fields for both:
- pickup location context (`pu_*` BID fields)
- dropoff location context (`do_*` BID fields)

---

## 6) Hypothesis testing design (what “good” looks like)

### Core principle
**Control for trip size** first (use pre-tip buckets). Then compare contexts.

### H2 — Stress/Friction reduces tipping
- Stress proxy: `duration_per_mile = duration_min / trip_distance`
- Best readout: effect on `is_tipped` (probability of tipping)

### H3 — Airport trips tip more
- Airport comparisons must be done within size buckets because airport rides have higher fares.
- Within comparable bins, airport uplift is often visible in tip probability.

### H4 — BID exposure
- Expectation: not a clean linear dose–response.
- Best framing: **0% exposure vs >0% exposure** (threshold), especially for larger trips and dropoff context.

---

## 7) Repro checklist

1. Load raw TLC files into staging (`stg_yellow_trips`)
2. Create/refresh analytical view (`vw_yellow_clean_tip`)
3. Create/refresh Tableau layer (`vw_tableau_tip`)
4. Build BID enrichment (`dim_zone_bid`) in Python
5. Create/refresh enriched Tableau view (`vw_tableau_tip_bid`)
6. Connect Tableau to `vw_tableau_tip_bid`
7. Build story sheets following the narrative order:
   - Intro → tipping mechanics → H2 → H3 → (optional H4) → conclusions

---

## 8) Repo hygiene (final polish)
- Put final SQL (DDL + view definitions) into `sql/`
- Keep Python enrichment code in `python/` or `notebooks/`
- Export Tableau assets into `tableau/`
- Put handoffs / narrative summaries into `docs/`