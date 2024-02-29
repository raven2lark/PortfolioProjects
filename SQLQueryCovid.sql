/*
Covid 19 Data Exploration 
Skills used: Joins, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- DBS created. View Data
SELECT *
FROM PortfolioProject..CovidDeaths
order by 3,4

SELECT *
FROM PortfolioProject..CovidVaccinations
order by 3,4

-- I altered table to adopt appropriate data types for fields. This i did to avoid continously type casting

ALTER TABLE PortfolioProject..CovidDeaths 
ALTER COLUMN total_cases float;

ALTER TABLE PortfolioProject..CovidDeaths 
ALTER COLUMN total_deaths float;

-- Decide the data you want to use from the table, I will be working with the dataset for Ghana
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE location = 'Ghana'
ORDER BY 1,2

--To calculate Total Cases Vs Total Deaths
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'Ghana'
Order By 1,2

--To look at the Total Cases Vs Population
SELECT location, date, total_cases, population, (total_cases/population)*100 infectionPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'Ghana'
Order By 1,2

-- Analysing Global Data
--Compare Infection Rate per population 
SELECT location, population, MAX(total_cases) InfectionRate, MAX((total_cases/population))*100 PopulationPercentage
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
Order By PopulationPercentage DESC

-- Look at Death Count per population
SELECT location, population, MAX(total_deaths) DeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location, population
Order By DeathCount DESC

-- LETS BREAK DOWN DATA BY CONTINENT
-- Showing Continents with Most Death Counts Per Population
SELECT continent, MAX(total_deaths) DeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
Order By DeathCount DESC

-- Looking at daily total of new cases and new deaths across the world
SELECT date, SUM(new_cases) TotalCases, SUM(new_deaths) TotalDeaths
FROM PortfolioProject..CovidDeaths
WHERE continent is null
GROUP BY date
Order By TotalDeaths DESC 

-- Death Percentages per day looking at total new cases and total new deaths
SELECT date, SUM(new_cases) TotalCases, SUM(new_deaths) TotalDeaths, SUM(new_deaths)/Sum(new_cases)*100 DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is null
GROUP BY date
Order By TotalDeaths DESC

-- To get total cases, deaths and percentage globally
SELECT SUM(new_cases) TotalCases, SUM(new_deaths) TotalDeaths, SUM(new_deaths)/Sum(new_cases)*100 DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is null
Order By TotalDeaths DESC

-- Looking at New Cases against Death Rate per location and the death percentages
SELECT location, SUM(new_cases) TotalCases, SUM(new_deaths) TotalDeaths, SUM(new_deaths)/Sum(new_cases)*100 DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY 4 desc

-- We ll be joining 2 tables, vaccination and infection/death toll data to work on our next insights
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject..Coviddeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

-- To look at Total Vaccinations in relation to population for each location
SELECT dea.location, dea.population, SUM(cast(total_vaccinations as float)) TotalVac
FROM PortfolioProject..Coviddeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
Group By dea.location, dea.population
ORDER BY TotalVac DESC

-- To do a rolling count, we ll use a partition clause to produce a column that gives total vaccinations as new vaccinations are given daily 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (partition by dea.location Order by dea.location, dea.date) RollingPeopleVaccinated
FROM PortfolioProject..Coviddeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

-- To use the max number of rolling people vaccinated to figure out how many people in the country that are vaccinated
-- we ll divide by population and multiply by hundred but we do this using a CTE or a temp table

Drop Table If Exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population,vac. new_vaccinations
, SUM(new_vaccinations) OVER (Partition By dea.location Order By dea.location, dea.date) RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null

Select *, (RollingPeopleVaccinated/population)*100
From #PercentPopulationVaccinated

-- To create Views to store data for later visualizations
Create View TotalDeathCount as
SELECT continent, MAX(total_deaths) DeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
Order By DeathCount DESC

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population,vac. new_vaccinations
, SUM(new_vaccinations) OVER (Partition By dea.location Order By dea.location, dea.date) RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null

