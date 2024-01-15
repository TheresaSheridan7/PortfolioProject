-- Created PortfolioProject database in SQL Server.
-- Imported CovidDeaths.xlsx into CovidDeaths table.
-- Imported CovidVaccinations.xlsx into CovidVaccinations table.


SELECT top 10 *
FROM PortfolioProject..CovidDeaths -- OR PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
ORDER BY 3,4


SELECT top 10 *
FROM PortfolioProject..CovidVaccination
ORDER BY 3,4


-- Review Total Covid Cases vs Total Deaths
-- Shows likelihood of dying after contract Covid in your country
SELECT Location, date, total_cases, total_deaths, ((total_deaths/CAST (total_cases AS FLOAT)) * 100) as DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE Location like '%Australia%'
ORDER BY 1,2


-- Review Total Covid Cases vs Population
SELECT Location, date, Population, total_cases, ((CAST (total_cases AS FLOAT)/Population) * 100) as PercentagePopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
WHERE Location like '%Australia%'
ORDER BY 1,2


-- Review Countries with Highest Infection Rate compared to Population
SELECT Location, Population, MAX(total_cases) as HighestInfectionCount, Max ((CAST (total_cases AS FLOAT)/Population)) * 100 as PercentagePopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
--WHERE Location like '%Australia%'
Group by Location, Population
ORDER BY PercentagePopulationInfected desc


-- Display Countries with highest death count per population
SELECT Location, MAX(CAST (total_deaths AS INT)) as TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
--WHERE Location like '%Australia%'
WHERE continent is not null
Group by Location
ORDER BY TotalDeathCount desc


-- Break thigs down by continent
SELECT Location , MAX(CAST (total_deaths AS INT)) as TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
--WHERE Location like '%Australia%'
WHERE continent is null
Group by Location 
ORDER BY TotalDeathCount desc


-- Break thigs down by continent, country
SELECT continent, Location , MAX(CAST (total_deaths AS INT)) as TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
--WHERE Location like '%Australia%'
WHERE continent is not null
Group by continent, Location  
ORDER BY continent, Location  


--Showing continents with highest death count per population
SELECT continent, MAX(CAST (total_deaths AS INT)) as TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
Group by continent
ORDER BY TotalDeathCount desc


-- Global Numbers
SELECT date, SUM(CAST (new_cases AS INT) ) as total_cases, SUM(CAST (new_deaths AS INT)) as total_deaths, ( SUM(CAST(new_deaths AS INT)) / SUM(CAST(new_cases AS INT)) ) * 100 as DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
group by date
ORDER BY 1,2


SELECT SUM(CAST (new_cases AS INT) ) as total_cases, SUM(CAST (new_deaths AS INT)) as total_deaths, ( SUM(CAST(new_deaths AS INT)) / SUM(CAST(new_cases AS INT)) ) * 100  as DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
ORDER BY 1,2


SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(CAST (v.new_vaccinations AS bigint)) OVER (PARTITION by d.location ORDER BY d.location, d.date) as RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths as d
inner join PortfolioProject.dbo.CovidVaccinations as v on d.location = v.location
and d.date = v.date
WHERE d.continent is not null
and d.location like '%alba%'
ORDER BY 2,3


-- Use Common Table Expressions (CTE)
WITH PopvsVac (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(CAST (v.new_vaccinations AS bigint)) OVER (PARTITION BY d.location ORDER BY  d.location, d.date) as RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths as d
inner join PortfolioProject.dbo.CovidVaccinations as v 
	on d.location = v.location
	and d.date = v.date
WHERE d.continent is not null
and d.location like '%alba%'
--ORDER BY 2,3
)

SELECT * , (RollingPeopleVaccinated/Population) * 100 as RollingPeopleVaccinatedPercentage
FROM PopvsVac


-- Use TEMP TABLE
DROP TABLE IF EXISTS  #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
	Continent nvarchar(255),
	Location nvarchar(255), 
	Date datetime, 
	Population numeric, 
	New_vaccinations numeric, 
	RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated 
SELECT d.continent, d.location, d.date, d.population, CAST(v.new_vaccinations AS INT)
, SUM(CAST (v.new_vaccinations AS bigint)) OVER (PARTITION by d.location ORDER BY d.location, d.date) as RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths as d
inner join PortfolioProject.dbo.CovidVaccinations as v 
	on d.location = v.location
	and d.date = v.date
WHERE d.continent is not null
and d.location like '%alba%'
--ORDER BY 2,3

SELECT * , (RollingPeopleVaccinated/Population) * 100
FROM #PercentPopulationVaccinated 


--Creating a View to store data for visualisations at a later stage
CREATE VIEW PercentPopulationVaccinated AS
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations 
, SUM(CAST (v.new_vaccinations AS bigint)) OVER (PARTITION by d.location ORDER BY d.location, d.date) as RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths as d
inner join PortfolioProject.dbo.CovidVaccinations as v 
	on d.location = v.location
	and d.date = v.date
WHERE d.continent is not null

SELECT *
FROM PercentPopulationVaccinated
