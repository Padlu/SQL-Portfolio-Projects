
/*

SQL based Covid Deaths and Vaccinations Data Exploration Project

SQL Skills used: Creating Views, CTE's, Temp tables, Joins, Windows Functions, Aggregate Functions, Converting Data Types

*/



---------------------------------------------------------------------------------

-- Checking the 2 tables [Covid Deaths and Covid Vaccinations]

SELECT * 
FROM SQL_SSMS_Portfolio_1.dbo.CovidDeaths
order by 3,4

SELECT * 
FROM SQL_SSMS_Portfolio_1..CovidVaccinations
order by 3,4


--------------------------------------------------------------------------------- 

/* Working on COVID DEATHS TABLE */

-- (Based on TOTAL CASES) --



-- For all the countries what is the death rate for total infected population

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
FROM SQL_SSMS_Portfolio_1..CovidDeaths
order by 1,2,3



-- Likelihood of dying if you contract COVID in India (Checking the same for only country India)

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
FROM SQL_SSMS_Portfolio_1..CovidDeaths
WHERE location like '%ndia'
order by 1,2,3



-- What % of population got COVID in India (Total cases vs Population)

SELECT location, date, total_cases, population, (total_cases/population)*100 as Case_Percentage
FROM SQL_SSMS_Portfolio_1..CovidDeaths
WHERE location like '%ndia'
order by 1,2



-- What countries have the highest infection rate compared to population

SELECT location, population, MAX(total_cases) as Highest_Infection_count, MAX((total_cases/population))*100 as Percent_Population_infected
FROM SQL_SSMS_Portfolio_1..CovidDeaths
Group by location, population   -- As we used an aggregate function
order by Percent_Population_infected desc


--------------------------------------------------------------------------------- 
-- (Based on TOTAL DEATHS) --



-- What countries have the highest death rate compared to population

SELECT location, population, MAX(cast(total_deaths as int)) as Total_Death_count, MAX((cast(total_deaths as int)/population))*100 as Percent_Population_dead   -- Casting the variable into int for math since it is in nvarchar 
FROM SQL_SSMS_Portfolio_1..CovidDeaths
Where continent is not null   -- This removes the rows with continental data to give accurate only country wise data
Group by location, population
order by Percent_Population_dead desc



-- Same but comparing only for India, Ireland, United States and Norway

SELECT location, population, MAX(cast(total_deaths as int)) as Total_Death_count, MAX((cast(total_deaths as int)/population))*100 as Percent_Population_dead
FROM SQL_SSMS_Portfolio_1..CovidDeaths
Where (location like '%states%' OR location like '%ndia' OR location like 'irel%' OR location like '%rway') AND (continent is not null)
Group by location, population
order by Percent_Population_dead desc



-- Exploring death_counts by continent

SELECT location, MAX(cast(total_deaths as int)) as Total_Death_count
FROM SQL_SSMS_Portfolio_1..CovidDeaths
Where (continent is null) AND (location not like '%income%')
Group by location
order by Total_Death_count desc


--------------------------------------------------------------------------------- 

-- (ENTIRE WORLD) ---- (TOTAL CASES) --



-- Checking the data with Global numbers by removing location

SELECT date, total_cases, total_deaths
FROM SQL_SSMS_Portfolio_1..CovidDeaths
order by 1



/*

For same date there's multiple columns as the data is created by location.
Thus, here we explore it using aggregate function SUM()

*/



-- Using group by on date with aggregating functions.

SELECT date, SUM(total_cases) as TotalCases, SUM(cast(total_deaths as int)) as TotalDeaths
FROM SQL_SSMS_Portfolio_1..CovidDeaths
Where continent is not null
Group by date
order by 1

/*

The results are displayed such that every new date the total cases is sum of
new_cases on that day and total cases of previous day.

We double check that below by including new_cases just to be sure.

*/


SELECT date, SUM(total_cases) as TotalCases, SUM(new_cases) as NewCases, SUM(cast(total_deaths as int)) as TotalDeaths
FROM SQL_SSMS_Portfolio_1..CovidDeaths
Where continent is not null
Group by date
order by 1 -- It's correct!



-- (TOTAL DEATHS) --



-- What is Global Death % per day

SELECT date, SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, 
SUM(cast(new_deaths as int))/SUM(new_cases)*100 as GlobalDeathPercentage
FROM SQL_SSMS_Portfolio_1..CovidDeaths
Where continent is not null
Group by date
order by 1

/*   There's 0.34% chance for a person to die across the world for date March 23rd, 2022.   */



-- What is the global death percentage in this entire two year period.

SELECT SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, 
SUM(cast(new_deaths as int))/SUM(new_cases)*100 as GlobalDeathPercentage
FROM SQL_SSMS_Portfolio_1..CovidDeaths
Where continent is not null
order by 1 -- A little below 1.3%

--------------------------------------------------------------------------------- 

/* USING COVID VACCINATIONS TABLE WITH JOIN */


-- Let's jump back to jog our memory what's on the vaccinations table.

SELECT *
FROM SQL_SSMS_Portfolio_1..CovidVaccinations
order by 3,4



-- Okay, now let's join the two tables on date, and location

SELECT *
FROM SQL_SSMS_Portfolio_1..CovidDeaths cd
	JOIN SQL_SSMS_Portfolio_1..CovidVaccinations cv
	ON cd.date = cv.date AND cd.location = cv.location
--where cd.continent is not null
order by cd.date, cd.location



-- How many people in the world that have been vaccinated (Vaccinations vs population)

SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
FROM SQL_SSMS_Portfolio_1..CovidDeaths cd
JOIN SQL_SSMS_Portfolio_1..CovidVaccinations cv
	ON cd.location = cv.location 
		AND cd.date = cv.date
WHERE cd.continent is not null
order by 2,3


-- Windows function to have a rolling count on total vaccinations per day per country

SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
	SUM(CONVERT(int, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, 
	cd.date ROWS UNBOUNDED PRECEDING) as RollingTotalVaccinations -- Order by date as well to add the count per day wise and not entire location-- ROWS UNBOUNDED PRECEDING because of memory shortage due large data. 
FROM SQL_SSMS_Portfolio_1..CovidDeaths cd
JOIN SQL_SSMS_Portfolio_1..CovidVaccinations cv
	ON cd.location = cv.location 
		AND cd.date = cv.date
WHERE cd.continent is not null
order by 2,3


/* 

 With the newly created variable RollingTotalVaccinations
 we explore RollingTotalVaccinations % per population
 To perform calculation on Partition By query we use CTE or Temp Table below

*/



-- Common Table Expression (CTE) --



-- What is RollingTotalVaccinations % per population

With PopvsVac (Continent, Location, Date, Population, NewVaccinations, RollingTotalVaccinations)
as
(
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
	SUM(CONVERT(int, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, 
	cd.date ROWS UNBOUNDED PRECEDING) as RollingTotalVaccinations
FROM SQL_SSMS_Portfolio_1..CovidDeaths cd
JOIN SQL_SSMS_Portfolio_1..CovidVaccinations cv
	ON cd.location = cv.location 
		AND cd.date = cv.date
WHERE cd.continent is not null
)
SELECT *, (RollingTotalVaccinations/Population)*100 as RollingVacPercentage
FROM PopvsVac



-- TEMP table --



-- What is Max RollingTotalVaccinations % per population per location //Remove date

DROP TABLE IF EXISTS #PercentPopulationVaccinated   -- drop if exists. Comes handy
CREATE TABLE #PercentPopulationVaccinated 
(
Continent nvarchar(255), 
Location nvarchar(255), 
Population numeric, 
NewVaccinations numeric, 
RollingTotalVaccinations numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT cd.continent, cd.location, cd.population, cv.new_vaccinations, 
	SUM(CONVERT(bigint, cv.new_vaccinations)) OVER (PARTITION BY cd.location 
	ORDER BY cd.location ROWS UNBOUNDED PRECEDING) as RollingTotalVaccinations
FROM SQL_SSMS_Portfolio_1..CovidDeaths cd
JOIN SQL_SSMS_Portfolio_1..CovidVaccinations cv
	ON cd.location = cv.location 
		AND cd.date = cv.date
WHERE cd.continent is not null

SELECT Continent, Location, Population, MAX(NewVaccinations) as NewVac, MAX(RollingTotalVaccinations)
	as RollingTotalVac, (MAX(RollingTotalVaccinations)/Population)*100 as RollingVacPercentage
FROM #PercentPopulationVaccinated
Group by Continent, Location, Population


--------------------------------------------------------------------------------- 

-- Creating Views for later usage or visualizations --



-- View for Highest Infection rate per population

CREATE VIEW HighestInfectionRateperPop 
AS
SELECT location, population, MAX(total_cases) as Highest_Infection_count, MAX((total_cases/population))*100 as Percent_Population_infected
FROM SQL_SSMS_Portfolio_1..CovidDeaths
Group by location, population   -- As we used an aggregate function
order by Percent_Population_infected desc



-- View for Death counts per continent

CREATE VIEW DeathCountsperContinent
AS
SELECT location, MAX(cast(total_deaths as int)) as Total_Death_count
FROM SQL_SSMS_Portfolio_1..CovidDeaths
Where (continent is null) AND (location not like '%income%')
Group by location
order by Total_Death_count desc



-- View for Global Death % per day

CREATE VIEW GlobalDeathRateperDay 
AS
SELECT date, SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, 
SUM(cast(new_deaths as int))/SUM(new_cases)*100 as GlobalDeathPercentage
FROM SQL_SSMS_Portfolio_1..CovidDeaths
Where continent is not null
Group by date
order by 1



-- View for Rolling Population Vaccinations

CREATE VIEW RollingPeopleVaccinations 
AS
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
	SUM(CONVERT(int, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, 
	cd.date ROWS UNBOUNDED PRECEDING) as RollingTotalVaccinations
FROM SQL_SSMS_Portfolio_1..CovidDeaths cd
JOIN SQL_SSMS_Portfolio_1..CovidVaccinations cv
	ON cd.location = cv.location 
		AND cd.date = cv.date
WHERE cd.continent is not null

