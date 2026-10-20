-- 02_places_load_checks.sql
-- Quality checks on the CDC PLACES 2025 county table (Wisconsin) after loading it into BigQuery.

-- 1. Row count, duplicates, and state. Expect 72 | 72 | 0.
SELECT
  COUNT(*)                     AS n_rows,
  COUNT(DISTINCT CountyFIPS)   AS n_distinct_fips,
  COUNTIF(StateAbbr != 'WI')   AS non_wi_rows
FROM `casestudy1-507213-c5.WI_Co_Health.PLACES_WI_2025`;

-- 2. Columns that autodetect did NOT store as decimals.
--    Expect CountyFIPS, TotalPopulation and TotalPop18plus (INT64); the *_95CI columns (STRING); the name columns; Geolocation.
SELECT column_name, data_type
FROM `casestudy1-507213-c5.WI_Co_Health.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'PLACES_WI_2025'
  AND data_type != 'FLOAT64'
ORDER BY ordinal_position;

-- 3. Range check on the 13 age-adjusted measures used in the analysis.
--    Prevalence should fall between 0 and 100. Expect 0 | 0.
SELECT
  COUNTIF(LEAST(LPA_AdjPrev, OBESITY_AdjPrev, DIABETES_AdjPrev, DEPRESSION_AdjPrev, GHLTH_AdjPrev,
                LACKTRPT_AdjPrev, FOODINSECU_AdjPrev, HOUSINSECU_AdjPrev, CHECKUP_AdjPrev,
                ACCESS2_AdjPrev, LONELINESS_AdjPrev, EMOTIONSPT_AdjPrev, MOBILITY_AdjPrev) < 0
       OR GREATEST(LPA_AdjPrev, OBESITY_AdjPrev, DIABETES_AdjPrev, DEPRESSION_AdjPrev, GHLTH_AdjPrev,
                   LACKTRPT_AdjPrev, FOODINSECU_AdjPrev, HOUSINSECU_AdjPrev, CHECKUP_AdjPrev,
                   ACCESS2_AdjPrev, LONELINESS_AdjPrev, EMOTIONSPT_AdjPrev, MOBILITY_AdjPrev) > 100)
                                                   AS counties_out_of_range,
  COUNTIF(LPA_AdjPrev IS NULL OR OBESITY_AdjPrev IS NULL OR DIABETES_AdjPrev IS NULL
       OR DEPRESSION_AdjPrev IS NULL OR GHLTH_AdjPrev IS NULL OR LACKTRPT_AdjPrev IS NULL
       OR FOODINSECU_AdjPrev IS NULL OR HOUSINSECU_AdjPrev IS NULL OR CHECKUP_AdjPrev IS NULL
       OR ACCESS2_AdjPrev IS NULL OR LONELINESS_AdjPrev IS NULL OR EMOTIONSPT_AdjPrev IS NULL
       OR MOBILITY_AdjPrev IS NULL)                AS counties_with_missing
FROM `casestudy1-507213-c5.WI_Co_Health.PLACES_WI_2025`;
