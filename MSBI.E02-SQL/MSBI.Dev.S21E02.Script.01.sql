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
  WHERE [region] = N'WA'

SELECT [empid]
      ,[lastname]
      ,[region]
  FROM [TSQL2012].[HR].[Employees]
  WHERE [region] <> N'WA'

--Null
SELECT [empid]
      ,[lastname]
      ,[region]
  FROM [TSQL2012].[HR].[Employees]
  WHERE [region] <> 'WA' OR [region] IS NUll


--Using T-SQL in a Relational Way

SELECT country
FROM HR.Employees;


--remove duplicates
SELECT DISTINCT country
FROM HR.Employees;


-- order in sets
SELECT
	empid,
	lastname
FROM HR.Employees;

-- let's make it ordered
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



/*==============================================================================
Logical Query Processing Phases

================================================================================*/

SELECT	country,
        COUNT(*) AS numemployees
FROM HR.Employees
WHERE hiredate >= '20030101'
GROUP BY country
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


-- non relational
SELECT empid, firstname + N' ' + lastname
FROM HR.Employees;




--=========================================================================
-- Data Types
--=========================================================================

-- Does it works?
DECLARE @X INT = '1';
SELECT @X;


--Yes, but don't do it


SELECT
	empid,
	lastname
FROM HR.Employees
WHERE empid = '1';
--DON'T EVER DO IT!!!


DECLARE @Y INT = 'AAA';
SELECT @Y;


DECLARE @S1 VARCHAR(1) = 1;
SELECT @S1;


DECLARE @S2 VARCHAR(1) = 1111;
SELECT @S2;


DECLARE @S3 VARCHAR(2) = 'ABC';
SELECT @S3;





--Simple arithmetic
SELECT 1 / 2;


--Solution
SELECT 1.0 / 2;


--What's now?
SELECT 1 / 2 + 0.5;


--Replicate and len functions
DECLARE @V VARCHAR(MAX) = REPLICATE('A', 6000);
SELECT
	'A' + 'B',
	@V,
	LEN(@V)
;

--Concatenation of long strings
SELECT
	LEN(REPLICATE('A', 6000))		+	LEN(REPLICATE('B', 6000)),
	LEN(	REPLICATE('A', 6000)	+	REPLICATE('B', 6000)	)
;

--Solution
SELECT
	LEN(	CAST('' AS VARCHAR(MAX))	+	REPLICATE('A', 6000)	+	REPLICATE('B', 6000)	)
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
