## Project 1: Data Exploration using SQL. 

**Experience Level:** Intermediate

**SQL Skills used:** Creating Views, CTE's, Temp tables, Joins, Windows Functions, Aggregate Functions, Converting Data Types

**Technology used:** T-SQL (SQL Server Management System)

<!-- <img src="Images-/SQL-Pandemic-2.png"> -->

![alt text](https://github.com/Padlu/SQL-Portfolio-Projects/blob/main/Images-/SQL-Pandemic-2.png "Data Exploration of COVID PANDEMIC")


**Objective:**
* To explore the Covid Deaths and Covid Vaccinations Data using SQL
* To fool around the dataset to use SQL skills
*  Dataset is gathered from '[Our World in Data](https://ourworldindata.org/covid-deaths)'


**Summary: [`SQL code`](https://github.com/Padlu/SQL-Portfolio-Projects/blob/main/Portfolio%201%20(Data%20Exploration)/SQL_based_Data_Exploration.sql)**
1. In this project, I worked to query the given dataset to answer simple questions of which a few are:
    1. Likelihood of dying if you contract COVID in India
    2. What countries have the highest infection rate compared to population
    3. Comparison of death rates for countries: India, Ireland, United States and Norway
    4. What is Global Death % per day
    5. How many people in all locations have been vaccinated
    6. What is Rolling TotalVaccinations % per population (Windows Function, CTE/Temp table)
2. This simple project focused on above mentioned SQL skills to be used on the given dataset.
3. This project demonstrates advance queries like combination of PARTITION BY clause with [JOIN](https://github.com/Padlu/SQL-Portfolio-Projects/blob/f497e40848faab035b0661e457988cd4734f1c40/Portfolio%201%20(Data%20Exploration)/SQL_based_Data_Exploration.sql#L212), [CTE and Temp tables](https://github.com/Padlu/SQL-Portfolio-Projects/blob/f497e40848faab035b0661e457988cd4734f1c40/Portfolio%201%20(Data%20Exploration)/SQL_based_Data_Exploration.sql#L233) and to create [VIEWS](https://github.com/Padlu/SQL-Portfolio-Projects/blob/f497e40848faab035b0661e457988cd4734f1c40/Portfolio%201%20(Data%20Exploration)/SQL_based_Data_Exploration.sql#L290) for later use and queries with GROUP BY, WHERE, ORDER BY, and aggregation functions.
4. Required queried tables for Tableau Vizualisation are saved using views.



---

### Tableau Visualization:

</br>

[`VIZ Link`](https://public.tableau.com/views/TableauPortfolioProject1_16498755048070/Dashboard1?:language=en-US&:display_count=n&:origin=viz_share_link)

</br>

![alt text](https://github.com/Padlu/SQL-Portfolio-Projects/blob/main/Images-/Portfolio-1-Tab/COVID_Dash.png "Tableau Visualization")
