# NYC Yellow Taxi Tipping — What Drives Tips?

This capstone analyzes NYC TLC **Yellow Taxi trip records** to understand **what drives tipping** — and shows that tipping is mostly explained by **trip context** (trip size + friction), not simply by location.

The workflow is **SQL-first in PostgreSQL**, with results presented as a stakeholder-friendly **Tableau Story** using controlled comparisons (trip-size buckets) to avoid misleading averages.

## Research question
**NYC Yellow Taxi Trips - Is tipping driven more by trip context (size + friction) than by location alone?**

## Scope
- Data: NYC TLC Yellow Taxi monthly files (Parquet)
- Window: **Jul–Sep 2025**
- Unit: 1 row = 1 trip (6,8 Million Rows in Analysis Dataset)
- Output: Tableau Story (hypothesis tests + conclusions)

## Core metrics
- **Tip probability:** `is_tipped = (tip_amount > 0)`
- **Tip % of fare(pre-tip total):** `tip_rate_pretip = tip_amount / pretip_total`
- **Tip % of fare (winsorizing,capped Outlier):** `tip_rate_pretip_capped` (P99 capping)

> Focus on **card payments** for reliable tip capture (cash tips are often missing in TLC trip data). See Picture: \docs\Picture\Distribution_PaymentTypes_Tiprate.png

## Key findings (high level)
- **Tipping mechanics:** small trips show “default” discrete tips (often ~$2), making % metrics unstable at the low end → comparisons must be done **within trip-size buckets**.
- **H2 (Friction/Stress):** higher minutes-per-mile reduces **whether** people tip (tip probability) more than it changes generosity conditional on tipping.
- **H3 (Airport):** airport uplift is **segment-dependent**; within comparable trip-size buckets, airport trips often show higher tip probability.
- **H4 (BID exposure):** no clean dose–response; strongest pattern is **0% exposure vs >0% exposure** (threshold), especially on larger trips.

## Repo structure (/notebooks)
- `python/` — get and extract Data (NYC Trips, Taxi Zones, BID Enrichment)
- `sql/` — view definitions + core transformations
- `tableau/` — workbook exports / story assets

## Repo structure (/docs)
- `DataDictionaries/` — Information
about Datafields, created columns (SQL), Calculated Fields(Tableau)
- `Presentation_TableauStory/` — Presentation and Tableaustory PDF
- `Pictures/` — some basic analyses which are not in the Tableau Story


## Notes
For full pipeline details, cleaning rules, view layer, and BID enrichment specifics see:
- `docs/1_readme_technical_notes.md`
Documentation of the analysis insights and presentation process:
- `docs/1_readme_technical_notes.md`