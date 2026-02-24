/*
Create new View: vw_tableau_tip + dim_zone_bid
----------------------------------------------
Expand the existing Tableau view to include additional attributes from the BID mapping table.
As a result, Tableau (and this new view) will also provide information about Business
Improvement Districts (BIDs).

Added fields:
- has_bid (0/1)
- bid_count: number of BIDs intersecting the taxi zone
- overlap_share (BID): percent of the taxi zone covered by the BID overlap

The data sourcing and construction of the BID-to-zone mapping can be reviewed in:
ETL/Notebooks/05_NY_Business_District_Data
*/


CREATE OR REPLACE VIEW {pg_schema}.vw_tableau_tip_bid AS
SELECT
    t.*,
    pu.bid_count          AS pu_bid_count,
    pu.has_bid            AS pu_has_bid,
    pu.overlap_share      AS pu_bid_overlap_share,
    pu.overlap_share_pct  AS pu_bid_overlap_share_pct,
    do_.bid_count         AS do_bid_count,
    do_.has_bid           AS do_has_bid,
    do_.overlap_share     AS do_bid_overlap_share,
    do_.overlap_share_pct AS do_bid_overlap_share_pct
FROM {pg_schema}.vw_tableau_tip t
LEFT JOIN {pg_schema}.dim_zone_bid pu
    ON pu.locationid = t.pulocationid
LEFT JOIN {pg_schema}.dim_zone_bid do_
    ON do_.locationid = t.dolocationid

