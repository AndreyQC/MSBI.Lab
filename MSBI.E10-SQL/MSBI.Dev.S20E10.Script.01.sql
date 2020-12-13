/*=========================================
MSBI.DEV.COURSE.S20E10.SCRIPT
=========================================*/

/*

https://www.mssqltips.com/sqlservertip/1888/when-to-use-set-vs-select-when-assigning-values-to-variables-in-sql-server/
--- few words about SET and SELECT
--SET is the ANSI standard for variable assignment, SELECT is not.
--SET can only assign one variable at a time, SELECT can make multiple assignments at once.
--If assigning from a query, SET can only assign a scalar value.
 If the query returns multiple values/rows then SET will raise an error. 
 SELECT will assign one of the values to the variable and hide the fact that multiple 
 values were returned (so you'd likely never know why something was going wrong elsewhere - have fun troubleshooting that one)
--When assigning from a query if there is no value returned then SET will assign NULL, 
where SELECT will not make the assignment at all (so the variable will not be changed from its previous value)
--As far as speed differences - there are no direct differences between SET and SELECT.
 However SELECT's ability to make multiple assignments in one shot does give it a slight speed advantage over SET.
*/

USE [TSQL2012];
GO

-- Populate by single row
DECLARE @ProductId INT = -1;
SET @ProductId	= (SELECT productid FROM [Production].[Products] WHERE [productname] = N'Product HHYDP');

SELECT @ProductId;
GO

DECLARE @ProductId INT = -1;
SELECT @ProductId	= productid FROM [Production].[Products] WHERE [productname] = N'Product HHYDP';

SELECT @ProductId;
GO

-- Try to populate by empty result set
DECLARE @ProductId INT = -1;
SET @ProductId	= (SELECT productid FROM [Production].[Products] WHERE [productname] = N'Product ABC');

SELECT @ProductId;
GO

DECLARE @ProductId INT = -1;
SELECT @ProductId	= productid FROM [Production].[Products] WHERE [productname] = N'Product ABC';

SELECT @ProductId;
GO

-- Populate by multiple rows
DECLARE @ProductId INT = -1;
SET @ProductId	= (SELECT productid FROM [Production].[Products] WHERE [supplierid] = 1);

SELECT @ProductId;
GO

DECLARE @ProductId INT = -1;
SELECT @ProductId	= productid FROM [Production].[Products] WHERE [supplierid] = 1;

SELECT @ProductId;
GO

-- Use the feature
DECLARE @AllProducts NVARCHAR(MAX) = N'';
SELECT
	@AllProducts	= @AllProducts + [productname] + N','
FROM
	[Production].[Products]
ORDER BY
	[productname]
;
SELECT @AllProducts;

--Alternate approach
SELECT
	[productname] + N',' AS 'data()'
FROM
	[Production].[Products]
ORDER BY
	[productname]
FOR XML PATH ('')
;

--SQL 2017
SELECT
	STRING_AGG([productname], N',')
FROM
	[Production].[Products]
;


/*====================================================================================================================================================
--Dynamic SQL Overview
=========================================*/

declare @n char(1)
set @n = char(10)
declare @stmt nvarchar(max)
-- procedures
select @stmt = isnull( @stmt + @n, '' ) +
    'drop procedure [' + schema_name(schema_id) + '].[' + name + ']'
from sys.procedures
-- check constraints
select @stmt = isnull( @stmt + @n, '' ) +
'alter table [' + schema_name(schema_id) + '].[' + object_name( parent_object_id ) + ']    drop constraint [' + name + ']'
from sys.check_constraints
-- functions
select @stmt = isnull( @stmt + @n, '' ) +
    'drop function [' + schema_name(schema_id) + '].[' + name + ']'
from sys.objects
where type in ( 'FN', 'IF', 'TF' )
-- views
select @stmt = isnull( @stmt + @n, '' ) +
    'drop view [' + schema_name(schema_id) + '].[' + name + ']'
from sys.views
-- foreign keys
select @stmt = isnull( @stmt + @n, '' ) +
    'alter table [' + schema_name(schema_id) + '].[' + object_name( parent_object_id ) + '] drop constraint [' + name + ']'
from sys.foreign_keys
-- tables
select @stmt = isnull( @stmt + @n, '' ) +
    'drop table [' + schema_name(schema_id) + '].[' + name + ']'
from sys.tables
where (schema_name(schema_id) + '.' + name) not like 'DQ.AssessmentWell%'
-- user defined types
select @stmt = isnull( @stmt + @n, '' ) +
    'drop type [' + schema_name(schema_id) + '].[' + name + ']'
from sys.types
where is_user_defined = 1

select @stmt
PRINT @stmt;

--exec sp_executesql @stmt


USE TSQL2012;
GO
SELECT COUNT(*) AS ProductRowCount FROM [Production].[Products];


SELECT a.name as 'SchemaName',o.name as 'TableName', i.rowcnt as 'RowCount'
FROM sys.schemas a, sys.objects o, sysindexes i
WHERE i.id=o.object_idAND a.schema_id=o.schema_idAND indid in(0,1)AND o.type='U'AND o.name <> 'sysdiagrams'
ORDER BY a.name desc


USE TSQL2012;
GO
DECLARE @tablename AS NVARCHAR(261) = N'[Production].[Products]';
PRINT N'SELECT COUNT(*) FROM ' + @tablename;
GO

DECLARE @tablename AS NVARCHAR(261) = N'[Production].[Products]';
SELECT N'SELECT COUNT(*) FROM ' + @tablename;
GO

DECLARE @tablename AS NVARCHAR(261) = N'[Production].[Products]';

EXECUTE (N'SELECT COUNT(*) AS TableRowCount FROM ' + @tablename);
/*====================================================================================================================================================
single quotation marks PROBLEM
=========================================*/

SELECT custid, companyname, contactname, contacttitle, [address]
FROM [Sales].[Customers]
WHERE address = N'5678 rue de l''Abbaye';
GO
-- getting worse
PRINT N'SELECT custid, companyname, contactname, contacttitle, address
FROM [Sales].[Customers]
WHERE address = N''5678 rue de l''''Abbaye'';';



DECLARE @address AS NVARCHAR(60) = '5678 rue de l''Abbaye';
PRINT N'SELECT *
FROM [Sales].[Customers]
WHERE address = '+ QUOTENAME(@address, '''') + ';';

DECLARE 
     @SQLString AS NVARCHAR(4000)
     SET @SQLString=N'SELECT *
FROM [Sales].[Customers]
WHERE address = '+ QUOTENAME(@address, '''') + ';';
EXECUTE(@SQLString);
GO

/*====================================================================================================================================================
SQL Injection
=========================================*/

IF OBJECT_ID('Sales.ListCustomersByAddress') IS NOT NULL
DROP PROCEDURE Sales.ListCustomersByAddress;
GO
CREATE PROCEDURE Sales.ListCustomersByAddress
     @address NVARCHAR(60)
AS
     DECLARE @SQLString AS NVARCHAR(4000);
     SET @SQLString = '
     SELECT companyname, contactname
     FROM Sales.Customers WHERE address = ''' + @address + '''';
     PRINT @SQLString;
     EXEC(@SQLString);
     RETURN;
GO

USE TSQL2012;
GO
EXEC Sales.ListCustomersByAddress @address = '8901 Tsawassen Blvd.';

USE TSQL2012;
GO
EXEC Sales.ListCustomersByAddress @address = '''';

USE TSQL2012;
GO
EXEC Sales.ListCustomersByAddress @address = 'x'' OR 1=1 --';

USE TSQL2012;
GO
EXEC Sales.ListCustomersByAddress @address = '''; SELECT * FROM sys.tables  -- ';



USE TSQL2012;
GO
CREATE OR ALTER PROCEDURE Sales.ListCustomersByAddress
     @address AS NVARCHAR(60)
AS
DECLARE @SQLString AS NVARCHAR(4000);
     SET @SQLString = '
     SELECT companyname, contactname
     FROM Sales.Customers WHERE address = @address';
     EXEC sp_executesql
		@statment = @SQLString
		, @params = N'@address NVARCHAR(60)'
		, @address = @address;
     RETURN;
GO


USE TSQL2012;
GO
EXEC Sales.ListCustomersByAddress @address = '8901 Tsawassen Blvd.';
EXEC Sales.ListCustomersByAddress @address = '''';
EXEC Sales.ListCustomersByAddress @address = 'x'' OR 1=1 --';
EXEC Sales.ListCustomersByAddress @address = '''; SELECT * FROM sys.tables  -- ';


-- out put parameter
USE TSQL2012;
GO
DECLARE @SQLString AS NVARCHAR(4000)
, @outercount AS int;
SET @SQLString = N'SET @innercount = (SELECT COUNT(*) FROM Production.Products)';
EXEC sp_executesql
     @statment = @SQLString
     , @params = N'@innercount AS int OUTPUT'
     , @innercount = @outercount OUTPUT;
SELECT @outercount AS 'RowCount';

--EXEC sp_executesql @sql, N'@p1 INT, @p2 INT, @p3 INT', @p1, @p2, @p3;
go

DECLARE @ProductCount INT;
DECLARE @SupplierId INT = 1;
DECLARE @CategoryId INT = 1;
DECLARE @SQLString AS NVARCHAR(4000) = N'
	SELECT @ProductCount	= COUNT(*)
	FROM Production.Products
	WHERE	[supplierid]		= @SupplierId
			AND [categoryid]	= @CategoryId';
EXEC sp_executesql @SQLString,
	N'@SupplierId INT,
	@CategoryId INT,
	@ProductCount INT OUTPUT',
	@SupplierId = @SupplierId,
	@CategoryId = @CategoryId,
	@ProductCount = @ProductCount OUTPUT
;
SELECT @ProductCount;




--=======================================================================
-- using temporary tables vs. table variables
--=======================================================================
 
 -- temp table features
DROP TABLE IF EXISTS #T1;
CREATE TABLE #T1 (   col1 INT NOT NULL ); 
 
INSERT INTO #T1(col1) VALUES(10), (11), (12); 
 
EXEC('SELECT col1 FROM #T1;');
GO 
 
SELECT col1 FROM #T1;

TRUNCATE TABLE #T1;
 
DROP TABLE IF EXISTS #T1;
GO

 -- table variable features
DECLARE @T1 AS TABLE (   col1 INT NOT NULL ); 
 
INSERT INTO @T1(col1) VALUES(10), (11), (12); 

SELECT * FROM @T1 --OPTION(RECOMPILE);

EXEC('SELECT col1 FROM @T1;');

--TRUNCATE TABLE @T1;
GO

--SELECT * FROM @T1;
GO



 -- transaction
DROP TABLE IF EXISTS #T1;
CREATE TABLE #T1 (   col1 INT NOT NULL ); 
 
BEGIN TRAN 
 
  INSERT INTO #T1(col1) VALUES(10); 
 
ROLLBACK TRAN 
 
SELECT col1 FROM #T1; 
 
DROP TABLE #T1; 
GO


DECLARE @T1 AS TABLE (   col1 INT NOT NULL ); 
 
BEGIN TRAN 
 
  INSERT INTO @T1(col1) VALUES(10);
 
ROLLBACK TRAN 
 
SELECT col1 FROM @T1;





--*********************************************************************************************************************************************************************

/*=========================================
why SP
=========================================*/
USE TSQL2012;
GO
SELECT orderid, custid, shipperid, orderdate, requireddate, shippeddate
FROM Sales.Orders
WHERE custid = 37
     AND orderdate >= '2007-04-01'
     AND orderdate < '2007-07-01';

-- improvement
USE TSQL2012;
GO
DECLARE		@custid				AS INT,
               @orderdatefrom		AS DATETIME,
               @orderdateto		AS DATETIME;

SET @custid = 37;
SET @orderdatefrom = '2007-04-01';
SET @orderdateto = '2007-07-01';

SELECT orderid, custid, shipperid, orderdate, requireddate, shippeddate
FROM Sales.Orders
WHERE custid = @custid
          AND orderdate >= @orderdatefrom
          AND orderdate < @orderdateto;
GO


CREATE OR ALTER PROC Sales.GetCustomerOrders
     @custid AS INT,
     @orderdatefrom AS DATETIME = '19000101',
     @orderdateto AS DATETIME = '99991231',
     @numrows AS INT = 0 OUTPUT
     
AS
BEGIN
     SET NOCOUNT ON;
     SELECT orderid, custid, shipperid, orderdate, requireddate, shippeddate
     FROM Sales.Orders
     WHERE custid = @custid
          AND orderdate >= @orderdatefrom
          AND orderdate < @orderdateto;
     SET @numrows = @@ROWCOUNT;
     RETURN;-- explain
END
GO

-- run SP

DECLARE @rowsreturned AS INT;
EXEC Sales.GetCustomerOrders
     @custid = 37,
     @orderdatefrom = '20070401',
     @orderdateto = '20070701',
     @numrows = @rowsreturned OUTPUT;

SELECT @rowsreturned AS "Rows Returned";
GO
/*=========================================
Input Parameters
=========================================*/

EXEC Sales.GetCustomerOrders 37, '20070401', '20070701';

EXEC Sales.GetCustomerOrders
        @orderdateto = '20070701',
        @orderdatefrom = '20070401',
        @custid = 37;
GO

EXEC Sales.GetCustomerOrders
@custid = 37;
GO
/*====================================================================================================================================================
Output Parameters
=========================================*/
DECLARE @rowsreturned AS INT;
EXEC Sales.GetCustomerOrders
     @custid = 37,
     @orderdatefrom = '20070401',
     @orderdateto = '20070701',
     @numrows = @rowsreturned;

SELECT @rowsreturned AS 'Rows Returned';
GO


DECLARE @rowsreturned AS INT;
EXEC Sales.GetCustomerOrders
     @custid = 37,
     @orderdatefrom = '20070401',
     @orderdateto = '20070701',
     @numrows = @rowsreturned OUTPUT;
SELECT @rowsreturned AS 'Rows Returned';
GO

/*====================================================================================================================================================
Passing table data
=========================================*/

--table variables
DROP TYPE IF EXISTS [typ_ProductTable];
CREATE TYPE [typ_ProductTable] AS TABLE
(
     [productname] NVARCHAR(40) NOT NULL,
     [categoryid] INT NOT NULL,
     [supplierid] INT NOT NULL,
     [unitprice] MONEY NOT NULL,
     [discontinued] BIT NOT NULL
);
GO

CREATE OR ALTER PROCEDURE Production.InsertProducts
	@Products [typ_ProductTable] READONLY
AS
BEGIN
	SET NOCOUNT ON;

    INSERT Production.Products
		(productname, supplierid, categoryid, unitprice, discontinued)
	OUTPUT
		inserted.productname, inserted.supplierid, inserted.categoryid, inserted.unitprice, inserted.discontinued
	SELECT
		productname, supplierid, categoryid, unitprice, discontinued
	FROM @Products;
END;
GO

DECLARE @Products [typ_ProductTable];
INSERT INTO @Products
VALUES
	(N'New Product 1', 1, 1, 10.0, 0),
	(N'New Product 2', 1, 1, 10.0, 0);

EXEC Production.InsertProducts @Products;
GO


--JSON
CREATE OR ALTER PROCEDURE Production.InsertProducts
	@Products NVARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON;

    INSERT Production.Products
		(productname, supplierid, categoryid, unitprice, discontinued)
	OUTPUT
		inserted.productname, inserted.supplierid, inserted.categoryid, inserted.unitprice, inserted.discontinued
	SELECT
		productname, supplierid, categoryid, unitprice, discontinued
	FROM OPENJSON(@Products) WITH(
		[productname] NVARCHAR(40) '$.productname',
		[categoryid] INT '$.categoryid',
		[supplierid] INT '$.supplierid',
		[unitprice] MONEY '$.unitprice',
		[discontinued] BIT '$.discontinued'
	);
END;
GO

DECLARE @ProductJSON NVARCHAR(MAX) = N'
[
	{"productname": "New Product 3", "categoryid": 1, "supplierid": 1, "unitprice": 10.0, "discontinued": 0},
	{"productname": "New Product 4", "categoryid": 1, "supplierid": 1, "unitprice": 10.0, "discontinued": 0}
]';

EXEC Production.InsertProducts @ProductJSON;
GO

--Other options:
--XML
--String with separators, like 'New Product,1,1,10.0'

--Clean up
DROP TYPE IF EXISTS [typ_ProductTable];
DELETE Production.Products WHERE productname LIKE N'New Product%';
GO


/*====================================================================================================================================================
IF/ELSE
=========================================*/

DECLARE @var1 AS INT, @var2 AS INT;
SET @var1 = 1;
SET @var2 = 2;

-- without begin end
IF @var1 = @var2
    PRINT 'The variables are equal';
ELSE
    PRINT 'The variables are not equal';
GO

-- with begin end
DECLARE @var1 AS INT, @var2 AS INT;
SET @var1 = 1;
SET @var2 = 1;

IF @var1 = @var2 
BEGIN
	PRINT 'The variables are equal';
	PRINT '@var1 equals @var2';
END
ELSE
BEGIN
	PRINT 'The variables are not equal';
    PRINT '@var1 does not equal @var2';
END
GO

DECLARE @var1 AS INT, @var2 AS INT;
SET @var1 = 1;
SET @var2 = 1;
IF @var1 = @var2
     BEGIN
     PRINT 'The variables are equal';
     PRINT '@var1 does not equal @var2'
     END
ELSE
     PRINT 'The variables are not equal';
     PRINT '@var1 does not equal @var2';
     PRINT '@var1 does not equal @var2';
GO

/*====================================================================================================================================================
WHILE
===================================================================================================================================================*/

SET NOCOUNT ON;
DECLARE @count AS INT = 1;

WHILE  @count <= 10
BEGIN
	PRINT CAST(@count AS NVARCHAR);
    SET @count += 1;
END;

GO

SET NOCOUNT ON;
DECLARE @count AS INT = 1;

WHILE @count <= 100
BEGIN
	IF @count = 10
		BREAK;

	IF @count = 5
    BEGIN
		SET @count += 2;
		CONTINUE;
	END

	PRINT CAST(@count AS NVARCHAR);
	SET @count += 1;
END

/*====================================================================================================================

=========================================================================*/

WAITFOR DELAY '00:00:20';

WAITFOR TIME '23:46:00';

/*====================================================================================================================================================
GOTO
=========================================*/

PRINT 'First PRINT statement';
GOTO MyLabel;
PRINT 'Second PRINT statement';
MyLabel:
PRINT 'End';

/*====================================================================================================================================================

=========================================*/

IF OBJECT_ID('Production.InsertProducts', 'P') IS NOT NULL
DROP PROCEDURE Production.InsertProducts
GO

CREATE PROCEDURE Production.InsertProducts
     @productname AS NVARCHAR(40)
     , @supplierid AS INT
     , @categoryid AS INT
     , @unitprice AS MONEY = 0
     , @discontinued AS BIT = 0
AS
BEGIN
     BEGIN TRY
          SET NOCOUNT ON;
          INSERT Production.Products (productname, supplierid, categoryid, unitprice, discontinued)
          VALUES (@productname, @supplierid, @categoryid, @unitprice, @discontinued);
     END TRY
     BEGIN CATCH
          THROW;
          RETURN;
     END CATCH;
END;
GO

/*====================================================================================================================================================

=========================================*/
IF OBJECT_ID('Production.InsertProducts', 'P') IS NOT NULL
DROP PROCEDURE Production.InsertProducts
GO

CREATE PROCEDURE Production.InsertProducts
     @productname AS NVARCHAR(40)
     , @supplierid AS INT
     , @categoryid AS INT
     , @unitprice AS MONEY = 0
     , @discontinued AS BIT = 0
AS
BEGIN
     DECLARE @ClientMessage NVARCHAR(100);
     BEGIN TRY
          -- Test parameters
          IF NOT EXISTS(SELECT 1 FROM Production.Suppliers WHERE supplierid = @supplierid)
          BEGIN
               SET @ClientMessage = 'Supplier id '
               + CAST(@supplierid AS VARCHAR) + ' is invalid';
               THROW 50000, @ClientMessage, 0;
          END
          IF NOT EXISTS(SELECT 1 FROM Production.Categories WHERE categoryid = @categoryid)
          BEGIN
               SET @ClientMessage = 'Category id '
               + CAST(@categoryid AS VARCHAR) + ' is invalid';
               THROW 50000, @ClientMessage, 0;
          END;
          IF NOT(@unitprice >= 0)
          BEGIN
               SET @ClientMessage = 'Unitprice '
               + CAST(@unitprice AS VARCHAR) + ' is invalid. Must be >= 0.';
               THROW 50000, @ClientMessage, 0;
          END;
          -- Perform the insert
          INSERT Production.Products (productname, supplierid, categoryid, unitprice, discontinued)
          VALUES (@productname, @supplierid, @categoryid, @unitprice, @discontinued);
     END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO


EXEC Production.InsertProducts
@productname = 'Test Product'
, @supplierid = 100
, @categoryid = 1
, @unitprice = 100
, @discontinued = 0

EXEC Production.InsertProducts
@productname = 'Test Product'
, @supplierid = 10
, @categoryid = 1
, @unitprice = -100
, @discontinued = 0

go

--*********************************************************************************************************************************************************************

/*====================================================================================================================================================
Triggers
=========================================*/
IF OBJECT_ID('Sales.tr_SalesOrderDetailsDML', 'TR') IS NOT NULL
DROP TRIGGER Sales.tr_SalesOrderDetailsDML;
GO
CREATE TRIGGER Sales.tr_SalesOrderDetailsDML
     ON Sales.OrderDetails
AFTER DELETE, INSERT, UPDATE
AS
BEGIN
     IF @@ROWCOUNT = 0 RETURN; -- Must be 1st statement
     SET NOCOUNT ON;
     -- don't do it on real project
     SELECT COUNT(*) AS InsertedCount FROM Inserted;
     SELECT COUNT(*) AS DeletedCount FROM Deleted;
END;

-- show
BEGIN TRAN
     DELETE FROM Sales.OrderDetails
ROLLBACK TRAN

/*====================================================================================================================================================
Triggers
=========================================*/

IF OBJECT_ID('Production.tr_ProductionCategories_categoryname', 'TR') IS NOT NULL
DROP TRIGGER Production.tr_ProductionCategories_categoryname;
GO
CREATE TRIGGER Production.tr_ProductionCategories_categoryname
ON Production.Categories
AFTER INSERT, UPDATE
AS
BEGIN
     IF @@ROWCOUNT = 0 RETURN;
     DECLARE @ClientMessage NVARCHAR(100);
     SET NOCOUNT ON;
     IF EXISTS (
                    SELECT COUNT(*)
                    FROM Inserted AS I
                         JOIN Production.Categories AS C
                              ON I.categoryname = C.categoryname
                    GROUP BY I.categoryname
                    HAVING COUNT(*) > 1 
                    )	
     BEGIN
          SET @ClientMessage = 'Duplicate category names not allowed';
          THROW 50000, @ClientMessage , 0;
     END
END
GO
-- disable UC_Categories

-- try to
INSERT INTO Production.Categories (categoryname,description)
VALUES ('TestCategory1', 'Test1 description v1');

UPDATE Production.Categories
SET categoryname = 'Beverages' WHERE categoryname = 'TestCategory1';


DELETE FROM Production.Categories WHERE categoryname = 'TestCategory1';

/*====================================================================================================================================================
Nested AFTER Triggers
=========================================*/


EXEC sp_configure 'nested triggers';
EXEC sp_configure 'nested triggers', 0;

/*====================================================================================================================================================
INSTEAD OF Triggers
=========================================*/

IF OBJECT_ID('Production.tr_ProductionCategories_categoryname', 'TR') IS NOT NULL
DROP TRIGGER Production.tr_ProductionCategories_categoryname;
GO
CREATE TRIGGER Production.tr_ProductionCategories_categoryname
ON Production.Categories
INSTEAD OF INSERT

AS
BEGIN
     SET NOCOUNT ON;
     IF EXISTS (
                    SELECT COUNT(*)
                    FROM Inserted AS I
                         JOIN Production.Categories AS C
                              ON I.categoryname = C.categoryname
                    GROUP BY I.categoryname
                    HAVING COUNT(*) > 1
                    )
         BEGIN;
              THROW 50000, 'Duplicate category names not allowed', 0;
         END;
     ELSE

         INSERT Production.Categories (categoryname, description)
         SELECT categoryname, description FROM Inserted;
END;
GO
-- Cleanup
IF OBJECT_ID('Production.tr_ProductionCategories_categoryname', 'TR') IS NOT NULL
DROP TRIGGER Production.tr_ProductionCategories_categoryname;


--=======================================================================
-- Understanding Cursors
--=======================================================================
USE TSQL2012; 
 
IF OBJECT_ID('Sales.ProcessCustomer') IS NOT NULL   DROP PROC Sales.ProcessCustomer; 
GO 
 
CREATE PROC Sales.ProcessCustomer (   @custid AS INT ) 
AS  
PRINT 'Processing customer ' + CAST(@custid AS VARCHAR(10)); 
GO


--=======================================================================
-- Cursor
--=======================================================================
SET NOCOUNT ON; 
 
DECLARE @curcustid AS INT; 
 
DECLARE cust_cursor CURSOR FAST_FORWARD FOR   
SELECT custid   
FROM Sales.Customers;

OPEN cust_cursor; 
 
FETCH NEXT FROM cust_cursor INTO @curcustid; 
 
WHILE @@FETCH_STATUS = 0 
BEGIN   
    EXEC Sales.ProcessCustomer @custid = @curcustid; 
    FETCH NEXT FROM cust_cursor INTO @curcustid; 
END; 
 
CLOSE cust_cursor; 
 
DEALLOCATE cust_cursor; 
GO
 
--=======================================================================
-- another approach
--=======================================================================
SET NOCOUNT ON; 
 
DECLARE @curcustid AS INT; 
 
SET @curcustid = 
(
    SELECT TOP (1) custid
    FROM Sales.Customers
    ORDER BY custid
); 
 
WHILE @curcustid IS NOT NULL 
BEGIN   
	EXEC Sales.ProcessCustomer @custid = @curcustid;      
	SET @curcustid = 
	(
		SELECT TOP (1) custid                     
		FROM Sales.Customers                     
		WHERE custid > @curcustid                     
		ORDER BY custid
	); 
END; 
GO



--*********************************************************************************************************************************************************************

