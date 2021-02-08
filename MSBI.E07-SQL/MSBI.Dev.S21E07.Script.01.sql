/*=========================================
MSBI.DEV.S19E07.SCRIPT
=========================================*/



/*=========================================
Views
=========================================*/

USE TSQL2012;
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

/*=========================================
--getmetadata 
=========================================*/

USE TSQL2012;
GO
SELECT name, object_id, principal_id, schema_id, type
FROM sys.views;

SELECT *
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'VIEW';


SELECT *
FROM INFORMATION_SCHEMA.ROUTINES



