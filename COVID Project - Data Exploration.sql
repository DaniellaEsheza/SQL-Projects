Covid 19 Data Exploration 
       
-- Selecting all data from the CovidDeaths table, filtering out rows where the continent is NULL
-- The results are ordered by the third and fourth columns (date and population)
SELECT * 
FROM coviddeaths
WHERE continent IS NOT NULL 
ORDER BY 3, 4;

-- Extracting specific columns to analyze Covid cases and deaths
-- Filters out rows where the continent is NULL and orders results by location and date
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1, 2;

-- Total Cases vs Total Deaths
-- This query calculates the likelihood of dying from Covid in each country
SELECT Location, date, total_cases, total_deaths, 
       (total_deaths / total_cases) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE location LIKE '%states%' -- Filters for locations that include "states"
  AND continent IS NOT NULL
ORDER BY 1, 2;

-- The same query as above but focuses only on Africa
SELECT Location, date, total_cases, total_deaths, 
       (total_deaths / total_cases) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE location = 'Africa'
  AND continent IS NOT NULL
ORDER BY 1, 2;

-- Total Cases vs Population
-- This query calculates the percentage of the population infected with Covid for each location
SELECT Location, date, Population, total_cases,  
       (total_cases / population) * 100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE location LIKE '%states%' 
ORDER BY 1, 2;

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From CovidDeaths
Where location like 'Africa'
order by 1,2;

-- Identifying countries with the highest infection rate compared to their population
SELECT Location, Population, 
       MAX(total_cases) AS HighestInfectionCount, 
       MAX((total_cases / population) * 100) AS PercentPopulationInfected
FROM CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;

-- Identifying countries with the highest death count per population
SELECT Location, 
       MAX(CAST(Total_deaths AS SIGNED)) AS TotalDeathCount
FROM CovidDeaths
WHERE Continent IS NOT NULL
  AND Total_deaths REGEXP '^[0-9]+$' -- Filters for rows where Total_deaths contains only numeric values
GROUP BY Location
ORDER BY TotalDeathCount DESC;


-- Breaking down death counts by continent
-- Shows continents with the highest death count per population
SELECT continent, 
       MAX(CAST(Total_deaths AS SIGNED)) AS TotalDeathCount
FROM CovidDeaths
WHERE Continent IS NOT NULL
  AND Total_deaths REGEXP '^[0-9]+$' 
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- Global Summary: Total cases, deaths, and death percentage
-- Aggregates data to show global totals and calculates the percentage of cases that resulted in death
SELECT 
    SUM(new_cases) AS total_cases, 
    SUM(CAST(new_deaths AS SIGNED)) AS total_deaths, 
    (SUM(CAST(new_deaths AS SIGNED)) / SUM(new_cases)) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL 
  AND new_deaths REGEXP '^[0-9]+$' 
  AND new_cases IS NOT NULL        
ORDER BY 1, 2;


-- Total Population vs Vaccinations
-- This query calculates the total vaccinations and the rolling sum of vaccinated individuals for each location
SELECT 
    dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS SIGNED)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN covidvaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY 1, 2, 3;


-- Using a Common Table Expression (CTE) to calculate rolling vaccinations and vaccination percentage
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) AS (
    SELECT 
        dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS SIGNED)) 
            OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    FROM CovidDeaths dea
    JOIN covidvaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL 
)
SELECT *, (RollingPeopleVaccinated / Population) * 100 AS VaccinationPercentage
FROM PopvsVac;

-- Using a Temporary Table to calculate rolling vaccinations and vaccination percentage
DROP TEMPORARY TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TEMPORARY TABLE PercentPopulationVaccinated (
    Continent VARCHAR(255),
    Location VARCHAR(255),
    Date DATETIME,
    Population DECIMAL(15, 2),
    New_vaccinations DECIMAL(15, 2),
    RollingPeopleVaccinated DECIMAL(15, 2)
);

INSERT INTO PercentPopulationVaccinated (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
SELECT 
    dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS SIGNED)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN covidvaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date;

SELECT *, 
       (RollingPeopleVaccinated / Population) * 100 AS VaccinationPercentage
FROM PercentPopulationVaccinated;

-- Creating View to store data for later visualizations

-- Creating a View to store the calculated data for visualization purposes
CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS SIGNED)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN covidvaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

-- Querying the view to retrieve all data
SELECT * 
FROM PercentPopulationVaccinated;
