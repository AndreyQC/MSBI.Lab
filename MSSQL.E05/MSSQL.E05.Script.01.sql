/*=========================================
MSSQL.E05.Script.01.sql
=========================================*/

USE [TSQL2012];
GO

/*=========================================
Working with variables
=========================================*/

DECLARE
	@x INT,
	@y INT = 2;

SET @y = 4;

SELECT @x, @y;

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

--Multiple variables

--Not the best approach
DECLARE
	@ProductId INT = -1,
	@CategoryId INT = -1;

SET @ProductId	= (SELECT productid FROM [Production].[Products] WHERE [productname] = N'Product HHYDP');
SET @CategoryId	= (SELECT categoryid FROM [Production].[Products] WHERE [productname] = N'Product HHYDP');

SELECT @ProductId, @CategoryId;
GO

--Good
DECLARE
	@ProductId INT = -1,
	@CategoryId INT = -1;

SELECT
	@ProductId	= productid,
	@CategoryId = categoryid
FROM [Production].[Products]
WHERE [productname] = N'Product HHYDP';

SELECT @ProductId, @CategoryId;
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


-- Try to populate by empty result set
DECLARE @ProductId INT = -1;
SET @ProductId	= (SELECT productid FROM [Production].[Products] WHERE [productname] = N'Product ABC');

SELECT @ProductId;
GO

DECLARE @ProductId INT = -1;
SELECT @ProductId	= productid FROM [Production].[Products] WHERE [productname] = N'Product ABC';

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

--Alternate approach (SQL 2017)
SELECT
	STRING_AGG([productname], N',')
FROM
	[Production].[Products]
;

--Alternate approach (before SQL 2017)
SELECT
	[productname] + N',' AS 'data()'
FROM
	[Production].[Products]
ORDER BY
	[productname]
FOR XML PATH ('')
;



/*=========================================
Inserting Data
=========================================*/


/*=========================================
Prepare sample data
=========================================*/


----------------drop table---------------------------
USE TSQL2012;

DROP TABLE IF EXISTS Sales.MyOrders;
GO
----------------create table---------------------------
CREATE TABLE Sales.MyOrders
(
	orderid INT NOT NULL IDENTITY(1, 1)	CONSTRAINT PK_MyOrders_orderid PRIMARY KEY,
	custid INT NOT NULL,
	empid INT NOT NULL,
	orderdate DATE NOT NULL CONSTRAINT DF_MyOrders_orderdate DEFAULT (CAST(GETDATE() AS DATE)),
	shipcountry NVARCHAR(15) NOT NULL,
	freight MONEY NOT NULL
);

SELECT * FROM Sales.MyOrders;

/*=========================================
INSERT VALUES
=========================================*/
INSERT 
    INTO Sales.MyOrders
    (custid, empid, orderdate, shipcountry, freight)
VALUES  (2, 19, '20120620', N'USA', 30.00);

-- will fail
INSERT 
    INTO Sales.MyOrders
    (orderid, custid, empid, orderdate, shipcountry, freight)
VALUES  (2, 2, 19, '20120620', N'USA', 30.00);

SET IDENTITY_INSERT Sales.MyOrders ON;
INSERT 
    INTO Sales.MyOrders
    (orderid, custid, empid, orderdate, shipcountry, freight)
VALUES  (2, 2, 19, '20120620', N'USA', 30.00);
SET IDENTITY_INSERT Sales.MyOrders OFF;

SELECT * FROM Sales.MyOrders;

/*=========================================
INSERT VALUES Server uses the default expression for orderdate
=========================================*/
INSERT INTO Sales.MyOrders(custid, empid, shipcountry, freight)
VALUES(3, 11, N'USA', 10.00);

-- or use default key word
INSERT INTO Sales.MyOrders(custid, empid, orderdate, shipcountry, freight)
VALUES(3, 17, DEFAULT, N'RUS', 30.00);

SELECT * FROM Sales.MyOrders;

/*=========================================
The INSERT VALUES with multiple rows
=========================================*/
INSERT 
    INTO Sales.MyOrders (custid, empid, orderdate, shipcountry, freight)
 VALUES
    (2, 11, '20120620', N'USA', 50.00),
    (5, 13, '20120620', N'USA', 40.00),
    (7, 17, '20120620', N'USA', 45.00);

SELECT *
FROM Sales.MyOrders;

--**************************************************************************************************************
--INSERT SELECT
--**************************************************************************************************************
SET IDENTITY_INSERT Sales.MyOrders ON;

INSERT 
    INTO Sales.MyOrders(orderid, custid, empid, orderdate, shipcountry, freight)
SELECT orderid, custid, empid, orderdate, shipcountry, freight
    FROM Sales.Orders
    WHERE shipcountry = N'Norway';

SET IDENTITY_INSERT Sales.MyOrders OFF;


SELECT *
FROM Sales.MyOrders;


INSERT INTO Sales.MyOrders(custid, empid, shipcountry, freight)
VALUES(3, 11, N'USA', 10.00);



--ROWCOUNT
DECLARE @RC INT;

INSERT 
    INTO Sales.MyOrders(custid, empid, orderdate, shipcountry, freight)
SELECT custid, empid, orderdate, shipcountry, freight
    FROM Sales.Orders
    WHERE shipcountry = N'Brazil';

SET @RC = @@ROWCOUNT;
SELECT @RC;


--**************************************************************************************************************
--INSERT EXEC
--**************************************************************************************************************




/*=========================================
create SP
=========================================*/
IF OBJECT_ID('Sales.usp_OrdersForCountry', 'P') IS NOT NULL
DROP PROC Sales.usp_OrdersForCountry;
GO
CREATE PROC Sales.usp_OrdersForCountry
@country AS NVARCHAR(15)
AS
    SELECT  orderid, custid, empid, orderdate, shipcountry, freight
    FROM Sales.Orders
    WHERE shipcountry = @country;
GO

EXEC Sales.usp_OrdersForCountry N'Portugal';


SET IDENTITY_INSERT Sales.MyOrders ON;

INSERT 
	INTO Sales.MyOrders(orderid, custid, empid, orderdate, shipcountry, freight)
EXEC Sales.usp_OrdersForCountry
		@country = N'Portugal';

SET IDENTITY_INSERT Sales.MyOrders OFF;


SELECT *
FROM Sales.MyOrders;


GO
/*=========================================
 wrong SP
=========================================*/
CREATE OR ALTER PROC Sales.usp_OrdersForCountry
@country AS NVARCHAR(15)
AS
    SELECT  'sdsd' col12, orderid, custid, empid, orderdate, shipcountry, freight
    FROM Sales.Orders
    WHERE shipcountry = @country;
GO
/*=========================================

=========================================*/

EXEC Sales.usp_OrdersForCountry N'Portugal';


SET IDENTITY_INSERT Sales.MyOrders ON;

INSERT 
	INTO Sales.MyOrders(orderid, custid, empid, orderdate, shipcountry, freight)
EXEC Sales.usp_OrdersForCountry
		@country = N'Portugal';

SET IDENTITY_INSERT Sales.MyOrders OFF;


DROP PROC IF EXISTS Sales.usp_OrdersForCountry;

--**************************************************************************************************************
--SELECT INTO
--**************************************************************************************************************

DROP TABLE IF EXISTS Sales.MyOrders;

SELECT 
    orderid,
    custid,
    orderdate,
    shipcountry,
    freight
INTO Sales.MyOrders
FROM Sales.Orders
WHERE shipcountry = N'Norway';

SELECT *
FROM Sales.MyOrders;

/*=========================================
to control datatypes in created table
=========================================*/

DROP TABLE IF EXISTS Sales.MyOrders;

SELECT
    orderid + 0 AS orderid,					-- get rid of IDENTITY property
    ISNULL(custid, -1) AS custid,			-- make column NOT NULL
    empid,
    CAST(orderdate AS DATE) AS orderdate,	-- change data type
    shipcountry,
	freight
INTO Sales.MyOrders
FROM Sales.Orders
WHERE shipcountry = N'Norway';



DROP TABLE IF EXISTS Sales.MyOrders;

SELECT
    ISNULL(orderid + 0, -1) AS orderid, -- get rid of IDENTITY property
    ISNULL(custid, -1) AS custid,		-- make column NOT NULL
    empid,
    ISNULL(CAST(orderdate AS DATE), '19000101') AS orderdate, -- change data type
    shipcountry, freight
INTO Sales.MyOrders
FROM Sales.Orders
WHERE shipcountry = N'Norway';

/*=========================================
add constraint if it needs
SELECT INTO does not copy constraints from the source table,
=========================================*/
ALTER TABLE Sales.MyOrders
	ADD CONSTRAINT PK_MyOrders PRIMARY KEY(orderid);


/*=========================================
clean up
=========================================*/
DROP TABLE IF EXISTS Sales.MyOrders;



--**************************************************************************************************************
--UPDATE
--**************************************************************************************************************

/*=========================================
prepare Sample Data
=========================================*/
IF OBJECT_ID('Sales.MyOrderDetails', 'U') IS NOT NULL
	DROP TABLE Sales.MyOrderDetails;

IF OBJECT_ID('Sales.MyOrders', 'U') IS NOT NULL
	DROP TABLE Sales.MyOrders;

IF OBJECT_ID('Sales.MyCustomers', 'U') IS NOT NULL
	DROP TABLE Sales.MyCustomers;

SELECT * INTO Sales.MyCustomers FROM Sales.Customers;

ALTER TABLE Sales.MyCustomers
	ADD CONSTRAINT PK_MyCustomers PRIMARY KEY(custid);

SELECT * INTO Sales.MyOrders FROM Sales.Orders;

ALTER TABLE Sales.MyOrders
	ADD CONSTRAINT PK_MyOrders PRIMARY KEY(orderid);

SELECT * INTO Sales.MyOrderDetails FROM Sales.OrderDetails;

ALTER TABLE Sales.MyOrderDetails
	ADD CONSTRAINT PK_MyOrderDetails PRIMARY KEY(orderid, productid);


/*=========================================

=========================================*/

SELECT *
FROM Sales.MyOrderDetails
WHERE orderid = 10251;

/*=========================================
first update
=========================================*/
UPDATE Sales.MyOrderDetails
SET discount += 0.05
WHERE orderid = 10251;

SELECT *
FROM Sales.MyOrderDetails
WHERE orderid = 10251;

/*=========================================
roll back changes
=========================================*/
UPDATE Sales.MyOrderDetails
SET discount -= 0.05
WHERE orderid = 10251;


/*=========================================
using update with join
=========================================*/

SELECT OD.*
FROM Sales.MyCustomers AS C
    INNER JOIN Sales.MyOrders AS O
        ON C.custid = O.custid
    INNER JOIN Sales.MyOrderDetails AS OD
        ON O.orderid = OD.orderid
WHERE C.country = N'Norway';
-- OD (16 rows affected)



UPDATE OD
SET OD.discount += 0.05
FROM Sales.MyCustomers AS C
    INNER JOIN Sales.MyOrders AS O
       ON C.custid = O.custid
    INNER JOIN Sales.MyOrderDetails AS OD
        ON O.orderid = OD.orderid
WHERE C.country = N'Norway';

-- review result
SELECT OD.*
FROM Sales.MyCustomers AS C
    INNER JOIN Sales.MyOrders AS O
         ON C.custid = O.custid
    INNER JOIN Sales.MyOrderDetails AS OD
         ON O.orderid = OD.orderid
WHERE C.country = N'Norway';


-- experiment

SELECT C.*
FROM Sales.MyCustomers AS C
    INNER JOIN Sales.MyOrders AS O
       ON C.custid = O.custid
    INNER JOIN Sales.MyOrderDetails AS OD
        ON O.orderid = OD.orderid
WHERE C.country = N'Norway';


UPDATE C
SET [address]=N'Erling Skakkes gate 2345'
FROM Sales.MyCustomers AS C
    INNER JOIN Sales.MyOrders AS O
       ON C.custid = O.custid
    INNER JOIN Sales.MyOrderDetails AS OD
       ON O.orderid = OD.orderid
WHERE C.country = N'Norway';



/*=========================================
Nondeterministic UPDATE
=========================================*/
-- let's take a look
SELECT C.custid,
    C.postalcode,
    O.shippostalcode
FROM Sales.MyCustomers AS C
    INNER JOIN Sales.MyOrders AS O
       ON C.custid = O.custid
ORDER BY C.custid;


-- let's update
UPDATE C
SET C.postalcode = O.shippostalcode
	FROM Sales.MyCustomers AS C
		INNER JOIN Sales.MyOrders AS O
			ON C.custid = O.custid;

-- check update
SELECT custid, postalcode
FROM Sales.MyCustomers
ORDER BY custid;

-- use determenistic

UPDATE C
SET C.postalcode = A.shippostalcode
FROM Sales.MyCustomers AS C
    CROSS APPLY (
                    SELECT TOP (1) O.shippostalcode
                    FROM Sales.MyOrders AS O
                    WHERE O.custid = C.custid
                    ORDER BY orderdate, orderid
                ) AS A



/*=========================================
--Prevent redundant update
=========================================*/

UPDATE TGT
	SET TGT.country = SRC.country,
		TGT.postalcode = SRC.postalcode
FROM Sales.MyCustomers AS TGT
	INNER JOIN Sales.Customers AS SRC
		ON TGT.custid = SRC.custid
WHERE
	TGT.country <> SRC.country
	OR TGT.postalcode <> SRC.postalcode
	--OR (TGT.postalcode IS NULL		AND SRC.postalcode IS NOT NULL)
	--OR (TGT.postalcode IS NOT NULL	AND SRC.postalcode IS NULL)
;



/*=========================================
All at once
=========================================*/

DROP TABLE IF EXISTS dbo.T1;
CREATE TABLE dbo.T1
(
	keycol INT NOT NULL	CONSTRAINT PK_T1 PRIMARY KEY,
	col1 INT NOT NULL,
	col2 INT NOT NULL
);
INSERT INTO dbo.T1(keycol, col1, col2) VALUES(1, 100, 0);

DECLARE @add AS INT = 10;

UPDATE dbo.T1
	SET 
		col1 += @add,
		col2 = col1
WHERE keycol = 1;

SELECT * FROM dbo.T1;

--clean up
DROP TABLE IF EXISTS dbo.T1;


--**************************************************************************************************************
--DELETE
--**************************************************************************************************************

/*=========================================
Sample Data
=========================================*/
IF OBJECT_ID('Sales.MyOrderDetails', 'U') IS NOT NULL
	DROP TABLE Sales.MyOrderDetails;
IF OBJECT_ID('Sales.MyOrders', 'U') IS NOT NULL
	DROP TABLE Sales.MyOrders;
IF OBJECT_ID('Sales.MyCustomers', 'U') IS NOT NULL
	DROP TABLE Sales.MyCustomers;

SELECT * INTO Sales.MyCustomers FROM Sales.Customers;

ALTER TABLE Sales.MyCustomers
	ADD CONSTRAINT PK_MyCustomers PRIMARY KEY(custid);

SELECT * INTO Sales.MyOrders FROM Sales.Orders;

ALTER TABLE Sales.MyOrders
	ADD CONSTRAINT PK_MyOrders PRIMARY KEY(orderid);

SELECT * INTO Sales.MyOrderDetails FROM Sales.OrderDetails;

ALTER TABLE Sales.MyOrderDetails
	ADD CONSTRAINT PK_MyOrderDetails PRIMARY KEY(orderid, productid);


/*=========================================

=========================================*/
SELECT * FROM Sales.MyOrderDetails
WHERE productid = 11;

DELETE FROM Sales.MyOrderDetails
WHERE productid = 11;

SELECT * FROM Sales.MyOrderDetails
WHERE productid = 11;

/*=========================================
delete is very log expensive command
here is a variant  with chunks.
=========================================*/
WHILE 1 = 1
BEGIN
	DELETE TOP (5) FROM Sales.MyOrderDetails
	WHERE productid = 12;
    -- PRINT  ' iteration'
	IF @@ROWCOUNT < 5 BREAK;
     
END

/*=========================================
DELETE Using Table Expressions
=========================================*/

WITH OldestOrders AS
(
	SELECT TOP (100) *
	FROM Sales.MyOrders
	ORDER BY orderdate, orderid
)
DELETE FROM OldestOrders;


/*=========================================
DELETE Based on a Join
=========================================*/

SELECT *  FROM Sales.MyOrders;

DELETE FROM O
FROM Sales.MyOrders AS O
	INNER JOIN Sales.MyCustomers AS C
		ON O.custid = C.custid
WHERE C.country = N'USA';


-- another version
DELETE FROM Sales.MyOrders
WHERE EXISTS
			(
				SELECT *
				FROM Sales.MyCustomers
				WHERE MyCustomers.custid = MyOrders.custid
				AND MyCustomers.country = N'USA'
			);



/*=========================================
Clean up
=========================================*/

IF OBJECT_ID('Sales.MyOrderDetails', 'U') IS NOT NULL
	DROP TABLE Sales.MyOrderDetails;
IF OBJECT_ID('Sales.MyOrders', 'U') IS NOT NULL
	DROP TABLE Sales.MyOrders;
IF OBJECT_ID('Sales.MyCustomers', 'U') IS NOT NULL
	DROP TABLE Sales.MyCustomers;




--**************************************************************************************************************
--Other Data Modification Aspects
--**************************************************************************************************************


/*=========================================
Using the IDENTITY Column Property
=========================================*/

USE TSQL2012;
DROP TABLE IF EXISTS Sales.MyOrders;
GO
CREATE TABLE Sales.MyOrders
(
	orderid INT NOT NULL IDENTITY(1, 1)	CONSTRAINT PK_MyOrders_orderid PRIMARY KEY,
	custid INT NOT NULL					CONSTRAINT CHK_MyOrders_custid CHECK(custid > 0),
	empid INT NOT NULL					CONSTRAINT CHK_MyOrders_empid CHECK(empid > 0),
	orderdate DATE NOT NULL
);

INSERT 
	INTO Sales.MyOrders(custid, empid, orderdate)
VALUES
		(1, 2, '20120620'),
		(1, 3, '20120620'),
		(2, 2, '20120620');

SELECT * FROM Sales.MyOrders;

/*=========================================
how to get identity value
=========================================*/
SELECT
	SCOPE_IDENTITY()				AS [SCOPE_IDENTITY],
	@@IDENTITY						AS [@@IDENTITY],
	IDENT_CURRENT('Sales.MyOrders')	AS [IDENT_CURRENT];

--Check identity value after delete
DELETE FROM Sales.MyOrders;
SELECT IDENT_CURRENT('Sales.MyOrders') AS [IDENT_CURRENT];
go

TRUNCATE TABLE Sales.MyOrders;
SELECT IDENT_CURRENT('Sales.MyOrders') AS [IDENT_CURRENT];

--reseed
DBCC CHECKIDENT('Sales.MyOrders', RESEED, 4);


--
INSERT 
	INTO Sales.MyOrders(custid, empid, orderdate) 
VALUES(2, 2, '20120620');
SELECT * FROM Sales.MyOrders;

-- potentional gaps
INSERT 
	INTO Sales.MyOrders(custid, empid, orderdate) 
VALUES(3, -1, '20120620');
-- this break constraint but identity is used

INSERT 
	INTO Sales.MyOrders(custid, empid, orderdate) 
VALUES(3, 1, '20120620');
--This time, the insertion succeeds. Query the table.
SELECT * FROM Sales.MyOrders;





/*=========================================
Using the Sequence Object
=========================================*/

DROP SEQUENCE IF EXISTS [Sales].[SeqOrderIDs]
GO

CREATE SEQUENCE Sales.SeqOrderIDs AS INT
MINVALUE 1
CYCLE;


SELECT NEXT VALUE FOR Sales.SeqOrderIDs;


ALTER SEQUENCE Sales.SeqOrderIDs
RESTART WITH 1;


IF OBJECT_ID('Sales.MyOrders') IS NOT NULL DROP TABLE Sales.MyOrders;
GO
CREATE TABLE Sales.MyOrders
(
	orderid INT NOT NULL	CONSTRAINT PK_MyOrders_orderid PRIMARY KEY,
	custid INT NOT NULL		CONSTRAINT CK_MyOrders_custid CHECK(custid > 0),
	empid INT NOT NULL		CONSTRAINT CK_MyOrders_empid CHECK(empid > 0),
	orderdate DATE NOT NULL
);

INSERT 
	INTO Sales.MyOrders(orderid, custid, empid, orderdate) 
	VALUES
		(NEXT VALUE FOR Sales.SeqOrderIDs, 1, 2, '20120620'),
		(NEXT VALUE FOR Sales.SeqOrderIDs, 1, 3, '20120620'),
		(NEXT VALUE FOR Sales.SeqOrderIDs, 2, 2, '20120620');


SELECT * FROM Sales.MyOrders;

-- insert select
INSERT 
	INTO Sales.MyOrders(orderid, custid, empid, orderdate)
SELECT
	NEXT VALUE FOR Sales.SeqOrderIDs OVER(ORDER BY orderid),
	custid,
	empid,
	orderdate
FROM Sales.Orders
WHERE custid = 1;


INSERT 
	INTO Sales.MyOrders( custid, empid, orderdate) 
	VALUES
		( 1, 2, '20180303'),
		( 1, 3, '20180303'),
		( 2, 2, '20180303')


-- add as a constraint
ALTER TABLE Sales.MyOrders
	ADD CONSTRAINT DF_MyOrders_orderid
	DEFAULT(NEXT VALUE FOR Sales.SeqOrderIDs) FOR orderid;

INSERT INTO Sales.MyOrders(custid, empid, orderdate)
SELECT
	custid,
	empid,
	orderdate
FROM Sales.Orders
WHERE custid = 2;
-- review 
SELECT * FROM Sales.MyOrders;


/*=========================================
Merging Data

=========================================*/

/*=========================================
Prepare data
=========================================*/
DROP TABLE IF EXISTS Sales.MyOrders;
DROP SEQUENCE IF EXISTS Sales.SeqOrderIDs;
CREATE SEQUENCE Sales.SeqOrderIDs AS INT
MINVALUE 1
CYCLE;
CREATE TABLE Sales.MyOrders
(
	orderid INT NOT NULL
		CONSTRAINT PK_MyOrders_orderid PRIMARY KEY
		CONSTRAINT DF_MyOrders_orderid DEFAULT(NEXT VALUE FOR Sales.SeqOrderIDs),
	custid INT NOT NULL
		CONSTRAINT CK_MyOrders_custid CHECK(custid > 0),
	empid INT NOT NULL
		CONSTRAINT CK_MyOrders_empid CHECK(empid > 0),
	orderdate DATE NOT NULL
);

DECLARE
	@orderid AS INT = 1,
	@custid AS INT = 2,
	@empid AS INT = 2,
	@orderdate AS DATE = '20120620';

MERGE INTO Sales.MyOrders WITH (HOLDLOCK) AS TGT  -- explain why  HOLDLOCK - two process P1 and P2 run at the same time
USING (VALUES(@orderid, @custid, @empid, @orderdate))
	AS SRC(orderid, custid, empid, orderdate)
	ON SRC.orderid = TGT.orderid
WHEN MATCHED THEN UPDATE
	SET TGT.custid = SRC.custid,
	TGT.empid = SRC.empid,
	TGT.orderdate = SRC.orderdate
WHEN NOT MATCHED THEN INSERT (orderid, custid, empid, orderdate)
	VALUES(SRC.orderid, SRC.custid, SRC.empid, SRC.orderdate);

SELECT * FROM Sales.MyOrders;

GO
-- to prevent redundant update
DECLARE
	@orderid AS INT = 1,
	@custid AS INT = 1,
	@empid AS INT = 2,
	@orderdate AS DATE = '20120620';
MERGE INTO Sales.MyOrders WITH (HOLDLOCK) AS TGT
USING (VALUES(@orderid, @custid, @empid, @orderdate))
	AS SRC( orderid, custid, empid, orderdate)
	ON SRC.orderid = TGT.orderid
WHEN MATCHED 
	AND ( TGT.custid <> SRC.custid
	OR TGT.empid <> SRC.empid
	OR TGT.orderdate <> SRC.orderdate) 
		THEN UPDATE
		SET TGT.custid = SRC.custid,
			TGT.empid = SRC.empid,
			TGT.orderdate = SRC.orderdate
WHEN NOT MATCHED 
		THEN INSERT (orderid, custid, empid, orderdate)
		VALUES(SRC.orderid, SRC.custid, SRC.empid, SRC.orderdate);

-- remember about NULL
/*
TGT.custid <> SRC.custid
OR (TGT.custid IS NULL AND SRC.custid IS NOT NULL)
OR (TGT.custid IS NOT NULL AND SRC.custid IS NULL)
*/

-- additional to merge in T-SQL WHEN NOT MATCHED BY SOURCE THEN
DECLARE @Orders AS TABLE
(
	orderid INT NOT NULL PRIMARY KEY,
	custid INT NOT NULL,
	empid INT NOT NULL,
	orderdate DATE NOT NULL
);
INSERT 
	INTO @Orders(orderid, custid, empid, orderdate) 
	VALUES
		(2, 1, 3, '20120612'),
		(3, 2, 2, '20120612'),
		(4, 3, 5, '20120612');
MERGE INTO Sales.MyOrders AS TGT
USING @Orders AS SRC
	ON SRC.orderid = TGT.orderid
WHEN MATCHED 
	AND ( TGT.custid <> SRC.custid
	OR TGT.empid <> SRC.empid
	OR TGT.orderdate <> SRC.orderdate) 
		THEN UPDATE
		SET TGT.custid = SRC.custid,
			TGT.empid = SRC.empid,
			TGT.orderdate = SRC.orderdate
WHEN NOT MATCHED 
	THEN INSERT
	VALUES(SRC.orderid, SRC.custid, SRC.empid, SRC.orderdate)
WHEN NOT MATCHED 
	BY SOURCE THEN
	DELETE;

SELECT * FROM Sales.MyOrders;
/*=========================================
Working with the OUTPUT Clause

=========================================*/

/*
prepare data
*/
IF OBJECT_ID('Sales.MyOrders') IS NOT NULL DROP TABLE Sales.MyOrders;
IF OBJECT_ID('Sales.MyOrders2') IS NOT NULL DROP TABLE Sales.MyOrders2;
IF OBJECT_ID('Sales.SeqOrderIDs') IS NOT NULL DROP SEQUENCE Sales.SeqOrderIDs;
CREATE SEQUENCE Sales.SeqOrderIDs AS INT
MINVALUE 1
CYCLE;
CREATE TABLE Sales.MyOrders
(
	orderid INT NOT NULL
		CONSTRAINT PK_MyOrders_orderid PRIMARY KEY
		CONSTRAINT DF_MyOrders_orderid DEFAULT(NEXT VALUE FOR Sales.SeqOrderIDs),
	custid INT NOT NULL
		CONSTRAINT CK_MyOrders_custid CHECK(custid > 0),
	empid INT NOT NULL
		CONSTRAINT CK_MyOrders_empid CHECK(empid > 0),
	orderdate DATE NOT NULL
);

SELECT * INTO Sales.MyOrders2 FROM Sales.MyOrders;

--INSERT with OUTPUT

INSERT INTO Sales.MyOrders(custid, empid, orderdate)
	OUTPUT
	inserted.orderid, inserted.custid, inserted.empid, inserted.orderdate
SELECT custid, empid, orderdate
FROM Sales.Orders
WHERE shipcountry = N'Norway';

SELECT * FROM Sales.MyOrders;

-- we can store result
INSERT INTO Sales.MyOrders(custid, empid, orderdate)
OUTPUT
	inserted.orderid, inserted.custid, inserted.empid, inserted.orderdate
INTO Sales.MyOrders2(orderid, custid, empid, orderdate)
SELECT custid, empid, orderdate
FROM Sales.Orders
WHERE shipcountry = N'Norway';

SELECT * FROM Sales.MyOrders2;

--Clean up
DROP TABLE IF EXISTS Sales.MyOrders2;
GO

---DELETE with OUTPUT
DELETE FROM Sales.MyOrders
OUTPUT deleted.orderid
WHERE empid = 1;


--UPDATE with OUTPUT

UPDATE Sales.MyOrders
SET orderdate = DATEADD(day, 1, orderdate)
OUTPUT
	inserted.orderid,
	deleted.orderdate AS old_orderdate,
	inserted.orderdate AS neworderdate
WHERE empid = 7;


--MERGE with OUTPUT

MERGE INTO Sales.MyOrders AS TGT
USING (VALUES(1, 70, 1, '20061218'),
			(2, 50, 7, '20070429'),
			(3, 50, 7, '20070820'),
			(4, 70, 3, '20080114'),
			(5, 70, 1, '20080226'),
			(6, 70, 2, '20080410'))
AS SRC(orderid, custid, empid, orderdate )
	ON SRC.orderid = TGT.orderid
WHEN MATCHED AND ( TGT.custid <> SRC.custid
		OR TGT.empid <> SRC.empid
		OR TGT.orderdate <> SRC.orderdate) 
		THEN UPDATE
			SET TGT.custid = SRC.custid,
				TGT.empid = SRC.empid,
				TGT.orderdate = SRC.orderdate
WHEN NOT MATCHED 
	THEN INSERT (orderid, custid, empid, orderdate)
	VALUES(SRC.orderid, SRC.custid, SRC.empid, SRC.orderdate)
WHEN NOT MATCHED BY SOURCE
	THEN DELETE
OUTPUT
	$action AS the_action,
	inserted.custid AS inserted_custid,
	deleted.custid AS deleted_custid,
	COALESCE(inserted.orderid, deleted.orderid) AS orderid;


--OUTPUT option with FROM clause
UPDATE o
SET orderdate = DATEADD(day, 1, o.orderdate)
OUTPUT
	inserted.orderdate,
	emp.firstname,
	emp.lastname
FROM Sales.MyOrders AS o
    INNER JOIN HR.Employees AS emp
        ON O.empid = emp.empid
WHERE emp.lastname = N'Davis';

DELETE o
OUTPUT
	deleted.orderid,
	emp.firstname,
	emp.lastname
FROM Sales.MyOrders AS o
    INNER JOIN HR.Employees AS emp
        ON O.empid = emp.empid
WHERE emp.lastname = N'Davis';

--Doesn't work with INSERT
INSERT INTO Sales.MyOrders(custid, empid, orderdate)
	OUTPUT
	inserted.orderid, emp.firstname, emp.lastname
SELECT o.custid, o.empid, o.orderdate
FROM Sales.Orders AS o
    INNER JOIN HR.Employees AS emp
        ON O.empid = emp.empid
WHERE emp.lastname = N'Davis';

--Workaround
MERGE
	Sales.MyOrders AS dst
USING (
	SELECT o.custid, o.empid, o.orderdate, emp.firstname, emp.lastname
	FROM Sales.Orders AS o
		INNER JOIN HR.Employees AS emp
			ON O.empid = emp.empid
	WHERE emp.lastname = N'Davis'
) AS src
ON 1 = 0	--fake condition
WHEN NOT MATCHED THEN
	INSERT (custid, empid, orderdate)
	VALUES (src.custid, src.empid, src.orderdate)
OUTPUT
	inserted.orderid, src.firstname, src.lastname
;

--Clean up
DROP TABLE IF EXISTS Sales.MyOrders;



/*=========================================
Managing transactions

=========================================*/

SELECT * FROM sys.dm_tran_active_transactions;


/*=========================================
Prepare data
=========================================*/

USE TSQL2012;
GO

DROP TABLE IF EXISTS #Categories;
DROP TABLE IF EXISTS #Products;

SELECT
	[categoryid]	= [categoryid] + 0,
	[categoryname]
INTO
	#Categories
FROM
	[Production].[Categories]
;
SELECT
	[productid]		= [productid] + 0,
	[productname],
	[categoryid],
	[unitprice]
INTO
	#Products
FROM
	[Production].[Products]
;

--SELECT * FROM #Categories;
--SELECT * FROM #Products;

/*=========================================
Basic transaction
=========================================*/
SELECT * FROM #Categories WHERE [categoryid] = 10;
SELECT * FROM #Products WHERE [productid] = 1;

BEGIN TRAN;
	INSERT INTO
		#Categories
		([categoryid], [categoryname])
	VALUES
		(10, N'Category')
	;
	UPDATE
		#Products
	SET
		[categoryid] = 10
	WHERE
		[productid] = 1
	;
COMMIT TRAN;

SELECT * FROM #Categories WHERE [categoryid] = 10;
SELECT * FROM #Products WHERE [productid] = 1;

/*=========================================
Rollback transaction
=========================================*/
SELECT * FROM #Categories WHERE [categoryid] = 11;
SELECT * FROM #Products WHERE [productid] = 1;

BEGIN TRAN;
	INSERT INTO
		#Categories
		([categoryid], [categoryname])
	VALUES
		(11, N'Shmategory')
	;
	UPDATE
		#Products
	SET
		[categoryid] = 11
	WHERE
		[productid] = 1
	;

	SELECT * FROM #Categories WHERE [categoryid] = 11;
	SELECT * FROM #Products WHERE [productid] = 1;
ROLLBACK TRAN;

SELECT * FROM #Categories WHERE [categoryid] = 11;
SELECT * FROM #Products WHERE [productid] = 1;

/*=========================================
Nested transaction
=========================================*/

SELECT @@TRANCOUNT AS [TRANCOUNT], XACT_STATE() AS [XACT_STATE], N'Start';

BEGIN TRAN;
	SELECT @@TRANCOUNT AS [TRANCOUNT], XACT_STATE() AS [XACT_STATE], N'First transaction';

		BEGIN TRAN; -- nested transaction
			SELECT @@TRANCOUNT AS [TRANCOUNT], XACT_STATE() AS [XACT_STATE], N'Second transaction';
		COMMIT TRAN;

	SELECT @@TRANCOUNT AS [TRANCOUNT], XACT_STATE() AS [XACT_STATE], N'First commit';
COMMIT TRAN;

SELECT @@TRANCOUNT AS [TRANCOUNT], XACT_STATE() AS [XACT_STATE], N'Second commit';


/*=========================================
Rollback transaction
=========================================*/

SELECT @@TRANCOUNT AS [TRANCOUNT], XACT_STATE() AS [XACT_STATE], N'Start';

BEGIN TRAN;
	SELECT @@TRANCOUNT AS [TRANCOUNT], XACT_STATE() AS [XACT_STATE], N'First transaction';

		BEGIN TRAN; -- nested transaction
			SELECT @@TRANCOUNT AS [TRANCOUNT], XACT_STATE() AS [XACT_STATE], N'Second transaction';
		
ROLLBACK TRAN;	-- just once

SELECT @@TRANCOUNT AS [TRANCOUNT], XACT_STATE() AS [XACT_STATE], N'Rollback';


/*=========================================
Rollback transaction
=========================================*/

SELECT * FROM #Categories WHERE [categoryid] = 11;
SELECT * FROM #Products WHERE [productid] = 1;

BEGIN TRAN;

	BEGIN TRAN;
		INSERT INTO
			#Categories
			([categoryid], [categoryname])
		VALUES
			(11, N'Shmategory')
		;
	COMMIT TRAN;

	UPDATE
		#Products
	SET
		[categoryid] = 11
	WHERE
		[productid] = 1
	;

	SELECT * FROM #Categories WHERE [categoryid] = 11;
	SELECT * FROM #Products WHERE [productid] = 1;
ROLLBACK TRAN;

SELECT * FROM #Categories WHERE [categoryid] = 11;
SELECT * FROM #Products WHERE [productid] = 1;


/*=========================================
Save transaction
=========================================*/

SELECT * FROM #Categories WHERE [categoryid] = 11;
SELECT * FROM #Products WHERE [productid] = 1;

BEGIN TRAN;
	INSERT INTO
		#Categories
		([categoryid], [categoryname])
	VALUES
		(11, N'Shmategory')
	;

	SAVE TRAN SavePoint;
		UPDATE
			#Products
		SET
			[categoryid] = 11
		WHERE
			[productid] = 1
		;
	ROLLBACK TRAN SavePoint;
COMMIT TRAN;

SELECT * FROM #Categories WHERE [categoryid] = 11;
SELECT * FROM #Products WHERE [productid] = 1;

/*=========================================
Batch
=========================================*/
SELECT 1;
SELECT 1;
SELECT 1;
GO
SELECT 1;
GO

--Variables
DECLARE @x INT = 1;
SELECT @x;
GO
--DECLARE @x INT = 2;
SELECT @x; --Error
SELECT 1;

--Some types DDL statements must be the only statement in the batch 
--GO
CREATE VIEW [dbo].[TestView]
	AS
SELECT 1 AS [Col1];
GO

--One transaction per few batches
BEGIN TRAN;
GO
SELECT empid, lastname, firstname, postalcode
FROM HR.Employees;
GO
COMMIT TRAN;
GO

--Few transactions per one batch
BEGIN TRAN;
	SELECT empid, lastname, firstname, postalcode
	FROM HR.Employees;
COMMIT TRAN;
BEGIN TRAN;
	SELECT empid, lastname, firstname, postalcode
	FROM HR.Employees;
COMMIT TRAN;
GO



/*=========================================
--Use XACT_ABORT to Handle Errors
=========================================*/

--OFF by default
SET XACT_ABORT OFF;

BEGIN TRAN;
SELECT [Message] = 'First Select';
SELECT [Message] = 'Second Select', 1/0;
SELECT [Message] = 'Third Select';

SELECT @@TRANCOUNT;

ROLLBACK TRAN;


SET XACT_ABORT ON;

BEGIN TRAN;
SELECT [Message] = 'First Select';
SELECT [Message] = 'Second Select', 1/0;
SELECT [Message] = 'Third Select';

SELECT @@TRANCOUNT;
ROLLBACK TRAN;