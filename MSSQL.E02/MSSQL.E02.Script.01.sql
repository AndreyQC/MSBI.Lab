/*=========================================
MSSQL.E02.Script.01.sql
=========================================*/

USE [TSQL2012];
GO
SELECT 1;

/*==============================================================================
Getting Started with the SELECT Statement

================================================================================*/

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

-- not recommended way to sort
SELECT
	empid,
	lastname
FROM HR.Employees
ORDER BY 1;

--What will be the order?
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC

--Make it determenistic
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC, orderid DESC;

--Sorting null values
SELECT orderid, orderdate, custid, empid, shipregion
FROM Sales.Orders
ORDER BY shipregion, orderid;


-- aliases for tables and columns
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
SELECT
	empid,
	firstname AS lastname
FROM HR.Employees;

SELECT
	empid, 
	lastname = firstname
FROM HR.Employees;


-- non relational
SELECT empid, firstname + N' ' + lastname
FROM HR.Employees;


/*==============================================================================
Three-Valued Predicate Logic

================================================================================*/

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

--The only option to reuse aliases
SELECT
	country,
	YEAR(hiredate) AS yearhired
FROM HR.Employees
ORDER BY yearhired


--=========================================================================
-- Code Style Conventions
--=========================================================================
--Show the script MSSQL.E02.Script.02.CodeStyle.sql


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

GO

--=========================================================================
-- CASE Expression and Related Functions
--=========================================================================

--the simple form

SELECT
	productid,
	productname,
	unitprice,
	discontinued,
	CASE discontinued
		WHEN 0		THEN 'No'
		WHEN 1		THEN 'Yes'
                    ELSE 'Unknown'
	END			AS discontinued_desc
FROM Production.Products;


--The searched form of the CASE expression

SELECT
	productid,
	productname,
	unitprice,
	CASE
		WHEN productname =   N'Product HHYDP'    THEN 'Extreme'
		WHEN unitprice   <   20.00               THEN 'Low'
		WHEN unitprice   <   40.00               THEN 'Medium'
		WHEN unitprice   >=  40.00               THEN 'High'
												 ELSE 'Unknown'
	END		AS pricerange
FROM Production.Products;


--Swap 2nd and 3d conditions
SELECT
	productid,
	productname,
	unitprice,
	CASE
		WHEN productname =   N'Product HHYDP'    THEN 'Extreme'
		WHEN unitprice   <   40.00               THEN 'Medium'
		WHEN unitprice   <   20.00               THEN 'Low'			--Will never match
		WHEN unitprice   >=  40.00               THEN 'High'
												 ELSE 'Unknown'
	END		AS pricerange
FROM Production.Products;



--COALESCE vs ISNULL
DECLARE
	@x1 AS INT = 111,
	@x2 AS INT = NULL,
	@x3 AS INT = 333;

SELECT COALESCE(@x1, @x3),	COALESCE(@x2, @x3);
SELECT ISNULL(@x1, @x3),	ISNULL(@x2, @x3);


--COALESCE(<exp1>, <exp2>, , <expn>)
--is similar to the following.
--CASE
--WHEN <exp1> IS NOT NULL THEN <exp1>
--WHEN <exp2> IS NOT NULL THEN <exp2>
--
--WHEN <expn> IS NOT NULL THEN <expn>
--END


--COALESCE vs ISNULL
DECLARE
	@a AS INT = NULL,
	@b AS INT = 123;

SELECT COALESCE(@a, NULL, @b, 0);
SELECT ISNULL(@a, @b);


DECLARE
	@x AS VARCHAR(3) = NULL,
	@y AS VARCHAR(10) = '1234567890';

SELECT COALESCE(@x, @y) AS [COALESCE], ISNULL(@x, @y) AS [ISNULL];


SELECT COALESCE(NULL, NULL);
SELECT ISNULL(NULL, NULL);


SELECT IIF(1 = 0, 'true', 'false');

SELECT CHOOSE(2, 'x', 'y', 'z');


/*=======================================================
Filtering and Sorting Data

========================================================*/
--Predicates, Three-Valued Logic, and Search Arguments

SELECT empid, firstname, lastname, country, region, city
FROM HR.Employees
WHERE region = N'WA';

SELECT empid, firstname, lastname, country, region, city
FROM HR.Employees
WHERE region <> N'WA';

SELECT empid, firstname, lastname, country, region, city
FROM HR.Employees
WHERE region <> N'WA' OR region IS NULL;

-- non-sarg
SELECT empid, firstname, lastname, country, region, city
FROM HR.Employees
WHERE ISNULL(region,'') <> N'WA';



--Search Arguments (SARG)
DECLARE @dt1 DATETIME = '2008-04-13 00:00:00.000';
SELECT orderid, shippeddate, empid
FROM Sales.Orders
WHERE COALESCE(shippeddate, '19000101') = COALESCE(@dt1, '19000101');

DECLARE @dt2 DATETIME = '2008-04-13 00:00:00.000';
SELECT orderid, shippeddate, empid
FROM Sales.Orders
WHERE shippeddate = @dt2
	OR (shippeddate IS NULL AND @dt2 IS NULL);

--Check plan
DECLARE @dt3 DATETIME = '2008-04-13 00:00:00.000';
SELECT orderid, shippeddate, empid
FROM Sales.Orders
WHERE shippeddate = @dt3 OR @dt3 IS NULL;



--Implicit conversion
SELECT empid, firstname, lastname
FROM HR.Employees
WHERE empid = '1';


--Varchar vs nvarchar
SELECT empid, lastname
FROM HR.Employees
WHERE lastname = 'Davis';

SELECT empid, lastname
FROM HR.Employees
WHERE lastname = N'Davis';

--Is it OK?

--Try varchar column
DROP TABLE IF EXISTS HR.NewEmployees;

SELECT empid, firstname, CAST(lastname AS VARCHAR(20)) AS lastname
INTO HR.NewEmployees
FROM HR.Employees;


SELECT empid, lastname
FROM HR.NewEmployees
WHERE lastname = 'Davis';

--Check predicate
SELECT empid, lastname
FROM HR.NewEmployees
WHERE lastname = N'Davis';

DROP TABLE IF EXISTS HR.NewEmployees;


--Filtering Character Data
-- LIKE

--SARG
SELECT empid, lastname
FROM HR.Employees
WHERE lastname LIKE N'D%';

--Case insensitive
SELECT empid, lastname
FROM HR.Employees
WHERE lastname LIKE N'd%';

--Non-SARG
SELECT empid, lastname
FROM HR.Employees
WHERE lastname LIKE N'%d%';


--Filtering Date and Time Data

--Wrong
SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE orderdate = '02/12/07';

--Correct
SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE orderdate = '20070212';	--YYYYMMDD


-- best way to select interval

SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE YEAR(orderdate) = 2008 AND MONTH(orderdate) = 4;


SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE orderdate >= '20080401' AND orderdate < '20080501';


SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE orderdate BETWEEN '20080401' AND '20080430 23:59:59.999';



SELECT
	[DateStr],
	CAST([DateStr] AS DATETIME)		AS [DateTime],
	CAST([DateStr] AS DATETIME2(3))	AS [DateTime2]
FROM
	(VALUES
		('20080430 23:59:59.997'),
		('20080430 23:59:59.998'),
		('20080430 23:59:59.999'),
		('20080501 00:00:00.000'),
		('20080501 00:00:00.001'),
		('20080501 00:00:00.002')
	) AS val([DateStr])


--Filtering Data with TOP

SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC, orderid DESC;


SELECT TOP (10) orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC, orderid DESC;


SELECT TOP (10) PERCENT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC, orderid DESC;

DECLARE @n AS BIGINT = 10;
SELECT TOP (@n) orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC, orderid DESC;

-- it can work without ORDER clause
SELECT TOP (3) orderid, orderdate, custid, empid
FROM Sales.Orders;

-- to keep consistant
SELECT TOP (3) orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY NEWID();


--what if there are other rows 
SELECT TOP (1) WITH TIES orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC;
--Non-determenistic there



--Filtering Data with OFFSET-FETCH

SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC, orderid DESC
OFFSET 50 ROWS FETCH NEXT 25 ROWS ONLY;

--The same as TOP
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC, orderid DESC
OFFSET 0 ROWS FETCH FIRST 25 ROWS ONLY;

--requests to skip 50 rows, returning all the rest.
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC, orderid DESC
OFFSET 50 ROWS;

--filter a certain number of rows based on arbitrary order
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY (SELECT NULL)
OFFSET 0 ROWS FETCH FIRST 3 ROWS ONLY;

--paginator
DECLARE @pagesize AS BIGINT = 25, @pagenum AS BIGINT = 4;
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC, orderid DESC
OFFSET (@pagenum - 1) * @pagesize ROWS FETCH NEXT @pagesize ROWS ONLY;



/*===========================================================================
Combining Sets

=============================================================================*/

-- cross join
SELECT * FROM dbo.Nums;

SELECT
	D.n AS theday,
	S.n AS shiftno
FROM dbo.Nums AS D
	CROSS JOIN dbo.Nums AS S
WHERE D.n <= 7
	AND S.N <= 3
ORDER BY theday, shiftno;


--Add test data

IF NOT EXISTS(SELECT 1 FROM Production.Suppliers WHERE companyname = N'Supplier XYZ')
	INSERT INTO Production.Suppliers
		(companyname, contactname, contacttitle, address, city, postalcode, country, phone)
	VALUES(N'Supplier XYZ', N'Jiru', N'Head of Security', N'42 Sekimai Musashino-shi',
		N'Tokyo', N'01759', N'Japan', N'(02) 4311-2609');

SELECT * FROM Production.Suppliers;
SELECT * FROM Production.Products;

--This supplier does not have any related products in the Production.Products table and is used in examples demonstrating nonmatches.


-- inner join

SELECT
    S.companyname AS supplier,
    S.country,
    P.productid,
    P.productname,
    P.unitprice
FROM Production.Suppliers AS S
    INNER JOIN Production.Products AS P
        ON P.supplierid = S.supplierid
WHERE S.country = N'Japan';

-- for inner we can move filter to ON
SELECT
    S.companyname AS supplier,
    S.country,
    P.productid,
    P.productname,
    P.unitprice
FROM Production.Suppliers AS S
    INNER JOIN Production.Products AS P
        ON S.supplierid = P.supplierid
        AND S.country = N'Japan';

--Outer Joins

SELECT
    S.companyname AS supplier,
    S.country,
    P.productid,
    P.productname,
    P.unitprice
FROM Production.Suppliers AS S
    LEFT OUTER JOIN Production.Products AS P
        ON S.supplierid = P.supplierid 
WHERE S.country = N'Japan';



SELECT
    S.companyname AS supplier,
    S.country,
    P.productid,
    P.productname,
    P.unitprice
FROM Production.Suppliers AS S
    LEFT OUTER JOIN Production.Products AS P
        ON S.supplierid = P.supplierid 
		AND S.country = N'Japan'
;

--with outer joins, the ON and WHERE clauses play
--very different roles, and therefore, they aren't interchangeable


--multi joins

SELECT
	S.companyname AS supplier,
	S.country,
	P.productid,
	P.productname,
	P.unitprice,
	C.categoryname
FROM Production.Suppliers AS S
	LEFT JOIN Production.Products AS P
		ON S.supplierid = P.supplierid
	LEFT JOIN Production.Categories AS C
		ON C.categoryid = P.categoryid
WHERE S.country = N'Japan';


SELECT
	S.companyname AS supplier,
	S.country,
	P.productid,
	P.productname,
	P.unitprice,
	C.categoryname
FROM Production.Suppliers AS S
	LEFT JOIN Production.Products AS P
		ON S.supplierid = P.supplierid
	INNER JOIN Production.Categories AS C
		ON C.categoryid = P.categoryid
WHERE S.country = N'Japan';


SELECT
	S.companyname AS supplier,
	S.country,
	P.productid,
	P.productname,
	P.unitprice,
	C.categoryname
FROM Production.Suppliers AS S
	LEFT OUTER JOIN Production.Products AS P
		ON S.supplierid = P.supplierid
	LEFT JOIN Production.Categories AS C
		ON C.categoryid = P.categoryid
		AND C.categoryname = N'Beverages'
;


SELECT
	S.companyname AS supplier,
	S.country,
	P.productid,
	P.productname,
	P.unitprice,
	C.categoryname
FROM Production.Suppliers AS S
	LEFT OUTER JOIN (
		Production.Products AS P
		INNER JOIN Production.Categories AS C
			ON C.categoryid = P.categoryid
	)
		ON S.supplierid = P.supplierid
		AND C.categoryname = N'Beverages'
;


--Clean up
DELETE
FROM Production.Suppliers
WHERE companyname = N'Supplier XYZ';



/*========================================================================================================================
Using Set Operators

========================================================================================================================*/



-- UNION ALL
SELECT country, region, city
FROM HR.Employees
UNION ALL
SELECT country, region, city
FROM Sales.Customers
ORDER BY country;


--UNION
SELECT country, region, city
FROM HR.Employees
UNION
SELECT country, region, city
FROM Sales.Customers
ORDER BY country;


-- UNION = UNION ALL + DISTINCT
SELECT country, region, city
FROM HR.Employees
UNION
SELECT N'' AS country, N'' AS region, N'' AS city


--INTERSECT
SELECT country, region, city
FROM HR.Employees
INTERSECT
SELECT country, region, city
FROM Sales.Customers;


--EXCEPT
SELECT country, region, city
FROM HR.Employees
EXCEPT
SELECT country, region, city
FROM Sales.Customers


--EXCEPT --compare with previous
SELECT country, region, city
FROM Sales.Customers
EXCEPT
SELECT country, region, city
FROM HR.Employees;


-- INTERSECT precedes UNION and EXCEPT, and
--UNION and EXCEPT are considered equal