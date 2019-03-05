/*=========================================
MSBI.DEV.COURSE.S19E10.SCRIPT
=========================================*/


-- few words about batch
USE TSQL2012;
GO
DECLARE @MyMsg VARCHAR(50);
SELECT @MyMsg = 'Hello, World.'
--GO -- @MyMsg is not valid after this GO ends the batch.


--https://docs.microsoft.com/en-us/sql/t-sql/language-elements/sql-server-utilities-statements-go
-- Yields an error because @MyMsg not declared in this batch.
PRINT @MyMsg
GO
sp_who
SELECT @@VERSION;
-- Yields an error: Must be EXEC sp_who if not first statement in 
-- batch.
go -- comment it
sp_who
GO
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

USE AdventureWorks2014
GO

-- Part1. Populate by single row through SET
DECLARE @Var1ForSet varchar(50)
SET @Var1ForSet = (SELECT [Name] FROM Production.Product WHERE ProductNumber = 'HY-1023-70')
PRINT @Var1ForSet
GO

-- Part 2. Populate by multiple rows through SET
DECLARE @Var2ForSet varchar(50)
SET @Var2ForSet = (SELECT [Name] FROM Production.Product WHERE Color = 'Silver')
PRINT @Var2ForSet
GO
-- Part2. Populate by multiple rows through SELECT
DECLARE @Var2ForSelect varchar(50)
SELECT @Var2ForSelect = [Name] FROM Production.Product WHERE Color = 'Silver'
PRINT @Var2ForSelect
GO

-- Part2. Populate by multiple rows through SELECT
DECLARE @Var2ForSelect varchar(MAX)
SELECT @Var2ForSelect = COALESCE(@Var2ForSelect + ', ', '') + Name FROM Production.Product 
PRINT @Var2ForSelect
GO
-- provide with opposite task


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

--exec sp_executesql @stmt


/*====================================================================================================================================================
--Dynamic SQL Overview
=========================================*/
USE TSQL2012;
GO
SELECT COUNT(*) AS ProductRowCount FROM [Production].[Products];

SELECT a.name as 'SchemaName',o.name as 'TableName', i.rowcnt as 'RowCount'FROM 
    sys.schemas a, sys.objects o, sysindexes iWHERE i.id=o.object_idAND a.schema_id=o.schema_idAND indid in(0,1)AND o.type='U'AND o.name <> 'sysdiagrams'
    --AND a.name in ('EEDM','APACHE','ER','GIL','GOMEZ','SUMMARY','SCOM')
    ORDER BY a.name desc


USE TSQL2012;
GO
DECLARE @tablename AS NVARCHAR(261) = N'[Production].[Products]';
PRINT N'SELECT COUNT(*) FROM ' + @tablename;
-- provide with task for count in all tables

DECLARE @tablename AS NVARCHAR(261) = N'[Production].[Products]';
SELECT N'SELECT COUNT(*) FROM ' + @tablename;

DECLARE @tablename AS NVARCHAR(261) = N'[Production].[Products]';

EXECUTE (N'SELECT COUNT(*) AS TableRowCount FROM ' + @tablename);
/*====================================================================================================================================================
single quotation marks PROBLEM
=========================================*/
USE TSQL2012;
GO
--try
/*
SELECT custid, companyname, contactname, contacttitle, addressFROM [Sales].[Customers]
WHERE address = N'5678 rue de l'Abbaye';
*/

SELECT custid, companyname, contactname, contacttitle, [address] FROM [Sales].[Customers]
WHERE address = N'5678 rue de l''Abbaye';
GO
-- getting worse
PRINT N'SELECT custid, companyname, contactname, contacttitle, address
FROM [Sales].[Customers]
WHERE address = N''5678 rue de l''''Abbaye'';';



USE TSQL2012;
GO
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
EXEC
=========================================*/
USE TSQL2012;
GO
DECLARE 
     @SQLString AS NVARCHAR(4000)
     , @tablename AS NVARCHAR(261) = 
                                        '[Production].[Products]';
                                        SET @SQLString = 'SELECT COUNT(*) AS TableRowCount FROM ' + @tablename;
EXECUTE(@SQLString);

USE TSQL2012;
GO
DECLARE @SQLString AS NVARCHAR(MAX)
, @tablename AS NVARCHAR(261) = '[Production].[Products]';
SET @SQLString = 'SELECT COUNT(*) AS TableRowCount FROM '
EXEC(@SQLString + @tablename);

/*====================================================================================================================================================
SQL Injection
=========================================*/

USE TSQL2012;
GO
DECLARE 
     @SQLString AS NVARCHAR(4000)
     , @tablename AS NVARCHAR(261) = 
                                        '[Production].[Products]';
                                        SET @SQLString = 'SELECT COUNT(*) FROM ' + @tablename;							--[1]
                                        
                                   
EXEC(@SQLString);
/*====================================================================================================================================================
Using sp_executesql
=========================================*/
USE TSQL2012;
GO
DECLARE @SQLString AS NVARCHAR(4000), @address AS NVARCHAR(60);
SET @SQLString = N'
          SELECT custid, companyname, contactname, contacttitle, address
          FROM [Sales].[Customers]
          WHERE address = @address';
SET @address = N'5678 rue de l''Abbaye';
EXEC sp_executesql
          @statement = @SQLString
          , @params = N'@address NVARCHAR(60)'
          , @address = @address;

/*====================================================================================================================================================
prevent code injection

========================================*/

USE TSQL2012;
GO
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
     --PRINT @SQLString;
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
EXEC Sales.ListCustomersByAddress @address = ''' -- SELCT 1 ';


USE TSQL2012;
GO
EXEC Sales.ListCustomersByAddress @address = ''' SELECT 1  -- ';



USE TSQL2012;
GO
IF OBJECT_ID('Sales.ListCustomersByAddress') IS NOT NULL
     DROP PROCEDURE Sales.ListCustomersByAddress;
GO
CREATE PROCEDURE Sales.ListCustomersByAddress
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
EXEC Sales.ListCustomersByAddress @address = '''';
EXEC Sales.ListCustomersByAddress @address = ''' -- ';
EXEC Sales.ListCustomersByAddress @address = ''' SELECT 1 -- ';


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

DECLARE @IntVariable int;
DECLARE @SQLString nvarchar(500);
DECLARE @ParmDefinition nvarchar(500);
DECLARE @max_title varchar(30);

SET @IntVariable = 197;
SET @SQLString = N'SELECT @max_titleOUT = max(JobTitle) 
   FROM AdventureWorks2014.HumanResources.Employee
   WHERE BusinessEntityID = @level';
SET @ParmDefinition = N'@level tinyint, @max_titleOUT varchar(30) OUTPUT';

EXECUTE sp_executesql @SQLString, @ParmDefinition, @level = @IntVariable, @max_titleOUT=@max_title OUTPUT;
SELECT @max_title;



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


IF OBJECT_ID('Sales.GetCustomerOrders', 'P') IS NOT NULL
DROP PROC Sales.GetCustomerOrders;
GO
CREATE PROC Sales.GetCustomerOrders
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

EXEC Sales.GetCustomerOrders 37, '20070401', '20070701', 0;

EXEC Sales.GetCustomerOrders @custid = 37, @orderdatefrom = '20070401', @orderdateto = '20070701';

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
IF/ELSE
=========================================*/

DECLARE @var1 AS INT, @var2 AS INT;
SET @var1 = 1;
SET @var2 = 1;

IF @var1 = @var2
    BEGIN
        PRINT 'The variables are equal';
    END
ELSE
    BEGIN
        PRINT 'The variables are not equal';

    END
GO
-- without begin end

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


--*********************************************************************************************************************************************************************

/*====================================================================================================================================================

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
SELECT Orderid, unitprice, qty, Sales.fn_extension(unitprice, qty) AS extension
FROM Sales.OrderDetails;

-- also UDFs can be used in this way
SELECT Orderid, unitprice, qty, Sales.fn_extension(unitprice, qty) AS extension
FROM Sales.OrderDetails
WHERE Sales.fn_extension(unitprice, qty) > 1000;

SELECT Orderid, unitprice, qty, unitprice* qty AS extension
FROM Sales.OrderDetails
WHERE unitprice* qty > 1000;


/*====================================================================================================================================================
Inline Table-Valued UDF

=========================================*/

IF OBJECT_ID('Sales.fn_FilteredExtension', 'IF') IS NOT NULL
DROP FUNCTION Sales.fn_FilteredExtension;
GO
CREATE FUNCTION Sales.fn_FilteredExtension
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

-- calling

SELECT orderid, unitprice, qty
FROM Sales.fn_FilteredExtension (10,20);
/*====================================================================================================================================================
Multistatement Table-Valued UDF

=========================================*/
IF OBJECT_ID('Sales.fn_FilteredExtension2', 'TF') IS NOT NULL
DROP FUNCTION Sales.fn_FilteredExtension2;
GO
CREATE FUNCTION Sales.fn_FilteredExtension2
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
-- review 
SET STATISTICS TIME ON;

SELECT orderid, unitprice, qty
FROM Sales.fn_FilteredExtension2 (10,20);

SELECT orderid, unitprice, qty
FROM Sales.fn_FilteredExtension (10,20);



SET STATISTICS TIME OFF;


/*====================================================================================================================================================

=========================================*/


/*=========================================

=========================================*/


/*=========================================

=========================================*/
