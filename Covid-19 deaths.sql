--creating a database

create database covid19

-- Select All  and order alphabetically by country

Select * from CovidDeaths$
order by 3 asc

--Total Cases overall by country using Aggregate function(sum).
--This included an anomally, location included continents as well which were removed by the where clause condition.

select continent,location, SUM(new_cases) as TotalCases from CovidDeaths$
where continent IS NOT NULL
group by location,continent
order by continent,location asc

--total cases in Pakistan

select continent, location, SUM(new_cases) as TotalCases from CovidDeaths$
where location like '%Pakistan%'
group by location,continent
order by 1

--Total deaths overall. New deaths column was in nvarchar therefore it needed to be typecasted into integer.

select continent, location, SUM(cast(new_deaths as int)) as Totaldeaths from CovidDeaths$
where continent IS NOT NULL
group by location,continent
order by SUM(cast(new_deaths as int))desc

--permanently altering the data type of total deaths and new deaths column

alter table CovidDeaths$ alter column [total_deaths] [int]
alter table CovidDeaths$ alter column [new_deaths] [int]

--Total deaths in Pakistan.

select continent,location, SUM(new_deaths) as Totaldeaths from CovidDeaths$
where location like '%Pakistan%'
group by location,continent
order by 1

--stringency index 

select location,sum(new_cases) as totalcases,avg(stringency_index) as stringencyindex from CovidDeaths$
where continent is NOT NULL AND new_cases is NOT NULL
group by location
order by sum(new_cases) desc

--Percentage of total cases against population to measure the impact of stringency 

select location,population,sum(new_cases) as totalcases,avg(stringency_index) as stringencyindex,Round((SUM(new_cases)/population)*100,2)as Percentage_by_population from CovidDeaths$
where continent is NOT NULL AND new_cases is NOT NULL
group by location,population
order by sum(new_cases) desc

--Number of deaths per total cases 

select location,population, sum(new_cases)as TotalCases,sum(new_deaths)as TotalDeaths,round(sum(new_deaths)/sum(new_cases)*100,2)as Death_percentage from CovidDeaths$
where continent is NOT NULL AND new_cases is NOT NULL
group by location,population
order by  (round(sum(new_deaths)/sum(new_cases)*100,2)) desc

-- Number of Cases by continent(we selected location because continents numbers weren't accurate).

select location,max(total_cases)as TotalCases from CovidDeaths$
where continent is NULL
group by location 
order by TotalCases desc

--total deaths per continent

select location,max(total_cases) as TotalCases, max(total_deaths) as TotalDeaths from CovidDeaths$
where continent is NULL
group by location 
order by TotalDeaths desc

--percentage of cases per population and percentage of death per cases

select location,Max(Population) as Population,max(total_cases) as TotalCases,(Round((MAX(total_cases)/max(population))*100,2)) as PercentageCases, max(total_deaths) as TotalDeaths,(Round((MAX(total_deaths)/max(total_cases))*100,2)) as DeathPercentage from CovidDeaths$
where continent is NULL AND population is NOT NULL
group by location 
order by DeathPercentage desc

-- Joining Deaths and Vaccinations table

select * from CovidDeaths$ as dea
join CovidVaccinations$ as vac 
on dea.location=vac.location

--we won't be needing to join both the files as the vaccination data is also included in the covid deaths table because i attached a different file by mistake initially.
--therefore we will continue to use only Covid Deaths table.

--converting positive rate to float type
alter table CovidDeaths$ alter column [positive_rate] [float]
alter table CovidDeaths$ alter column [new_tests] [float]


--positive rate of cases
select location,sum(new_tests)as totaltests,max(total_cases) as TotalCases,round(Avg(positive_rate),2) as Average_positive_rate from CovidDeaths$
where continent is NOT NULL 
group by location 
order by Average_positive_rate  desc

--regarding the above query we will be identifying when id the process of testing started as the numbers don't match.

select location, date,new_tests from CovidDeaths$
where new_tests is NOT NULL
order by location,date asc

select location, date,new_cases from CovidDeaths$
where new_cases is NOT NULL
order by location,date asc

select location,sum(new_tests)as totaltests,max(total_cases) as TotalCases,round(Avg(positive_rate),2) as Average_positive_rate from CovidDeaths$
where continent is NOT NULL And location = 'Albania' 
group by location 
order by Average_positive_rate  desc

--now we are going to be using common table expressions to identify the relationship between icu patients and smokers
WITH CTE_Smokers as 
(select location,date, hosp_patients,weekly_hosp_admissions,weekly_icu_admissions,female_smokers,male_smokers from CovidDeaths$
where continent IS NOT NULL
)
select location, AVG(weekly_icu_admissions) as AVGweeklyICUadmissions,avg(female_smokers)+avg(male_smokers) as total_smokers from CTE_Smokers
where weekly_icu_admissions is not null AND female_smokers is not null and male_smokers is not null
group by location
order by total_smokers desc

--Vaccinatons data
select continent, location, date,new_vaccinations,people_vaccinated,people_fully_vaccinated from CovidDeaths$

-- Average vaccinations per day with total people vaccinated and total people fully vaccinated
with cte_vaccinations as (select location, AVG(new_vaccinations) as Average_vacc_perday,MAX(people_vaccinated) as total_people_vaccinated, MAX(people_fully_vaccinated) as total_fully_vacc_people,Round(((MAX(people_fully_vaccinated)/MAX(people_vaccinated))*100),2) as percentage_fullyvaccinated  from CovidDeaths$
where continent is not null
group by location
having Round(((MAX(people_fully_vaccinated)/MAX(people_vaccinated))*100),2) > 50
)
select * from cte_vaccinations
order by total_people_vaccinated desc
