/*=========================================
MSBI.Dev.S20E02.Script.01.sql
=========================================*/

USE [TSQL2012];
GO

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

SELECT country
FROM HR.Employees;


--remove duplicates
SELECT DISTINCT country
FROM HR.Employees;


-- order in sets
-- result is relational
SELECT
	empid,
	lastname
FROM HR.Employees;

-- let's make it ordered
--the result isnt relational
SELECT
	empid,
	lastname
FROM HR.Employees
ORDER BY empid;

-- wrong way to sort
SELECT
	empid,
	lastname
FROM HR.Employees
ORDER BY 1;


--Aliases

--wrong way
SELECT
	empid,
	firstname + ' ' + lastname
FROM HR.Employees;

--wrong way
SELECT
	empid,
	firstname + ' ' + lastname fullname
FROM HR.Employees;

--right way
SELECT
	empid,
	firstname + ' ' + lastname AS fullname
FROM HR.Employees;

--right way
SELECT
	empid,
	fullname =	firstname + ' ' + lastname
FROM HR.Employees;




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
     ORDER BY COUNT(*) DESC;


	--1 . Evaluate the FROM Clause


	--typical mistake
SELECT
	country,
	YEAR(hiredate) AS yearhired
FROM HR.Employees
WHERE yearhired >= 2003;


--NON SARGABLE BUT WORKS
SELECT
	country,
	YEAR(hiredate) AS yearhired
FROM HR.Employees
WHERE YEAR(hiredate) >= 2003;
--should use YEAR(hiredate) >= 2003 better hiredate >= '20030101'


--Note that an alias created by the SELECT phase isnt even visible to other expressions that
--appear in the same SELECT list. For example, the following query isnt valid.
SELECT
	empid,
	YEAR(hiredate) AS yearhired,
	yearhired - 1 AS prevyear
FROM HR.Employees;

--Correct
SELECT
	empid,
	YEAR(hiredate) AS yearhired,
	YEAR(hiredate) - 1 AS prevyear
FROM HR.Employees;

--The only option
SELECT
	country,
	YEAR(hiredate) AS yearhired
FROM HR.Employees
ORDER BY yearhired

/*===========================================================================
Using the FROM and SELECT Clauses
============================================================================*/

-- alias for table
SELECT
    E.empid,
    E.firstname AS fn,
    E.lastname
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

--redefine attribute name
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

-- Does it works?
DECLARE @X INT = '1';
SELECT @X;


DECLARE @Y INT = 'AAA';
SELECT @Y;


DECLARE @S1 VARCHAR(1) = 1;
SELECT @S1;


DECLARE @S2 VARCHAR(1) = 1111;
SELECT @S2;


DECLARE @S3 VARCHAR(2) = 'AAA';
SELECT @S3;


--DON'T EVER DO IT!!!
SELECT
	empid,
	lastname
FROM HR.Employees
WHERE empid = '1';


--Simple arithmetic
SELECT 1 / 2;


--Solution
SELECT 1.0 / 2;


--What's now?
SELECT 1 / 2 + 0.5;


--Replicate and len functions
DECLARE @V VARCHAR(MAX) = REPLICATE('A', 8000);
SELECT
	@V,
	LEN(@V)
;

--Concatenation of long strings
SELECT
	LEN(REPLICATE('A', 8000))		+	LEN(REPLICATE('B', 8000)),
	LEN(	REPLICATE('A', 8000)	+	REPLICATE('B', 8000)	)
;

--Solution
SELECT
	LEN(	CAST('' AS VARCHAR(MAX))	+	REPLICATE('A', 8000)	+	REPLICATE('B', 8000)	)
;


--String comparison
SELECT
	CASE WHEN 'AAA       ' = 'AAA'
		THEN 'True'
		ELSE 'False'
	END
;

SELECT
	CASE WHEN '       ' = ''
		THEN 'True'
		ELSE 'False'
	END
;


--Float
DECLARE @f AS FLOAT = 29545428.022495;
SELECT CAST(@f AS NUMERIC(28, 14)) AS value;
