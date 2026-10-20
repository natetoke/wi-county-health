-- 03_join_checks.sql
-- Confirms the two sources will join cleanly before building the analysis table.
-- FIPS codes are converted to text in both tables so they share one join key.

-- 1. Anti-join in both directions: counties in one source but not the other.
--    Expect zero rows returned.
WITH chr AS (
  SELECT CAST(fips AS STRING) AS fips
  FROM `casestudy1-507213-c5.WI_Co_Health.CHR_2025`
  WHERE CAST(county_fips AS INT64) != 0          -- exclude the statewide row
),
places AS (
  SELECT CAST(CountyFIPS AS STRING) AS fips
  FROM `casestudy1-507213-c5.WI_Co_Health.PLACES_WI_2025`
)
SELECT
  chr.fips    AS fips_in_chr,
  places.fips AS fips_in_places
FROM chr
FULL OUTER JOIN places
  ON chr.fips = places.fips
WHERE chr.fips IS NULL OR places.fips IS NULL;

-- 2. Cross-check county population between sources.
--    Expect 72 | 0 (both sources use the same Census population estimates).
WITH chr AS (
  SELECT CAST(fips AS STRING) AS fips, CAST(population AS INT64) AS population
  FROM `casestudy1-507213-c5.WI_Co_Health.CHR_2025`
  WHERE CAST(county_fips AS INT64) != 0
),
places AS (
  SELECT
    CAST(CountyFIPS AS STRING) AS fips,
    TotalPopulation AS population
  FROM `casestudy1-507213-c5.WI_Co_Health.PLACES_WI_2025`
)
SELECT
  COUNT(*)                                    AS n_matched_counties,
  COUNTIF(chr.population != places.population) AS n_population_differs
FROM chr
JOIN places
  ON chr.fips = places.fips;
