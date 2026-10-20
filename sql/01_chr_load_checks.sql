-- 01_chr_load_checks.sql
-- Quality checks on the County Health Rankings 2025 table after loading it into BigQuery.
-- Source file: CHR 2025 Wisconsin county data, restructured from two header rows to one.
-- Note: schema autodetect stored the FIPS columns as integers, so the statewide row's
-- county_fips of 000 is stored as 0. The CASTs below work whether FIPS is a number or text.

-- 1. Row count. Expect 73 rows: 72 counties + 1 statewide row.
SELECT
  COUNT(*)                                  AS n_rows,
  COUNTIF(CAST(county_fips AS INT64) = 0)   AS statewide_rows
FROM `casestudy1-507213-c5.WI_Co_Health.CHR_2025`;

-- 2. Duplicate join keys. Expect zero rows returned.
SELECT fips, COUNT(*) AS n
FROM `casestudy1-507213-c5.WI_Co_Health.CHR_2025`
GROUP BY fips
HAVING n > 1;

-- 3. Valid Wisconsin county codes (55001 to 55141). Expect 0.
SELECT
  COUNTIF(CAST(fips AS INT64) NOT BETWEEN 55001 AND 55141) AS invalid_fips
FROM `casestudy1-507213-c5.WI_Co_Health.CHR_2025`
WHERE CAST(county_fips AS INT64) != 0;

-- 4. Spot-check one county against the County Health Rankings website.
--    Expect Dane County: adult_obesity 0.316 | physical_inactivity 0.177 |
--    median_household_income 84190 | population 575347.
SELECT county_name, adult_obesity, physical_inactivity, median_household_income, population
FROM `casestudy1-507213-c5.WI_Co_Health.CHR_2025`
WHERE CAST(fips AS STRING) = '55025';
