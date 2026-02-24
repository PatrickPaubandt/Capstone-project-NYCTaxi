# NYC Yellow Taxi Tipping — Tableau Story (Final)

This document is the **final written version** of my Tableau Story for the NYC Yellow Taxi tipping capstone.  
Data scope is **card payments only**, **Jul–Sep 2025**, using **clean + capped tip rates**.

---

## Audience & goal
**Audience:** stakeholders with basic statistics knowledge  
**Goal:** explain *what drives tipping* using controlled, like-for-like comparisons (avoid misleading raw averages).

---

## Research question + red thread
**Research question:** *Is tipping driven more by trip context (size + friction) than by location alone?*

**Master hypothesis (red thread):**  
Tipping depends mainly on **trip context**:
- **Trip size** (pre-tip total / fare level)  
- **Friction / stress** (slow, stop-and-go trips)  
…and only *secondarily* on labels like airport or neighborhood context.

**Story logic (why this order matters):**
1) Establish **tipping mechanics** (trip size is the #1 confounder).  
2) Test **H2 Stress/Friction** while controlling for trip size.  
3) Test **H3 Airport**: overall vs controlled by trip size.  
4) Test **H4 BID exposure**: dose–response vs threshold, controlled by trip size.  
5) Close with **conclusions + actionability**.

---

## Data & scope (what’s in / what’s out)
- Unit of analysis: **one row = one trip**
- Payment scope: **card-only** (cash tips are not reliably recorded, so I exclude cash to reduce measurement bias)
- Time window: **Jul–Sep 2025**
- Source: Tableau-facing clean view (incl. engineered fields + BID enrichment)

---

## KPI definitions (use these names in Tableau)
To keep the story easy to understand, I use **two core outcomes**:

1) **Tip Probability**  
   - Tableau: `AVG(is_tipped)`  
   - Meaning: *likelihood that a passenger tips at all*

2) **Tip % (of pre-tip total, capped)**  
   - Tableau: `AVG(tip_rate_pretip_capped)`  
   - Meaning: *tip intensity*, robust to outliers using P99 cap

**Control variable (always used for hypothesis tests):**
- **Trip size bucket:** `pretip_total_bucket` (stakeholder-facing bins)

**Sample-size guardrail (stability):**
- Minimum counts per bin / cell (I use thresholds like **≥ 1,000** per bin; for heatmaps/panels I use higher thresholds when needed)

---

# Story Point 0 — Overview (baseline)
**Dashboard:** `00_Story_Intro_KPIs`

**Purpose:** quick baseline + preview of the confounder (trip size).

**What I show**
- KPI row: Tip Probability, Tip %, average pre-tip total, trip volume
- Trips by weekday (volume + tip metric stability)
- A simple spatial snapshot (dropoff map)
- A “how tipping changes with trip size” line (sets up the mechanics)

**1–2 sentences I say**
- “This overview gives the baseline: how often people tip, how much they tip relative to the pre-tip total, and how metrics vary by time, location, and trip size.”  
- “The rest of the story tests *why* tipping differs across contexts—while controlling for trip size.”

---

# Story Point 1 — Tipping mechanics (Trip size confounder)
**Dashboard:** `01_Tipping_Mechanics`

## Hypothesis (measurement insight)
**H0 (mechanics):** *Trip size dominates observed tip % patterns.*

## What I test
- How **Tip %** behaves over trip size
- Whether small trips show **step-like / minimum tip** behavior

## Key insight
**Small trips behave non-linearly**: tips cluster around a **~$2 default/minimum** for low pre-tip totals (≈ up to ~$12).  
This mechanically inflates **Tip %** on small trips.

**Implication:**  
✅ All later hypothesis tests must be interpreted **within `pretip_total_bucket`**, not only as overall averages.

## Recommended sheets (mechanics)
- `MECH_TipPctCapped_vs_PretipBin`
  - X: `pretip_total (bin)` (fine bins)
  - Y: `AVG(tip_rate_pretip_capped)`
  - Add a reference curve for “$2 fixed tip” (optional; great for explanation)
- `MECH_TipAmount_Distribution_LowPretip`
  - Filter: `pretip_total <= 12`
  - X: `tip_amount (bin)`
  - Y: `COUNT(trips)` (or share of trips)
  - Purpose: show the spike around **$2**

**Stakeholder takeaway (one line):**  
**Trip size is the #1 confounder—small trips show step-like tipping, so I control for trip size in every hypothesis test.**

---

# Story Point 2 — H2 Stress / Friction
**Dashboard:** `02_Stress_Effect`

## Hypothesis
**H2:** *More stressful rides (slower, stop-and-go) reduce tipping.*

## Stress proxy
- **Minutes per mile:**  
  `duration_per_mile = duration_min / trip_distance`  
- Higher = slower = more friction

## How I test (controlled)
- Compare tipping across `duration_per_mile (bin)` **within** `pretip_total_bucket`
- Use minimum sample-size thresholds per bin/cell

## Findings
- **Tip Probability decreases as rides get slower** (directionally consistent across fare buckets).
- **Tip % declines slightly overall**, but the clearer channel is **more zero-tip rides** under high friction.  
  Among trips where people *do* tip (i.e., `is_tipped = 1`), **Tip % is stable or slightly higher** → friction mainly affects **whether** people tip, not generosity conditional on tipping.

## Recommended sheets (stress)
1) **Small multiples (must-have)**
   - `STRESS_SmallMultiples_TipProb_by_DPMbin_and_PretipBucket`
   - Columns: `pretip_total_bucket`
   - X: `duration_per_mile (bin)`
   - Y: `AVG(is_tipped)`
   - Filter: min N per cell
2) **Companion (optional)**
   - `STRESS_TipPctCapped_by_DPMbin` (or small multiples version)
3) **Optional KPI summary**
   - `STRESS_KPI_Delta_TipProb_LowVsHighStress`  
   - Show Δ (percentage-point drop) between low-stress vs high-stress bins per trip-size bucket

**Stakeholder takeaway (one line):**  
**Traffic friction reliably reduces the *probability of tipping*—even within comparable trip sizes.**

---

# Story Point 3 — H3 Airport
**Dashboard:** `03_Airport_Context`

## Hypothesis
**H3:** *Airport trips tip more.*

## How I test
- Step 1: Compare **airport vs non-airport** overall
- Step 2: Repeat **within `pretip_total_bucket`** (control for trip size) + minimum sample thresholds

## Findings
- Overall averages can look **flat or even lower** for airport trips because **airport rides have much higher trip totals** (strong confounder).
- After controlling for trip size, the **airport uplift becomes visible**:  
  - Non-airport can lead in small-fare bins,  
  - Airports often lead in **mid/high** fare bins  
  → airport effect is **real but conditional**, not universal.

## Recommended sheets (airport)
1) `AIR_Overall_TipProb_Airport_vs_NonAirport`
   - Bars: airport flag
   - Y: `AVG(is_tipped)`
2) **Controlled (must-have)**
   - `AIR_TipProb_by_PretipBucket_AirportSplit`
   - X: `pretip_total_bucket`
   - Color: `is_airport_trip`
   - Y: `AVG(is_tipped)`
   - Filter: min N per bucket
3) Optional companion:
   - `AIR_TipPctCapped_by_PretipBucket_AirportSplit`

**Stakeholder takeaway (one line):**  
**Airport is not a blanket uplift—airport trips often tip more *after controlling for trip size*, especially in mid/high fare segments.**

---

# Story Point 4 — H4 BID exposure
**Dashboard:** `04_BID_Threshold`

## Hypothesis
**H4:** *Higher BID exposure at dropoff is associated with higher tipping.*

## BID metric (context / exposure)
- BID exposure is measured as **zone overlap with BID polygons (%)** (dropoff-focused is the primary signal).

## How I test
1) **Dose–response check:** does higher overlap steadily increase tipping?
2) If dose–response fails, test **threshold**: `0%` vs `>0%` exposure
3) Always control for `pretip_total_bucket` and enforce minimum N

## Findings
- **No clean dose–response:** higher BID overlap does **not** consistently increase tipping.
- Stronger pattern is **threshold**: main difference is **0% vs any exposure (>0%)**.
- **Dropoff** BID exposure is more consistently positive than pickup BID.
- Effect concentrates in **mid/high fare buckets** (from ~$30–50 upward).

### Stakeholder-facing lift numbers (Δ Tip Probability: Any vs None)
(percentage-point change by trip-size bucket)
- `<$10`: **-0.09 pp**
- `$10–20`: **+1.34 pp**
- `$20–30`: **+0.15 pp**
- `$30–50`: **+1.85 pp**
- `$50–75`: **+1.01 pp**
- `$75+`: **+1.19 pp**
- Average uplift (across buckets shown): **~+0.91 pp**

## Recommended sheets (BID)
1) **Dose–response heatmap (transparency / proof)**
   - `BID_01_Heatmap_DOBIDOverlapBins_by_PretipBucket`
   - Rows: `pretip_total_bucket`
   - Columns: `do_bid_overlap_bin` (0%, 1–25%, 25–50%, 50–75%, 75–100%)
   - Color: `AVG(is_tipped)` (or Tip % capped), labels include N
2) **Threshold test (core mechanism)**
   - `BID_02_Threshold_AnyVsNone_by_PretipBucket`
   - Columns: `DO BID Exposure (0 vs >0)`
   - Rows: `pretip_total_bucket`
   - Show: `AVG(is_tipped)` + `AVG(tip_rate_pretip_capped)` + N
3) **Executive summary (must-have)**
   - `BID_03_LiftVsNone_RefLine0`
   - Bar chart: `pretip_total_bucket` vs `Δ Tip Probability (Any - None)`
   - Add reference line at 0 and label with N

**Stakeholder takeaway (one line):**  
**BID exposure behaves like a threshold marker (none vs some), not a scalable “more BID → more tips” lever—especially for dropoffs and higher-value trips.**

---

# Story Point 5 — Conclusions & actionability
**Dashboard:** `05_Conclusions_Actionability`

## Final conclusions (stakeholder summary)
1) **Mechanics first:** small trips show step-like tipping (~$2), so **trip size is the key confounder**.  
2) **H2 supported:** higher minutes-per-mile (stress) → **lower Tip Probability**, robust within trip-size buckets.  
3) **H3 conditional:** airport uplift appears **after controlling for trip size**, strongest in mid/high segments.  
4) **H4 threshold:** BID overlap shows **0% vs >0%** separation; no reliable dose–response.

## Practical implications (what to do)
- **Guardrail:** always control for **trip size** when comparing tipping across contexts.
- **Reduce friction where possible:** stop-and-go conditions lower the likelihood of tipping.
- **Segment > blanket rules:** airport effects show up mainly in mid/high fare segments.
- **Use BID as a marker:** focus on **none vs some exposure**; don’t assume linear “more overlap → more tips”.

**Closing line (slide-ready):**  
**The best lever isn’t only *where* the trip happens—it’s *how the ride feels*, and which trip-size segment it belongs to.**
