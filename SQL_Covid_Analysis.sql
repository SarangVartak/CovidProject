create database CovidProject;

--data for Covid

select * from CovidProject..CovidDeaths 
where continent is not null  --as when continent column has null values the location column has Continent names instead of Country names
order by 3,4                --as we want to order by location, date

select * from CovidProject..CovidVaccinations 
order by 3,4

select location, date, new_cases, total_cases, total_deaths, population
from CovidProject..CovidDeaths
order by 1,2                --as we want to order by location, date


--Percentage of total deaths with respect to total cases
--Daily likelihood of dying after contracting covid by country
select location, date, total_cases, total_deaths, (cast(total_deaths as decimal)/cast(total_cases as decimal))*100 as PercentageOfDeath   --if cast not used got error "nvarchar is invalid for divide operator"
from CovidProject..CovidDeaths   --if cast not used got error "nvarchar is invalid for divide operator"
where location like 'India'
order by 1,2


--Total Cases vs Population
--Percentage of population that got infected by Covid
select location, date, total_cases, Population, (cast(total_cases as decimal)/cast(population as decimal))*100 as PercentageOfInfected
from CovidProject..CovidDeaths
--where location like 'India'
order by 1,2


--Countries with highest Infection rate compared to there population   
select location, population, Max(cast(total_cases as decimal)) as HighestInfectionCount, Max(cast(total_cases as decimal)/cast(population as decimal))*100 as HighestPercentageOfInfected
from CovidProject..CovidDeaths
--where location like 'India'
group by location, population
order by HighestPercentageOfInfected desc


--Countries with highest Infection rate compared to there population per day    
select location, population, date, Max(cast(total_cases as decimal)) as HighestInfectionCount, Max(cast(total_cases as decimal)/cast(population as decimal))*100 as HighestPercentageOfInfected
from CovidProject..CovidDeaths
--where location like 'India'
group by location, population, date
order by HighestPercentageOfInfected desc


--Countries with highest death count compared to population

select location, Max(cast(total_deaths as int)) as HighestDeathCount
from CovidProject..CovidDeaths
--where location like 'India'
where continent is not null    --as when continent column has null values the location column has Continent names instead of Country names
group by location
order by HighestDeathCount desc


--If level of detail is by continent instead of country
select continent, Max(cast(total_deaths as int)) as HighestDeathCount
from CovidProject..CovidDeaths
--where location like 'India'
where continent is not null
group by continent
order by HighestDeathCount desc

--OR
select location, Max(cast(total_deaths as int)) as HighestDeathCount
from CovidProject..CovidDeaths
where continent is null
and location not in ('world', 'European Union', 'International', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
group by location
order by HighestDeathCount desc


--Total Global case numbers every day
select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as PercentageOfDeath
from CovidProject..CovidDeaths
--where location like 'India'
where continent is not null
group by date
order by 1,2

--Total Global Case number              
select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as PercentageOfDeath
from CovidProject..CovidDeaths
where continent is not null
--and location like 'India'
order by 1,2


--Total death count where location has continent names only        
select location, SUM(cast(new_deaths as int)) as TotalDeathCount
from CovidProject..CovidDeaths
where continent is null   --if we had given not null it would have displayed all the records where location is country names
and location not in ('world', 'European Union', 'International', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
group by location
order by TotalDeathCount desc

--Covid_Vaccinations
select * from CovidProject..CovidVaccinations 

--Join Covid_deaths & Covid_Vaccinations
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
from CovidProject..CovidDeaths cd
join CovidProject..CovidVaccinations cv
	on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null
order by 2,3




--Total Population vs Vaccination 
--finding total_vaccinations that were done till that day using new_vaccinations, date, location

select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM(cast(cv.new_vaccinations as bigint)) over (partition by cd.location order by cd.location, cd.date) as total_vaccinationsEveryDay
from CovidProject..CovidDeaths cd           --here we use bigint instead of int as the value is too big
join CovidProject..CovidVaccinations cv   
	on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null
order by 2,3


--using CTE (i.e Common Table Expression)
with popvsvac (continent, location, date, population, new_vaccinations, total_vaccinationsEveryDay)
as
(
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM(cast(cv.new_vaccinations as bigint)) over (partition by cd.location order by cd.location, cd.date) as total_vaccinationsEveryDay
from CovidProject..CovidDeaths cd      --here we use bigint instead of int as the value is too big
join CovidProject..CovidVaccinations cv
	on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null   --as when cd.continent column has null values the location column has Continent names instead of Country names
--order by 2,3
)
select *, (total_vaccinationsEveryDay/population)*100   --without using CTE we couldn't have added this formula to before code as it would give error
from popvsvac


--using subquery
select *, (total_vaccinationsEveryDay/population)*100  
from
(
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM(cast(cv.new_vaccinations as bigint)) over (partition by cd.location order by cd.location, cd.date) as total_vaccinationsEveryDay
from CovidProject..CovidDeaths cd      --here we use bigint instead of int as the value is too big
join CovidProject..CovidVaccinations cv
	on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null   --as when cd.continent column has null values the location column has Continent names instead of Country names
--order by 2,3
) as popvsvac


--temp table i.e temporary table
drop table if exists #PercentPopulationVaccinated  --to execute the below code again we need to drop the created table


create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
Total_vaccinationsEveryDay numeric
)
insert into #PercentPopulationVaccinated
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM(cast(cv.new_vaccinations as bigint)) over (partition by cd.location order by cd.location, cd.date) as total_vaccinationsEveryDay
from CovidProject..CovidDeaths cd      --here we use bigint instead of int as the value is too big
join CovidProject..CovidVaccinations cv
	on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null   --as when cd.continent column has null values the location column has Continent names instead of Country names
--order by 2,3

select *, (total_vaccinationsEveryDay/population)*100
from #PercentPopulationVaccinated


--creating view to store data for later visualizations. unlike temp table views are permanent
drop view if exists PercentPopulationVaccinated

create view PercentPopulationVaccinated as
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM(cast(cv.new_vaccinations as bigint)) over (partition by cd.location order by cd.location, cd.date) as total_vaccinationsEveryDay
from CovidProject..CovidDeaths cd
join CovidProject..CovidVaccinations cv
	on cd.location = cv.location
	and cd.date = cv.date
	where cd.continent is not null   --as when cd.continent column has null values the location column has Continent names instead of Country names
  --order by 2,3

select * from PercentPopulationVaccinated