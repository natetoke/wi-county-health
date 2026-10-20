-- 04_build_analysis_table.sql
-- Builds wi_county_analysis: one row per Wisconsin county (72), joining County Health
-- Rankings 2025 to CDC PLACES 2025 on 5-digit FIPS code. This table was exported to CSV
-- for the Tableau dashboard.
--
-- UNITS CONVENTION
--   * Every column starting with pct_ is a percentage on a 0-100 scale, rounded to 1 decimal
--     (CHR stores proportions such as 0.316, so those are multiplied by 100; PLACES is already 0-100).
--   * All PLACES measures use the age-adjusted estimate (_AdjPrev).
--   * Columns ending in _pp_vs_wi are differences from the Wisconsin statewide value, in percentage points.
--   * Non-percentage measures keep their original units, named in the column (years, per 100k, etc.).

CREATE OR REPLACE TABLE `casestudy1-507213-c5.WI_Co_Health.wi_county_analysis` AS

-- Both tables were loaded with schema autodetect, which stored FIPS codes as integers
-- (the statewide code 000 became 0). county_fips is compared as a number, and fips is
-- converted to text so both sources share the same join key.
WITH chr AS (                       -- CHR counties only
  SELECT * REPLACE (CAST(fips AS STRING) AS fips)
  FROM `casestudy1-507213-c5.WI_Co_Health.CHR_2025`
  WHERE CAST(county_fips AS INT64) != 0
),
wi AS (                             -- CHR statewide row, used for state comparisons
  SELECT *
  FROM `casestudy1-507213-c5.WI_Co_Health.CHR_2025`
  WHERE CAST(county_fips AS INT64) = 0
),
places AS (                         -- PLACES with FIPS as text so it matches CHR
  SELECT
    CAST(CountyFIPS AS STRING) AS fips,
    LPA_AdjPrev, OBESITY_AdjPrev, DIABETES_AdjPrev, DEPRESSION_AdjPrev, GHLTH_AdjPrev,
    LACKTRPT_AdjPrev, FOODINSECU_AdjPrev, HOUSINSECU_AdjPrev, CHECKUP_AdjPrev, ACCESS2_AdjPrev,
    LONELINESS_AdjPrev, EMOTIONSPT_AdjPrev, MOBILITY_AdjPrev
  FROM `casestudy1-507213-c5.WI_Co_Health.PLACES_WI_2025`
)

SELECT
  -- Identifiers
  c.fips,
  c.county_name,
  'Wisconsin' AS state,

  -- Population context
  CAST(c.population AS INT64)                                   AS population,
  ROUND(c.pct_rural * 100, 1)                                   AS pct_rural,
  CASE
    WHEN c.pct_rural = 1    THEN 'Completely rural'
    WHEN c.pct_rural >= 0.5 THEN 'Mostly rural'
    ELSE 'Mostly urban'
  END                                                           AS rurality_group,
  ROUND(c.pct_65_and_older * 100, 1)                            AS pct_65_and_older,
  ROUND(c.pct_disability_functional_limitations * 100, 1)       AS pct_disability,
  ROUND(p.MOBILITY_AdjPrev, 1)                                  AS pct_mobility_disability,

  -- 1. Headline outcomes
  ROUND(c.life_expectancy, 1)                                   AS life_expectancy_years,
  ROUND(c.life_expectancy - wi.life_expectancy, 1)              AS life_expectancy_years_vs_wi,
  RANK() OVER (ORDER BY c.life_expectancy DESC)                 AS life_expectancy_rank,   -- 1 = longest
  ROUND(c.premature_age_adjusted_mortality, 0)                  AS premature_deaths_per_100k,
  ROUND(p.GHLTH_AdjPrev, 1)                                     AS pct_fair_poor_health,
  ROUND(p.OBESITY_AdjPrev, 1)                                   AS pct_obesity,
  ROUND(p.DIABETES_AdjPrev, 1)                                  AS pct_diabetes,

  -- 2. Built environment for activity
  ROUND(c.access_to_exercise_opportunities * 100, 1)            AS pct_access_exercise,
  ROUND((c.access_to_exercise_opportunities
         - wi.access_to_exercise_opportunities) * 100, 1)       AS pct_access_exercise_pp_vs_wi,
  ROUND(c.access_to_parks * 100, 1)                             AS pct_access_parks,
  ROUND((c.access_to_parks - wi.access_to_parks) * 100, 1)      AS pct_access_parks_pp_vs_wi,
  ROUND(p.LPA_AdjPrev, 1)                                       AS pct_physical_inactivity,
  ROUND(c.food_environment_index, 1)                            AS food_environment_index_0_10,  -- higher = better
  ROUND(c.long_commute_driving_alone * 100, 1)                  AS pct_long_commute_alone,
  ROUND(p.LACKTRPT_AdjPrev, 1)                                  AS pct_lack_transportation,

  -- 3. Economic conditions
  CAST(c.median_household_income AS INT64)                      AS median_household_income,
  NTILE(4) OVER (ORDER BY c.median_household_income)            AS income_quartile,        -- 1 = lowest income
  ROUND(c.children_in_poverty * 100, 1)                         AS pct_children_in_poverty,
  ROUND((c.children_in_poverty - wi.children_in_poverty) * 100, 1)
                                                                AS pct_children_in_poverty_pp_vs_wi,
  ROUND(c.income_inequality, 2)                                 AS income_inequality_ratio,  -- 80th/20th percentile income
  ROUND(c.unemployment * 100, 1)                                AS pct_unemployed,
  ROUND(p.FOODINSECU_AdjPrev, 1)                                AS pct_food_insecure,
  ROUND(p.HOUSINSECU_AdjPrev, 1)                                AS pct_housing_insecure,

  -- 4. Access to care
  ROUND(c.uninsured * 100, 1)                                   AS pct_uninsured_under65,
  ROUND(p.ACCESS2_AdjPrev, 1)                                   AS pct_uninsured_adults_18_64,
  ROUND(c.ratio_of_population_to_primary_care_physicians, 0)    AS people_per_primary_care_physician,  -- higher = worse
  ROUND(c.ratio_of_population_to_mental_health_providers, 0)    AS people_per_mental_health_provider,  -- higher = worse
  ROUND(c.preventable_hospital_stays, 0)                        AS preventable_stays_per_100k_medicare,
  ROUND(p.CHECKUP_AdjPrev, 1)                                   AS pct_routine_checkup,

  -- 5. Social connection and mental health
  ROUND(p.LONELINESS_AdjPrev, 1)                                AS pct_loneliness,
  ROUND(p.EMOTIONSPT_AdjPrev, 1)                                AS pct_lack_social_support,
  ROUND(c.social_associations, 1)                               AS social_associations_per_10k,
  ROUND(c.frequent_mental_distress * 100, 1)                    AS pct_frequent_mental_distress,
  ROUND(p.DEPRESSION_AdjPrev, 1)                                AS pct_depression

FROM chr AS c
CROSS JOIN wi
LEFT JOIN places AS p
  ON c.fips = p.fips;
