/*=========================================
MSBI.DEV.COURSE.S21E09.SCRIPT
=========================================*/

USE TSQL2012;
GO

/*====================================================================================================================================================
--Dynamic SQL Overview
=========================================*/

--Drop all DB objects
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



--Getting row count of a particular table
SELECT COUNT(*) AS ProductRowCount FROM [Production].[Products];


DECLARE @tablename AS NVARCHAR(261) = N'[Production].[Products]';
PRINT N'SELECT COUNT(*) FROM ' + @tablename;
GO


DECLARE @tablename AS NVARCHAR(261) = N'[Production].[Products]';
EXECUTE (N'SELECT COUNT(*) AS TableRowCount FROM ' + @tablename);
GO

--The best practice: use metadata to get table rows count
SELECT a.name as 'SchemaName',o.name as 'TableName', i.rowcnt as 'RowCount'
FROM sys.schemas a, sys.objects o, sysindexes i
WHERE i.id=o.object_idAND a.schema_id=o.schema_idAND indid in(0,1)AND o.type='U'AND o.name <> 'sysdiagrams'
ORDER BY a.name desc

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

CREATE OR ALTER PROCEDURE Sales.ListCustomersByAddress
     @address NVARCHAR(60)
AS
     DECLARE @SQLString AS NVARCHAR(4000);
     SET @SQLString = '
		 SELECT companyname, contactname
		 FROM Sales.Customers
		 WHERE address = ''' + @address + '''';
     PRINT @SQLString;
     EXEC(@SQLString);
GO


EXEC Sales.ListCustomersByAddress @address = '8901 Tsawassen Blvd.';


EXEC Sales.ListCustomersByAddress @address = '''';


EXEC Sales.ListCustomersByAddress @address = 'x'' OR 1=1 --';


EXEC Sales.ListCustomersByAddress @address = '''; SELECT * FROM sys.tables  -- ';



USE TSQL2012;
GO
CREATE OR ALTER PROCEDURE Sales.ListCustomersByAddress
     @address AS NVARCHAR(60)
AS
DECLARE @SQLString AS NVARCHAR(4000);
     SET @SQLString = '
		 SELECT companyname, contactname
		 FROM Sales.Customers
		 WHERE address = @addr';
     EXEC sp_executesql
		@statment = @SQLString
		, @params = N'@addr NVARCHAR(60)'
		, @addr = @address;
GO


EXEC Sales.ListCustomersByAddress @address = '8901 Tsawassen Blvd.';
EXEC Sales.ListCustomersByAddress @address = '''';
EXEC Sales.ListCustomersByAddress @address = 'x'' OR 1=1 --';
EXEC Sales.ListCustomersByAddress @address = '''; SELECT * FROM sys.tables  -- ';


--Clean up
DROP PROCEDURE IF EXISTS Sales.ListCustomersByAddress;
GO

-- output parameter
DECLARE @SQLString AS NVARCHAR(4000)
	,@outercount AS int;
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

IF OBJECT_ID(N'Sales.GetCustomerOrders', N'P') IS NOT NULL
	DROP PROC Sales.GetCustomerOrders;
GO
CREATE PROC Sales.GetCustomerOrders
     @custid INT,
     @orderdatefrom DATETIME = '19000101',
     @orderdateto DATETIME = '99991231',
     @numrows INT = 0 OUTPUT
     
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
     @numrows = @rowsreturned OUTPUT;
SELECT @rowsreturned AS 'Rows Returned';
GO

--Typical mistake
DECLARE @rowsreturned AS INT;
EXEC Sales.GetCustomerOrders
     @custid = 37,
     @orderdatefrom = '20070401',
     @orderdateto = '20070701',
     @numrows = @rowsreturned;	--OUTPUT
SELECT @rowsreturned AS 'Rows Returned';
GO

--Clean up
DROP PROC IF EXISTS Sales.GetCustomerOrders;
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
     PRINT '@var1 equals @var2';
END
ELSE
     PRINT 'The variables are not equal';
     PRINT '@var1 does not equal @var2';
     PRINT '@var1 does not equal @var2';
GO

/*====================================================================================================================================================
WHILE
===================================================================================================================================================*/

DECLARE @count AS INT = 1;

WHILE  @count <= 10
BEGIN
	PRINT CAST(@count AS NVARCHAR);
    SET @count += 1;
END;

GO

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

GO
/*====================================================================================================================================================
Best Practices of Stored Procedures Developing
=========================================*/
CREATE OR ALTER PROCEDURE Production.usp_Products_Insert
     @productname NVARCHAR(40)
     , @supplierid INT
     , @categoryid INT
     , @unitprice MONEY = 0
     , @discontinued BIT = 0
	 , @productid INT = NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @ErrorMessage NVARCHAR(100);
	BEGIN TRY
		-- Test parameters
		IF NOT EXISTS(SELECT 1 FROM Production.Suppliers WHERE supplierid = @supplierid)
			SET @ErrorMessage = 'Supplier id ' + CAST(@supplierid AS VARCHAR) + ' is invalid';
		IF NOT EXISTS(SELECT 1 FROM Production.Categories WHERE categoryid = @categoryid)
			SET @ErrorMessage = 'Category id ' + CAST(@categoryid AS VARCHAR) + ' is invalid';
		IF NOT(@unitprice >= 0)
			SET @ErrorMessage = 'Unitprice ' + CAST(@unitprice AS VARCHAR) + ' is invalid. Must be >= 0.';
		-- Throw up error
		IF @ErrorMessage IS NOT NULL
			THROW 50000, @ErrorMessage, 0;

		-- Perform the insert
		BEGIN TRAN	--If more than one statememnt
			INSERT Production.Products (productname, supplierid, categoryid, unitprice, discontinued)
			VALUES (@productname, @supplierid, @categoryid, @unitprice, @discontinued);
			--SPs for inserting new records should return new IDs
			SET @productid = SCOPE_IDENTITY();
		COMMIT TRAN;
	END TRY
    BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN;
        THROW;
    END CATCH;
END;
GO

DECLARE @productid INT;
EXEC Production.usp_Products_Insert
	@productname = 'Test Product'
	, @supplierid = 10
	, @categoryid = 1
	, @unitprice = 100
	, @discontinued = 0
	, @productid = @productid OUTPUT;
SELECT @productid;

DELETE Production.Products
WHERE productid = @productid
GO

DECLARE @productid INT;
EXEC Production.usp_Products_Insert
	@productname = 'Test Product'
	, @supplierid = 100
	, @categoryid = 1
	, @unitprice = 100
	, @discontinued = 0
	, @productid = @productid OUTPUT;
SELECT @productid;
GO

DECLARE @productid INT;
EXEC Production.usp_Products_Insert
	@productname = 'Test Product'
	, @supplierid = 10
	, @categoryid = 1
	, @unitprice = -100
	, @discontinued = 0
	, @productid = @productid OUTPUT;
SELECT @productid;
GO

DROP PROCEDURE IF EXISTS Production.usp_Products_Insert;
GO
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

DROP TRIGGER IF EXISTS Sales.tr_SalesOrderDetailsDML;
GO
/*====================================================================================================================================================
Triggers
=========================================*/

CREATE OR ALTER TRIGGER Production.tr_ProductionCategories_categoryname
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
GO

/*====================================================================================================================================================
INSTEAD OF Triggers
=========================================*/

CREATE OR ALTER TRIGGER Production.tr_ProductionCategories_categoryname
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
DROP TRIGGER IF EXISTS Production.tr_ProductionCategories_categoryname;
GO

--=======================================================================
-- Understanding Cursors
--=======================================================================
CREATE OR ALTER PROC Sales.ProcessCustomer (   @custid AS INT ) 
AS  
	PRINT 'Processing customer ' + CAST(@custid AS VARCHAR(10)); 
GO

SELECT * FROM Sales.Customers;

--=======================================================================
-- Cursor
--=======================================================================

--Turn off Execution plan
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

DROP PROC IF EXISTS Sales.ProcessCustomer;
--*********************************************************************************************************************************************************************

