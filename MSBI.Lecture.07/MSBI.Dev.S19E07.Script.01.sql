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

USE TSQL2012;
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


SELECT
	YEAR(O.orderdate) AS orderyear,
	SUM(OD.qty) AS qty
FROM Sales.Orders AS O
	JOIN Sales.OrderDetails AS OD
		ON OD.orderid = O.orderid
GROUP BY YEAR(orderdate);

SELECT * FROM Sales.vw_OrderTotalsByYear

IF OBJECT_ID('Sales.vw_Customers', 'V') IS NOT NULL
BEGIN
    DROP VIEW Sales.vw_Customers;
END
ELSE
BEGIN
    PRINT 'view does not exist';
END

GO

CREATE VIEW Sales.vw_Customers
WITH  SCHEMABINDING 
AS

SELECT [custid],
	[companyname]
FROM [Sales].[Customers]
WHERE [companyname] LIKE 'Customer Q%'
WITH CHECK OPTION
;
GO
SELECT * FROM [Sales].[Customers]

ALTER TABLE [Sales].[Customers]
DROP COLUMN [companyname]

--Customer QNIVZ 
UPDATE Sales.vw_Customers
   SET companyname=N'Customer QNIVZ'
   --SET    contacttitle='Owner test'
WHERE custid=56

SELECT orderyear, qty
FROM Sales.vw_OrderTotalsByYear;

/*
-- won't work
CREATE VIEW Sales.OrderTotalsByYear(orderyear, qty)
WITH SCHEMABINDING
AS
SELECT
	YEAR(O.orderdate),
	SUM(OD.qty)
FROM Sales.Orders AS O
	JOIN Sales.OrderDetails AS OD
		ON OD.orderid = O.orderid
GROUP BY YEAR(orderdate);
GO
*/

/*=========================================
altering view
=========================================*/

ALTER VIEW Sales.vw_OrderTotalsByYear
WITH SCHEMABINDING
AS
SELECT
	O.shipregion,
	YEAR(O.orderdate) AS orderyear,
	SUM(OD.qty)  AS qty,
	count_big(*) as cnt
FROM Sales.Orders AS O
	JOIN Sales.OrderDetails AS OD
		ON OD.orderid = O.orderid
GROUP BY YEAR(orderdate), O.shipregion

GO

SELECT * FROM Sales.vw_OrderTotalsByYear

CREATE UNIQUE CLUSTERED INDEX IDX_vw_OrderTotalsByYear ON Sales.vw_OrderTotalsByYear ( orderyear, shipregion);


/*=========================================
--get viewsmetadata 
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
/*=========================================
Inline Functions
=========================================*/
USE TSQL2012;
GO
/*=========================================
Droping Functions
=========================================*/
IF OBJECT_ID (N'Sales.fn_OrderTotalsByYear', N'IF') IS NOT NULL
DROP FUNCTION Sales.fn_OrderTotalsByYear;
GO
/*=========================================
Creating Functions
=========================================*/
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
	SELECT orderyear, qty FROM Sales.vw_OrderTotalsByYear
);
GO

/*=========================================
several way to get data by year 2007
=========================================*/

SELECT orderyear, qty
FROM Sales.fn_OrderTotalsByYear()
WHERE orderyear = 2007;


DECLARE @orderyear int = 2007;
SELECT orderyear, qty
FROM Sales.OrderTotalsByYear
WHERE orderyear = @orderyear;

USE TSQL2012;
GO
IF OBJECT_ID (N'Sales.fn_OrderTotalsByYear', N'IF') IS NOT NULL
DROP FUNCTION Sales.fn_OrderTotalsByYear;
GO
CREATE FUNCTION Sales.fn_OrderTotalsByYear (@orderyear int)
RETURNS TABLE
AS
RETURN
(
	SELECT orderyear, qty FROM Sales.vw_OrderTotalsByYear
	WHERE orderyear = @orderyear
);
GO

SELECT orderyear, qty FROM Sales.fn_OrderTotalsByYear(2008);
/*=========================================
Creating a Synonym
=========================================*/

USE TSQL2012;
GO
CREATE SYNONYM dbo.Categories FOR Production.Categories;
GO

SELECT * FROM dbo.[Categories]


SELECT categoryid, categoryname, description
FROM Categories;

/*=========================================
altering view
=========================================*/



/*=========================================
altering view
=========================================*/
