/*=========================================
MSBI.Dev.S19E02.Script.01.sql
=========================================*/

--predicate
SELECT [empid]
      ,[lastname]
      ,[region]
  FROM [TSQL2012].[HR].[Employees]
  WHERE [region]=N'WA'
--Null
SELECT [empid]
      ,[lastname]
      ,[region]
  FROM [TSQL2012].[HR].[Employees]
  WHERE [region]<>'WA'  OR [region] Is NUll


--Using T-SQL in a Relational Way

USE TSQL2012;
SELECT country
FROM HR.Employees;


--remove duplicates
SELECT DISTINCT country
FROM HR.Employees;


-- order in sets
-- result is relational
SELECT empid, lastname
FROM HR.Employees;

-- let's make it ordered
--the result isnt relational
SELECT empid, lastname
FROM HR.Employees
ORDER BY empid;


-- wrong way to sort

SELECT empid, lastname
FROM HR.Employees
ORDER BY 1;


--wrong way
SELECT empid, firstname + ' ' + lastname
FROM HR.Employees;

--right way
SELECT empid, firstname + ' ' + lastname AS fullname
FROM HR.Employees;


--right way
SELECT empid, firstname + ' ' + lastname AS fullname
FROM HR.Employees;

-- declarative

SELECT shipperid, phone, companyname
FROM Sales.Shippers;



/*==============================================================================
Logical Query Processing Phases

================================================================================*/

SELECT	country,
           YEAR(hiredate) AS yearhired,
           COUNT(*) AS numemployees
FROM HR.Employees
     WHERE hiredate >= '20030101'
     GROUP BY country, YEAR(hiredate)
     HAVING COUNT(*) > 1
     ORDER BY country , yearhired DESC;


	--1 . Evaluate the FROM Clause


	--typical mistake
SELECT country, YEAR(hiredate) AS yearhired
FROM HR.Employees
WHERE yearhired >= 2003;
--should use YEAR(hiredate) >= 2003 better hiredate >= '20030101'


--Note that an alias created by the SELECT phase isnt even visible to other expressions that
--appear in the same SELECT list. For example, the following query isnt valid.
--!!!!!!!  TODO Meaning?????
SELECT empid, country, YEAR(hiredate) AS yearhired, YEAR(hiredate) - 1 AS prevyear
FROM HR.Employees;



/*===========================================================================
Using the FROM and SELECT Clauses
============================================================================*/

-- alias for table
SELECT E.empid, firstname AS fn, lastname
FROM HR.Employees AS E;

--alias for column
-- bug
SELECT empid, firstname lastname
FROM HR.Employees;

-- right way 
SELECT empid, firstname AS lastname
FROM HR.Employees;

SELECT empid,  lastname = firstname
FROM HR.Employees;

--redefime attribute name
SELECT empid AS employeeid, firstname, lastname
FROM HR.Employees;


-- non relational
SELECT empid, firstname + N' ' + lastname
FROM HR.Employees;


-- difference between T-SQL and SQL
SELECT 10 AS col1, 'ABC' AS col2;



--=========================================================================
-- Data Types
--=========================================================================
DECLARE @f AS FLOAT = '29545428.022495';
SELECT CAST(@f AS NUMERIC(28, 14)) AS value;
