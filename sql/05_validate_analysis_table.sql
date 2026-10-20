-- 05_validate_analysis_table.sql
-- Checks run after building wi_county_analysis, before exporting it to Tableau.

-- 1. Expect 72 rows, 0 counties missing PLACES data.
SELECT
  COUNT(*)                                  AS n_counties,
  COUNTIF(pct_physical_inactivity IS NULL)  AS missing_places,
  COUNTIF(people_per_primary_care_physician IS NULL) AS missing_pcp_ratio,  -- expect 1
  COUNTIF(food_environment_index_0_10 IS NULL)       AS missing_food_env    -- expect 1
FROM `casestudy1-507213-c5.WI_Co_Health.wi_county_analysis`;

-- 2. Spot-check Dane County. Expect: 80.8 | 94.1 | 20.8 | 7.7 | Mostly urban | 4
SELECT county_name, life_expectancy_years, pct_access_exercise, pct_physical_inactivity,
       pct_children_in_poverty, rurality_group, income_quartile
FROM `casestudy1-507213-c5.WI_Co_Health.wi_county_analysis`
WHERE fips = '55025';
