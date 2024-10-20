-- Shows all records in 'covid_deaths' table ordered by population 
-- smallest to largest
SELECT * 
FROM covid_deaths
ORDER BY population DESC; 

-----------------------------------------------------------------------

-- Shows all records in 'covid_deaths' table excluding null 
-- continent rows, so locations are exclusively countries

SELECT *
FROM covid_deaths
WHERE continent IS NOT NULL
ORDER BY population;

------------------------------------------------------------------------

-- Shows all records in 'covid_vacc' table excluding null 
-- continent rows

SELECT *
FROM covid_vacc
WHERE continent IS NOT NULL;

-------------------------------------------------------------------------

-- shows 'countries', 'dates', 'total_cases', 'total_deaths' and
-- percentage of people who contract covid and pass away

SELECT locations AS country, 
dates, 
total_cases, 
total_deaths,
ROUND((CAST(total_deaths AS numeric)/ CAST(total_cases AS
numeric))*100, 2) AS death_rate_percentage
FROM covid_deaths
WHERE total_cases > 0
AND continent IS NOT NULL
ORDER BY locations, dates, total_cases;

---------------------------------------------------------------------------

-- View created showing average monthly death rate as a percentage for United 
-- Kingdom throughout the pandemic 

DROP VIEW IF EXISTS UK_avg_monthly_death_rate;
CREATE VIEW UK_avg_monthly_death_rate AS
--Above query as CTE
WITH death_rate AS 
(
SELECT locations AS country, 
dates, 
total_cases, 
total_deaths,
ROUND((CAST(total_deaths AS numeric)/ CAST(total_cases AS
numeric))*100, 2) AS death_rate_percentage
FROM covid_deaths
WHERE total_cases > 0
AND continent IS NOT NULL
ORDER BY locations, dates, total_cases
)
SELECT CASE WHEN EXTRACT(year FROM dates) = '2020' 
THEN INITCAP(TRIM(to_char(dates, 'month'))) ||'_'|| '2020'
WHEN EXTRACT(year FROM dates) = '2021' 
THEN INITCAP(TRIM(to_char(dates, 'month'))) ||'_'|| '2021'
WHEN EXTRACT(year FROM dates) = '2022' 
THEN INITCAP(TRIM(to_char(dates, 'month'))) ||'_'|| '2022'
WHEN EXTRACT(year FROM dates) = '2023' 
THEN INITCAP(TRIM(to_char(dates, 'month'))) ||'_'|| '2023'
ELSE INITCAP(TRIM(to_char(dates, 'month'))) ||'_'|| '2024'
END AS month,
country, 
avg_monthly_death_rate_percentage
FROM (

-- Nested query showing the monthly average death rate for the UK

SELECT DATE_TRUNC('month', dates) AS dates,
country,
ROUND(AVG(death_rate_percentage),2) AS 
avg_monthly_death_rate_percentage
FROM death_rate 
WHERE country ILIKE 'united king%'
GROUP BY country, DATE_TRUNC('month', dates)
ORDER BY country, dates
) AS covid_twenty_one;

---------------------------------------------------------------------------

-- Shows all records from 'UK_avg_monthly_death_rate' view 

SELECT *
FROM UK_avg_monthly_death_rate;

----------------------------------------------------------------------------


-- Tempory table shows the proportion of the population who got infected for 
-- each country 

CREATE TEMP TABLE percentage_of_pop_infected AS 
SELECT DISTINCT locations,
MAX((total_cases::numeric/population::numeric)*100)
OVER(PARTITION BY locations) AS max_perc_pop_infected
FROM covid_deaths
ORDER BY locations;

SELECT *
FROM percentage_of_pop_infected;

------------------------------------------------------------------------------

-- View created showing the human development index and proportion of
-- population infected by the end of the pandemic for each country where 
-- the human development index is recorded

DROP VIEW IF EXISTS HDI_vs_prop_pop_infected;
CREATE VIEW HDI_vs_prop_pop_infected AS
SELECT p.locations AS country, 
ROUND(AVG(c.human_development_index),2) AS human_development_index,
ROUND(AVG(p.max_perc_pop_infected),2) AS max_perc_pop_infected
FROM percentage_of_pop_infected AS p
LEFT JOIN covid_vacc AS c
USING(locations)
WHERE human_development_index IS NOT NULL
GROUP BY p.locations
ORDER BY human_development_index;

----------------------------------------------------------------------------

SELECT * 
FROM HDI_vs_prop_pop_infected;

----------------------------------------------------------------------------
-- Pearsons correlation coefficient showing a strong positive relationship 
-- between the human development index and proportion of population 
-- infected by the end of the pandemic

SELECT CORR(human_development_index, max_perc_pop_infected) AS 
corr_hdi_vs_prop_pop_infected
FROM HDI_vs_prop_pop_infected;

--------------------------------------------------------------------------

-- Tempary table joining 'covid_deaths' and 'covid_vacc' tables

CREATE TEMP TABLE combined AS 
SELECT
d.locations,
d.dates,
d.population,
d.total_cases,
v.people_fully_vaccinated,
v.population_density
FROM covid_deaths AS d
INNER JOIN covid_vacc AS v
ON d.locations = v.locations
AND d.dates = v.dates
WHERE d.continent IS NOT NULL
ORDER BY d.locations;

------------------------------------------------------------------------

SELECT *
FROM combined;

------------------------------------------------------------------------
-- View created showing proportion of population infected by
-- the end of the pandemic and population density for each country

DROP VIEW IF EXISTS infvspopdens;
CREATE VIEW infvspopdens AS 

WITH pop_dens_inf AS
(
SELECT DISTINCT locations AS country,
MAX((total_cases::numeric/population::numeric)*100)
OVER(PARTITION BY locations) AS max_perc_pop_infected,
population_density
FROM combined
ORDER BY locations
)
SELECT 
country,
population_density,
ROUND(max_perc_pop_infected,2) AS max_perc_pop_infected
FROM pop_dens_inf
WHERE population_density IS NOT NULL
AND max_perc_pop_infected IS NOT NULL
ORDER BY population_density;

----------------------------------------------------------------

SELECT * 
FROM infvspopdens;

-----------------------------------------------------------------

-- Pearsons correlation coefficient showing no correlation between
-- population density and proportion of population infected by the
-- end of the pandemic

SELECT CORR(population_density, max_perc_pop_infected) AS 
corr_pop_dens_vs_prop_pop_infected
FROM infvspopdens;

