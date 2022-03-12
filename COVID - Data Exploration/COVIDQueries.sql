-- Select Data que l'on va utiliser

SELECT Location, date, total_cases, new_cases, total_deaths, population
  FROM CovidDeaths
  ORDER BY 1,2


-- Nous allons analyser le nombre total de cas par rapport au nombre total de décès
-- Pour cela, nous avons d'abord besoin de changer de type les colonnes de calcul 
ALTER TABLE CovidDeaths ALTER COLUMN total_cases float
ALTER TABLE CovidDeaths ALTER COLUMN total_deaths float

SELECT Location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100, 2, 1) as DeathPercentage
  FROM CovidDeaths
  WHERE continent is not null AND location NOT LIKE '%income%'
  ORDER BY 1,2

  -- Quel est le pourcentage de la population ayant contracté le virus ?
  SELECT location, date, total_cases, population, ROUND((total_cases/population)*100, 2, 1) as PercentPopulationInfected
  FROM CovidDeaths
  WHERE continent is not null AND location NOT LIKE '%income%'
  ORDER BY 1,2

  -- Quel pays a le taux d'infection le plus haut ?
  SELECT location, population, MAX(total_cases) as HighestInfectionCount, ROUND(MAX((total_cases/population))*100, 2, 1) as PercentPopulationInfected
  FROM CovidDeaths
  WHERE continent is not null AND location NOT LIKE '%income%'
  GROUP BY location, population
  ORDER BY PercentPopulationInfected DESC

  -- Quels sont les pays ayant subis le plus de décès ? 
  SELECT location, MAX(total_deaths) as TotalDeathsCount
  FROM CovidDeaths
  WHERE continent is not null AND location NOT LIKE '%income%'
  GROUP BY location
  ORDER BY TotalDeathsCount DESC

   -- Grouper par continent 
  SELECT location, MAX(total_deaths) as TotalDeathsCount
  FROM CovidDeaths
  WHERE continent is null AND location NOT LIKE '%income%'
  GROUP BY location
  ORDER BY TotalDeathsCount DESC

  SELECT continent, MAX(total_deaths) as TotalDeathsCount
  FROM CovidDeaths
  WHERE continent is not null 
  GROUP BY continent
  ORDER BY TotalDeathsCount DESC

  -- Nombre Globaux - Tout d'abord convertir les colonnes de calcul
  ALTER TABLE CovidDeaths ALTER COLUMN new_cases float
  ALTER TABLE CovidDeaths ALTER COLUMN new_deaths float

  -- On additionne les new cases et new deaths pour avoir de total_cases et total_deaths sous forme d'aggrégat
  -- totaux par jour
  SELECT date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, ROUND(SUM(new_deaths)/SUM(new_cases)*100, 2, 1) as DeathPercentage
  FROM CovidDeaths
  WHERE continent is not null
  GROUP BY date
  ORDER BY 1,2

   -- total global
  SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, ROUND(SUM(new_deaths)/SUM(new_cases)*100, 2, 1) as DeathPercentage
  FROM CovidDeaths
  WHERE continent is not null
  ORDER BY 1,2


  -- Jointure avec la partie Vaccination
  -- Total Population vs Vaccinations
  -- CTE
  With PopVsVac (Continent, Location, Date, Population, New_Vaccinations, CountPeopleVaccinatedOverTime)
  as
  (
  SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
  , SUM(CAST(cv.new_vaccinations as float)) OVER (Partition by cd.location ORDER BY cd.location, cd.date) as CountPeopleVaccinatedOverTime
  FROM CovidDeaths cd
  JOIN CovidVaccinations cv
	ON cd.location = cv.location
	AND cd.date = cv.date
  WHERE cd.continent is not null
  --ORDER BY 2,3
  )
  SELECT *, (CountPeopleVaccinatedOverTime/Population)*100
  FROM PopVsVac

  -- TEMP TABLE
  DROP TABLE IF EXISTS #PercentPopulationVaccinated
  CREATE TABLE #PercentPopulationVaccinated
  (
  Continent nvarchar(255), 
  Location nvarchar(255),
  Date datetime,
  Population numeric,
  New_vaccinations numeric,
  CountPeopleVaccinatedOverTime numeric
  )
  INSERT INTO #PercentPopulationVaccinated
  SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
  , SUM(CAST(cv.new_vaccinations as float)) OVER (Partition by cd.location ORDER BY cd.location, cd.date) as CountPeopleVaccinatedOverTime
  FROM CovidDeaths cd
  JOIN CovidVaccinations cv
	ON cd.location = cv.location
	AND cd.date = cv.date
  WHERE cd.continent is not null
  --ORDER BY 2,3

  SELECT *, (CountPeopleVaccinatedOverTime/Population)*100
  FROM #PercentPopulationVaccinated

  -- Creation de vues pour stocker les data dans un but de Data Visualisation
  CREATE VIEW PercentPopulationVaccinated as
  SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
  , SUM(CAST(cv.new_vaccinations as float)) OVER (Partition by cd.location ORDER BY cd.location, cd.date) as CountPeopleVaccinatedOverTime
  FROM CovidDeaths cd
  JOIN CovidVaccinations cv
	ON cd.location = cv.location
	AND cd.date = cv.date
  WHERE cd.continent is not null