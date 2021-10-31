/*=========================================
MSSQL.E04.Script.01.sql
=========================================*/

USE [TSQL2012];
GO

/*========================================================================================================================
 Creating and Altering Tables

========================================================================================================================*/

-- create schema
CREATE SCHEMA Production AUTHORIZATION dbo;
GO


IF OBJECT_ID(N'Production.CategoriesTest', N'U') IS NOT NULL
	DROP TABLE Production.CategoriesTest;
GO

CREATE TABLE Production.CategoriesTest
(
	categoryid		INT				NOT NULL	IDENTITY(1,1),
	categoryname	NVARCHAR(15)	NOT NULL,
	description		NVARCHAR(200)	NOT NULL
)
GO



/*---------------------------------------------------------------------------------------- 
 Altering table
-----------------------------------------------------------------------------------------*/

USE TSQL2012;
GO

DROP TABLE IF EXISTS Production.CategoriesTest;
GO

CREATE TABLE Production.CategoriesTest
(
	categoryid INT NOT NULL IDENTITY
);
GO

-- add two columns
ALTER TABLE Production.CategoriesTest
	ADD	categoryname NVARCHAR(15) NOT NULL,
		description NVARCHAR(200) NOT NULL;
GO

--Make the description column larger.
ALTER TABLE Production.CategoriesTest
	ALTER COLUMN description NVARCHAR(500);
GO

DROP TABLE IF EXISTS Production.CategoriesTest;
GO


/*---------------------------------------------------------------------------------------- 
 Computed Columns
-----------------------------------------------------------------------------------------*/

SELECT TOP (10) 
    orderid, 
    productid, 
    unitprice, 
    qty,
    unitprice * qty AS initialcost -- expression
FROM Sales.OrderDetails;

CREATE TABLE Sales.OrderDetails
(
    orderid INT NOT NULL,
	unitprice money NOT NULL,
	qty smallint NOT NULL,
    initialcost AS unitprice * qty -- computed column
	--initialcost AS unitprice * qty PERSISTED
);

ALTER TABLE Sales.OrderDetails
	ADD initialcost AS unitprice * qty;


SELECT * FROM Sales.OrderDetails;


ALTER TABLE Sales.OrderDetails
	DROP COLUMN IF EXISTS initialcost;



/*========================================================================================================================
 Enforcing Data Integrity

========================================================================================================================*/


/*---------------------------------------------------------------------------------------- 
 Primary Key Constraints
-----------------------------------------------------------------------------------------*/
DROP TABLE IF EXISTS Production.CategoriesTest;
GO

--Bad
CREATE TABLE Production.CategoriesTest
(
    categoryid INT NOT NULL PRIMARY KEY,
    categoryname NVARCHAR(15) NOT NULL,
    description NVARCHAR(200) NOT NULL
);


DROP TABLE IF EXISTS Production.CategoriesTest;
GO

--Good
CREATE TABLE Production.CategoriesTest
(
    categoryid INT NOT NULL CONSTRAINT PK_CategoriesTest PRIMARY KEY,
    categoryname NVARCHAR(15) NOT NULL,
    description NVARCHAR(200) NOT NULL
);


DROP TABLE IF EXISTS Production.CategoriesTest;
GO

--Good
CREATE TABLE Production.CategoriesTest
(
    categoryid INT NOT NULL,
    categoryname NVARCHAR(15) NOT NULL,
    description NVARCHAR(200) NOT NULL,
    CONSTRAINT PK_CategoriesTest PRIMARY KEY(categoryid)
);

INSERT INTO [Production].[CategoriesTest]
           ([categoryid],[categoryname],[description])
     VALUES
           (1,'testa','tet')


-- add to existing table
ALTER TABLE Production.Categories
	ADD CONSTRAINT PK_Categories PRIMARY KEY(categoryid);
GO


--PK is not only over clustered index. Clustered index is not only unique
DROP TABLE IF EXISTS Production.CategoriesTest;
GO

CREATE TABLE Production.CategoriesTest
(
    categoryid INT NOT NULL IDENTITY,
    categoryname NVARCHAR(15) NOT NULL,
    description NVARCHAR(200) NOT NULL,
    CONSTRAINT PK_CategoriesTest PRIMARY KEY NONCLUSTERED(categoryid)
);
GO

CREATE CLUSTERED INDEX [CI_Production_CategoriesTest]	--Non unique!
	ON [Production].[CategoriesTest] ([categoryname]);
GO


-- get list of constraint
SELECT *
FROM sys.key_constraints
WHERE type = 'PK';

-- get list of indexes which support logical constraints
SELECT *
FROM sys.indexes
WHERE object_id = OBJECT_ID('Production.Categories') AND name = 'PK_Categories';

/*---------------------------------------------------------------------------------------- 
 Unique Constraints
-----------------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS Production.CategoriesTest;
GO

CREATE TABLE Production.CategoriesTest
(
    categoryid INT NOT NULL,
    categoryname NVARCHAR(15) NOT NULL	CONSTRAINT UC_CategoriesTest_categoryname UNIQUE,
    description NVARCHAR(200) NOT NULL
);

ALTER TABLE Production.Categories
	ADD CONSTRAINT UC_Categories UNIQUE (categoryname);
GO
--The unique constraint does not require the column to be NOT NULL. You can allow NULL in
--a column and still have a unique constraint, but only one row can be NULL.


DROP TABLE IF EXISTS Production.CategoriesTest;
GO


SELECT *
FROM sys.key_constraints
WHERE type = 'UQ';

/*---------------------------------------------------------------------------------------- 
 Foreign Key Constraints
-----------------------------------------------------------------------------------------*/

USE TSQL2012
GO
ALTER TABLE Production.Products WITH CHECK
	ADD CONSTRAINT FK_Products_Categories FOREIGN KEY(categoryid)
	REFERENCES Production.Categories (categoryid)
GO

--
SELECT *
FROM sys.foreign_keys
WHERE name = 'FK_Products_Categories';

/*---------------------------------------------------------------------------------------- 
 Check Constraints
-----------------------------------------------------------------------------------------*/


ALTER TABLE Production.Products WITH CHECK
	ADD CONSTRAINT CK_Products_unitprice
	CHECK (unitprice>=0);
GO

--
SELECT *
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID('Production.Products');

/*---------------------------------------------------------------------------------------- 
 Default Constraints
-----------------------------------------------------------------------------------------*/


CREATE TABLE Production.Products
(
    productid INT NOT NULL IDENTITY,
    productname NVARCHAR(40) NOT NULL,
    supplierid INT NOT NULL,
    categoryid INT NOT NULL,
    unitprice MONEY NOT NULL 
    CONSTRAINT DF_Products_unitprice DEFAULT(0),
    discontinued BIT NOT NULL
    CONSTRAINT DF_Products_discontinued DEFAULT(0),
);

SELECT *
FROM sys.default_constraints
WHERE parent_object_id = OBJECT_ID('Production.Products');




/*=========================================
Views
=========================================*/

/*=========================================
Dropping a View
=========================================*/
IF OBJECT_ID('Sales.vw_OrderTotalsByYear', 'V') IS NOT NULL
	DROP VIEW Sales.vw_OrderTotalsByYear;
GO

/*=========================================
Creating a View
=========================================*/
CREATE VIEW Sales.vw_OrderTotalsByYear
WITH SCHEMABINDING
AS
SELECT
	YEAR(O.orderdate) AS orderyear,
	SUM(OD.qty) AS qty
FROM Sales.Orders AS O
	JOIN Sales.OrderDetails AS OD
		ON OD.orderid = O.orderid
GROUP BY YEAR(orderdate);
GO

SELECT * FROM Sales.vw_OrderTotalsByYear;
GO

/*=========================================
Create or alter
=========================================*/
CREATE OR ALTER VIEW Sales.vw_OrderTotalsByYear
WITH SCHEMABINDING
AS
SELECT
	YEAR(O.orderdate) AS orderyear,
	SUM(OD.qty) AS qty
FROM Sales.Orders AS O
	JOIN Sales.OrderDetails AS OD
		ON OD.orderid = O.orderid
GROUP BY YEAR(orderdate);
GO

SELECT * FROM Sales.vw_OrderTotalsByYear;

SELECT
	YEAR(O.orderdate) AS orderyear,
	SUM(OD.qty) AS qty
FROM Sales.Orders AS O
	JOIN Sales.OrderDetails AS OD
		ON OD.orderid = O.orderid
GROUP BY YEAR(orderdate);

GO

/*=========================================
View Options
=========================================*/
CREATE OR ALTER VIEW Sales.vw_Customers
--WITH  SCHEMABINDING 
AS

SELECT [custid],
	[companyname],
	[country]
FROM [Sales].[Customers]
WHERE [companyname] LIKE 'Customer Q%'
WITH CHECK OPTION
;
GO

--Test SCHEMABINDING
BEGIN TRAN;
ALTER TABLE [Sales].[Customers]
	DROP COLUMN [country];

SELECT * FROM [Sales].[vw_Customers];

ROLLBACK TRAN;
GO

SELECT * FROM [Sales].[vw_Customers]

--Test CHECK OPTION
UPDATE Sales.vw_Customers
   SET companyname=N'Customer QNIVZ'
   --SET companyname=N'Customer MLTDN'
WHERE custid=56;

GO

DROP VIEW IF EXISTS [Sales].[vw_Customers];
GO
/*=========================================
Indexed view
=========================================*/

CREATE OR ALTER VIEW Sales.vw_OrderTotalsByYear
WITH SCHEMABINDING
AS
SELECT
	O.shipregion,
	YEAR(O.orderdate) AS orderyear,
	SUM(OD.qty)  AS qty,
	COUNT_BIG(*) as cnt
FROM Sales.Orders AS O
	JOIN Sales.OrderDetails AS OD
		ON OD.orderid = O.orderid
GROUP BY YEAR(orderdate), O.shipregion;

GO

SELECT * FROM Sales.vw_OrderTotalsByYear;

CREATE UNIQUE CLUSTERED INDEX CI_vw_OrderTotalsByYear
	ON Sales.vw_OrderTotalsByYear (orderyear, shipregion);

--NOEXPAND hint
SELECT * FROM Sales.vw_OrderTotalsByYear WITH(NOEXPAND);

DROP VIEW IF EXISTS Sales.vw_OrderTotalsByYear;
GO

/*=========================================
Inline Functions
=========================================*/
USE TSQL2012;
GO
IF OBJECT_ID (N'Sales.fn_OrderTotalsByYear', N'IF') IS NOT NULL
	DROP FUNCTION Sales.fn_OrderTotalsByYear;
GO
CREATE FUNCTION Sales.fn_OrderTotalsByYear ()
RETURNS TABLE
AS
RETURN
(
	SELECT
		YEAR(O.orderdate) AS orderyear,
		SUM(OD.qty) AS qty
	FROM Sales.Orders AS O
		JOIN Sales.OrderDetails AS OD
			ON OD.orderid = O.orderid
	GROUP BY YEAR(orderdate)
);
GO


SELECT *  FROM [Sales].[fn_OrderTotalsByYear]();

GO

CREATE OR ALTER FUNCTION Sales.fn_OrderTotalsByYear (@orderyear int)
RETURNS TABLE
AS
RETURN
(
	SELECT orderyear, qty
	FROM Sales.OrderTotalsByYear
	WHERE orderyear = @orderyear
);
GO

SELECT orderyear, qty FROM Sales.fn_OrderTotalsByYear(2008);

--APPLY operator
SELECT
	ord.custid,
	ord.orderdate,
	ord.freight,
	ttl.qty
FROM
	Sales.Orders AS ord
	CROSS APPLY Sales.fn_OrderTotalsByYear( YEAR(ord.orderdate) ) AS ttl
WHERE
	custid = 56
;


--Clean up
DROP FUNCTION IF EXISTS Sales.fn_OrderTotalsByYear;
GO

/*=========================================
Scalar Functions
=========================================*/
IF OBJECT_ID('Sales.fn_extension', 'FN') IS NOT NULL
	DROP FUNCTION Sales.fn_extension
GO
CREATE FUNCTION Sales.fn_extension
          (
               @unitprice AS MONEY,
               @qty AS INT
          )
RETURNS MONEY
AS
BEGIN
     RETURN @unitprice * @qty
END;
GO
-- use UDFs
SELECT Orderid, unitprice, qty,
	Sales.fn_extension(unitprice, qty) AS extension
FROM Sales.OrderDetails;

-- also UDFs can be used in this way
SELECT Orderid, unitprice, qty,
	Sales.fn_extension(unitprice, qty) AS extension
FROM Sales.OrderDetails
WHERE Sales.fn_extension(unitprice, qty) > 1000;


--Clean up
DROP FUNCTION IF EXISTS Sales.fn_extension;
GO


/*====================================================================================================================================================
Multistatement Table-Valued UDF

=========================================*/
IF OBJECT_ID('Sales.fn_FilteredExtensionTF', 'TF') IS NOT NULL
	DROP FUNCTION Sales.fn_FilteredExtensionTF;
GO
CREATE FUNCTION Sales.fn_FilteredExtensionTF
(
     @lowqty AS SMALLINT,
     @highqty AS SMALLINT
)
RETURNS @returntable TABLE
(
     orderid INT,
     unitprice MONEY,
     qty SMALLINT
)
AS
BEGIN
     INSERT @returntable
     SELECT orderid, unitprice, qty
     FROM Sales.OrderDetails
     WHERE qty BETWEEN @lowqty AND @highqty

     RETURN
END;
GO

SELECT orderid, unitprice, qty
FROM Sales.fn_FilteredExtensionTF (10,20);
GO


--Compare with inline function
CREATE OR ALTER FUNCTION Sales.fn_FilteredExtensionIF
(
     @lowqty AS SMALLINT,
     @highqty AS SMALLINT
)
RETURNS TABLE AS RETURN
(
     SELECT orderid, unitprice, qty
     FROM Sales.OrderDetails
     WHERE qty BETWEEN @lowqty AND @highqty
);
GO

--Like in SQL 2016 (check cardinality)
ALTER DATABASE [TSQL2012] SET COMPATIBILITY_LEVEL = 130;
GO

SET STATISTICS TIME ON;

SELECT orderid, unitprice, qty
FROM Sales.fn_FilteredExtensionIF (10,20);

SELECT orderid, unitprice, qty
FROM Sales.fn_FilteredExtensionTF (10,20);

SET STATISTICS TIME OFF;

--Back to SQL 2019
ALTER DATABASE [TSQL2012] SET COMPATIBILITY_LEVEL = 150;
GO

DBCC FREEPROCCACHE;

SET STATISTICS TIME ON;

SELECT orderid, unitprice, qty
FROM Sales.fn_FilteredExtensionIF (10,20);

SELECT orderid, unitprice, qty
FROM Sales.fn_FilteredExtensionTF (10,20);

SET STATISTICS TIME OFF;


GO

--Clean up
DROP FUNCTION IF EXISTS Sales.fn_FilteredExtensionIF;
DROP FUNCTION IF EXISTS Sales.fn_FilteredExtensionTF;
GO


















