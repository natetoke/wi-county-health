-- 06_findings.sql
-- Reproduces every number in the project's Key Findings.
-- Table: wi_county_analysis (72 rows, one per county), built in 04_build_analysis_table.sql.

-- 1. Correlations (Pearson r), with and without Menominee County, the most extreme outlier.
--    Expect -0.61 | -0.73 | -0.53 | -0.72.
SELECT
  ROUND(CORR(pct_access_exercise, pct_physical_inactivity), 2)     AS r_access_vs_inactivity,
  ROUND(CORR(median_household_income, pct_physical_inactivity), 2) AS r_income_vs_inactivity,
  ROUND(CORR(IF(county_name != 'Menominee County', pct_access_exercise, NULL),
             pct_physical_inactivity), 2)                          AS r_access_excl_menominee,
  ROUND(CORR(IF(county_name != 'Menominee County', median_household_income, NULL),
             pct_physical_inactivity), 2)                          AS r_income_excl_menominee
FROM `casestudy1-507213-c5.WI_Co_Health.wi_county_analysis`;

-- 2. Range of physical inactivity across counties. Expect 19.6 | 35.8.
SELECT
  MIN(pct_physical_inactivity) AS min_inactivity,
  MAX(pct_physical_inactivity) AS max_inactivity
FROM `casestudy1-507213-c5.WI_Co_Health.wi_county_analysis`;

-- 3. Medians by income quartile (1 = lowest income).
--    Expect quartile 1: 29.4 (rounds from 29.35) and 76.2; quartile 4: 24.7 and 79.4.
SELECT DISTINCT
  income_quartile,
  COUNT(*) OVER (PARTITION BY income_quartile)                                      AS n_counties,
  PERCENTILE_CONT(pct_physical_inactivity, 0.5) OVER (PARTITION BY income_quartile) AS median_inactivity,
  PERCENTILE_CONT(life_expectancy_years, 0.5)   OVER (PARTITION BY income_quartile) AS median_life_expectancy
FROM `casestudy1-507213-c5.WI_Co_Health.wi_county_analysis`
ORDER BY income_quartile;

-- 4. Median access to exercise opportunities by rurality group.
--    Expect Completely rural 64.1 | Mostly rural 62.9 | Mostly urban 85.6.
SELECT DISTINCT
  rurality_group,
  COUNT(*) OVER (PARTITION BY rurality_group)                                  AS n_counties,
  PERCENTILE_CONT(pct_access_exercise, 0.5) OVER (PARTITION BY rurality_group) AS median_access_exercise
FROM `casestudy1-507213-c5.WI_Co_Health.wi_county_analysis`
ORDER BY rurality_group;
