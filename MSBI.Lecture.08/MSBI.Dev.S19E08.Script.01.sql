/*=========================================
MSBI.DEV.COURSE.S18E08.SCRIPT
=========================================*/


/*=========================================
Inserting Data
=========================================*/


/*=========================================
Prepare sample data
=========================================*/


----------------drop table---------------------------
USE TSQL2012;
IF OBJECT_ID('Sales.MyOrders', 'U') IS NOT NULL
DROP TABLE  Sales.MyOrders;
go

----------------create table---------------------------
USE TSQL2012;
IF OBJECT_ID('Sales.MyOrders') IS NOT NULL DROP TABLE Sales.MyOrders;
GO
CREATE TABLE Sales.MyOrders
(
	orderid INT NOT NULL IDENTITY(1, 1)
	CONSTRAINT PK_MyOrders_orderid PRIMARY KEY,
	custid INT NOT NULL,
	empid INT NOT NULL,
	orderdate DATE NOT NULL
	CONSTRAINT DFT_MyOrders_orderdate DEFAULT (CAST(SYSDATETIME() AS DATE)),
	shipcountry NVARCHAR(15) NOT NULL,
	freight MONEY NOT NULL
);

PRINT SYSDATETIME();
PRINT GETDATE();
PRINT GETUTCDATE();
-- pay attention
SELECT GETDATE() AS fn_GetDate, SYSDATETIME() AS fn_SYSDATETIME
--DATETIME and the other DATETIME2


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

INSERT 
    INTO Sales.MyOrders
    (custid, empid, orderdate, shipcountry, freight)
VALUES  (2, 19, '20120620', N'USA', 30.00);
/*=========================================
INSERT VALUES Server uses the default expression for orderdate
=========================================*/
INSERT INTO Sales.MyOrders(custid, empid, shipcountry, freight)
VALUES(3, 11, N'USA', 10.00);

-- or use default key word
INSERT INTO Sales.MyOrders(custid, empid, orderdate, shipcountry, freight)
VALUES(3, 17, DEFAULT, N'RUS', 30.00);


/*=========================================
The INSERT VALUES with multiple rows
=========================================*/
BEGIN TRAN
 
INSERT 
    INTO Sales.MyOrders (custid, empid, orderdate, shipcountry, freight)
 VALUES
    (2, 11, '20120620', N'USA', 50.00),
    (5, 13, '20120620', N'USA', 40.00),
    (7, 17, '20120620', N'USA', 45.00);


ROLLBACK
/*=========================================
review result
=========================================*/
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
/*=========================================

=========================================*/



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

/*=========================================
 wrong SP create SP
=========================================*/
IF OBJECT_ID('Sales.usp_OrdersForCountry', 'P') IS NOT NULL
DROP PROC Sales.usp_OrdersForCountry;
GO
CREATE PROC Sales.usp_OrdersForCountry
@country AS NVARCHAR(15)
AS
    SELECT  'sdsd' col12, orderid, custid, empid, orderdate, shipcountry, freight
    FROM Sales.Orders
    WHERE shipcountry = @country;
GO
/*=========================================

=========================================*/

SET IDENTITY_INSERT Sales.MyOrders ON;

EXEC Sales.usp_OrdersForCountry N'Portugal';

INSERT 
	INTO Sales.MyOrders(orderid, custid, empid, orderdate, shipcountry, freight)
EXEC Sales.usp_OrdersForCountry
		@country = N'Portugal';


SET IDENTITY_INSERT Sales.MyOrders OFF;


SELECT *
FROM Sales.MyOrders;



--**************************************************************************************************************
--SELECT INTO
--**************************************************************************************************************

IF OBJECT_ID('Sales.MyOrders', 'U') IS NOT NULL DROP TABLE Sales.MyOrders;

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

IF OBJECT_ID('Sales.MyOrders', 'U') IS NOT NULL DROP TABLE Sales.MyOrders;


SELECT
    ISNULL(orderid + 0, -1) AS orderid, -- get rid of IDENTITY property
-- make column NOT NULL
    ISNULL(custid, -1) AS custid, -- make column NOT NULL
    empid,
    ISNULL(CAST(orderdate AS DATE), '19000101') AS orderdate,
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
IF OBJECT_ID('Sales.MyOrders', 'U') IS NOT NULL
DROP TABLE Sales.MyOrders;



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

-- roll back

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



UPDATE OD
SET OD.discount -= 0.05
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
UPDATE and Table Expressions
=========================================*/
-- first version
SELECT 
	TGT.custid,
	TGT.country AS tgt_country,
	SRC.country AS src_country,
	TGT.postalcode AS tgt_postalcode,
	SRC.postalcode AS src_postalcode
FROM Sales.MyCustomers AS TGT
	INNER JOIN Sales.Customers AS SRC
		ON TGT.custid = SRC.custid;

-- but for update we should replace SELECT
UPDATE TGT
	SET TGT.country = SRC.country,
		TGT.postalcode = SRC.postalcode
FROM Sales.MyCustomers AS TGT
	INNER JOIN Sales.Customers AS SRC
		ON TGT.custid = SRC.custid;

-- there is a way to combine both
WITH C AS
(
	SELECT 
		TGT.custid,
		TGT.country AS tgt_country,
		SRC.country AS src_country,
		TGT.postalcode AS tgt_postalcode,
		SRC.postalcode AS src_postalcode
	FROM Sales.MyCustomers AS TGT
		INNER JOIN Sales.Customers AS SRC
			ON TGT.custid = SRC.custid
)
UPDATE C
SET		tgt_country = src_country,
		tgt_postalcode = src_postalcode;


-- or by derrived table
UPDATE D
SET		tgt_country = src_country,
		tgt_postalcode = src_postalcode
FROM (
		SELECT 
			TGT.custid,
			TGT.country AS tgt_country, 
			SRC.country AS src_country,
			TGT.postalcode AS tgt_postalcode,
			SRC.postalcode AS src_postalcode
		FROM Sales.MyCustomers AS TGT
			INNER JOIN Sales.Customers AS SRC
				ON TGT.custid = SRC.custid
	) AS D;


	--UPDATE statements based on joins:
UPDATE TGT
SET TGT.country		=	SRC.country,
	TGT.postalcode	 =	SRC.postalcode
FROM Sales.MyCustomers AS TGT
	INNER JOIN Sales.Customers AS SRC
		ON TGT.custid = SRC.custid;

UPDATE Sales.MyCustomers
	SET		
			MyCustomers.country = SRC.country,
			MyCustomers.postalcode = SRC.postalcode
FROM Sales.Customers AS SRC
	WHERE MyCustomers.custid = SRC.custid;

--This code is equivalent to the following use of an explicit cross join with a filter.
UPDATE TGT
	SET 
		TGT.country = SRC.country,
		TGT.postalcode = SRC.postalcode
FROM Sales.MyCustomers AS TGT
	CROSS JOIN Sales.Customers AS SRC
WHERE TGT.custid = SRC.custid;

/*=========================================
--UPDATE Based on a Variable
=========================================*/

SELECT *
FROM Sales.MyOrderDetails
WHERE orderid = 10250
	AND productid = 51;


DECLARE @newdiscount AS NUMERIC(4, 3) = NULL;

UPDATE Sales.MyOrderDetails
	SET @newdiscount = discount += 0.05
WHERE orderid = 10250
	AND productid = 51;

SELECT @newdiscount;

-- rollback
UPDATE Sales.MyOrderDetails
SET discount -= 0.05
WHERE orderid = 10250
AND productid = 51;



/*=========================================
All at once
=========================================*/

IF OBJECT_ID('dbo.T1', 'U') IS NOT NULL DROP TABLE dbo.T1;
CREATE TABLE dbo.T1
(
	keycol INT NOT NULL
	CONSTRAINT PK_T1 PRIMARY KEY,
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
IF OBJECT_ID('dbo.T1', 'U') IS NOT NULL DROP TABLE dbo.T1;


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
WHERE productid = 10;

DELETE FROM Sales.MyOrderDetails
WHERE productid = 11;

SELECT * FROM Sales.MyOrderDetails
WHERE productid = 12;

/*=========================================
delete is very log expensive command
here is a variant  with chunks.
=========================================*/
WHILE 1 = 1
BEGIN
	DELETE TOP (5) FROM Sales.MyOrderDetails
	WHERE productid = 12;
    -- PRINT  ' iteration'
	IF @@rowcount < 5 BREAK;
     
END

/*=========================================
DELETE Based on a Join
=========================================*/

SELECT *  FROM Sales.MyOrders;
--(830 rows affected)
--(708 rows affected)
BEGIN TRAN



DELETE FROM O
FROM Sales.MyOrders AS O
	INNER JOIN Sales.MyCustomers AS C
		ON O.custid = C.custid
WHERE C.country = N'USA';

ROLLBACK

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
IF OBJECT_ID('Sales.MyOrders') IS NOT NULL DROP TABLE Sales.MyOrders;
GO
CREATE TABLE Sales.MyOrders
(
	orderid INT NOT NULL IDENTITY(1, 1)
	CONSTRAINT PK_MyOrders_orderid PRIMARY KEY,
	custid INT NOT NULL
	CONSTRAINT CHK_MyOrders_custid CHECK(custid > 0),
	empid INT NOT NULL
	CONSTRAINT CHK_MyOrders_empid CHECK(empid > 0),
	orderdate DATE NOT NULL
);

INSERT 
	INTO Sales.MyOrders(custid, empid, orderdate)
VALUES
		(1, 2, '20120620'),
		(1, 3, '20120620'),
		(2, 2, '20120620');

SELECT * FROM Sales.MyOrders;

DELETE FROM Sales.MyOrders;

/*=========================================
how to get identity value
=========================================*/
SELECT
SCOPE_IDENTITY() AS SCOPE_IDENTITY,
@@IDENTITY AS [@@IDENTITY],
IDENT_CURRENT('Sales.MyOrders') AS IDENT_CURRENT;

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

DROP SEQUENCE [Sales].[SeqOrderIDs]
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
	orderid INT NOT NULL
	CONSTRAINT PK_MyOrders_orderid PRIMARY KEY,
	custid INT NOT NULL
	CONSTRAINT CHK_MyOrders_custid CHECK(custid > 0),
	empid INT NOT NULL
	CONSTRAINT CHK_MyOrders_empid CHECK(empid > 0),
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


-- review 
SELECT * FROM Sales.MyOrders;

-- add as a constraint
ALTER TABLE Sales.MyOrders
ADD CONSTRAINT DFT_MyOrders_orderid
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

TRUNCATE TABLE Sales.MyOrders;
ALTER SEQUENCE Sales.SeqOrderIDs RESTART WITH 1;

IF OBJECT_ID('Sales.MyOrders') IS NOT NULL DROP TABLE Sales.MyOrders;
IF OBJECT_ID('Sales.SeqOrderIDs') IS NOT NULL DROP SEQUENCE Sales.SeqOrderIDs;
CREATE SEQUENCE Sales.SeqOrderIDs AS INT
MINVALUE 1
CYCLE;
CREATE TABLE Sales.MyOrders
(
	orderid INT NOT NULL
	CONSTRAINT PK_MyOrders_orderid PRIMARY KEY
	CONSTRAINT DFT_MyOrders_orderid
	DEFAULT(NEXT VALUE FOR Sales.SeqOrderIDs),
	custid INT NOT NULL
	CONSTRAINT CHK_MyOrders_custid CHECK(custid > 0),
	empid INT NOT NULL
	CONSTRAINT CHK_MyOrders_empid CHECK(empid > 0),
	orderdate DATE NOT NULL
);


--DECLARE
--	@orderid AS INT = 1,
--	@custid AS INT = 1,
--	@empid AS INT = 2,
--	@orderdate AS DATE = '20120620';
--SELECT *
--FROM (SELECT @orderid, @custid, @empid, @orderdate )
--AS SRC( orderid, custid, empid, orderdate );


--DECLARE
--	@orderid AS INT = 1,
--	@custid AS INT = 1,
--	@empid AS INT = 2,
--	@orderdate AS DATE = '20120620';
--SELECT *
--FROM (VALUES(@orderid, @custid, @empid, @orderdate))
--AS SRC( orderid, custid, empid, orderdate);

DECLARE
	@orderid AS INT = 1,
	@custid AS INT = 1,
	@empid AS INT = 2,
	@orderdate AS DATE = '20120620';

MERGE INTO Sales.MyOrders WITH (HOLDLOCK) AS TGT  -- explain why  HOLDLOCK - two process P1 and P2 run at the same time
USING (VALUES(@orderid, @custid, @empid, @orderdate))
AS SRC( orderid, custid, empid, orderdate)
	ON SRC.orderid = TGT.orderid
WHEN MATCHED THEN UPDATE
	SET TGT.custid = SRC.custid,
	TGT.empid = SRC.empid,
	TGT.orderdate = SRC.orderdate
WHEN NOT MATCHED THEN INSERT
VALUES(SRC.orderid, SRC.custid, SRC.empid, SRC.orderdate);

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
		THEN INSERT
		VALUES(SRC.orderid, SRC.custid, SRC.empid, SRC.orderdate);

-- remember about NULL
/*
TGT.custid = SRC.custid OR (TGT.custid IS NULL AND SRC.custid IS NOT
NULL) OR (TGT.custid IS NOT NULL AND SRC.custid IS NULL).
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


/*=========================================
Working with the OUTPUT Clause

=========================================*/

/*
prepare data
*/
IF OBJECT_ID('Sales.MyOrders') IS NOT NULL DROP TABLE Sales.MyOrders;
IF OBJECT_ID('Sales.SeqOrderIDs') IS NOT NULL DROP SEQUENCE Sales.SeqOrderIDs;
CREATE SEQUENCE Sales.SeqOrderIDs AS INT
MINVALUE 1
CYCLE;
CREATE TABLE Sales.MyOrders
(
	orderid INT NOT NULL
	CONSTRAINT PK_MyOrders_orderid PRIMARY KEY
	CONSTRAINT DFT_MyOrders_orderid
	DEFAULT(NEXT VALUE FOR Sales.SeqOrderIDs),
	custid INT NOT NULL
	CONSTRAINT CHK_MyOrders_custid CHECK(custid > 0),
	empid INT NOT NULL
	CONSTRAINT CHK_MyOrders_empid CHECK(empid > 0),
	orderdate DATE NOT NULL
);

/*=========================================
Working with the OUTPUT Clause

=========================================*/

TRUNCATE TABLE Sales.MyOrders;
ALTER SEQUENCE Sales.SeqOrderIDs RESTART WITH 1;
--If the table and sequence dont exist in the database, use the following code to create
--them.
IF OBJECT_ID('Sales.MyOrders') IS NOT NULL DROP TABLE Sales.MyOrders;
IF OBJECT_ID('Sales.SeqOrderIDs') IS NOT NULL DROP SEQUENCE Sales.SeqOrderIDs;
CREATE SEQUENCE Sales.SeqOrderIDs AS INT
MINVALUE 1
CYCLE;
CREATE TABLE Sales.MyOrders
(
	orderid INT NOT NULL
	CONSTRAINT PK_MyOrders_orderid PRIMARY KEY
	CONSTRAINT DFT_MyOrders_orderid
	DEFAULT(NEXT VALUE FOR Sales.SeqOrderIDs),
	custid INT NOT NULL
	CONSTRAINT CHK_MyOrders_custid CHECK(custid > 0),
	empid INT NOT NULL
	CONSTRAINT CHK_MyOrders_empid CHECK(empid > 0),
	orderdate DATE NOT NULL
);

--INSERT with OUTPUT

INSERT INTO Sales.MyOrders(custid, empid, orderdate)
	OUTPUT
	inserted.orderid, inserted.custid, inserted.empid, inserted.orderdate
SELECT custid, empid, orderdate
FROM Sales.Orders
WHERE shipcountry = N'Norway';


-- we can store result
INSERT INTO Sales.MyOrders(custid, empid, orderdate)
OUTPUT
	inserted.orderid, inserted.custid, inserted.empid, inserted.orderdate
INTO Sametableq(orderid, custid, empid, orderdate)
SELECT custid, empid, orderdate
FROM Sales.Orders
WHERE shipcountry = N'Norway';


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
			(2, 70, 7, '20070429'),
			(3, 70, 7, '20070820'),
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
	THEN INSERT
	VALUES(SRC.orderid, SRC.custid, SRC.empid, SRC.orderdate)
WHEN NOT MATCHED BY SOURCE THEN
DELETE
OUTPUT
$action AS the_action,
COALESCE(inserted.orderid, deleted.orderid) AS orderid;


--


DECLARE @InsertedOrders AS TABLE
(
	orderid INT NOT NULL PRIMARY KEY,
	custid INT NOT NULL,
	empid INT NOT NULL,
	orderdate DATE NOT NULL
);
INSERT INTO @InsertedOrders
(orderid, custid, empid, orderdate)
SELECT orderid, custid, empid, orderdate
FROM 
(
	MERGE INTO Sales.MyOrders AS TGT
	USING (VALUES(1, 70, 1, '20061218'),
		(2, 70, 7, '20070429'),
		(3, 70, 7, '20070820'),
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
		THEN INSERT
		VALUES(SRC.orderid, SRC.custid, SRC.empid, SRC.orderdate)
	WHEN NOT MATCHED BY SOURCE THEN
	DELETE
	OUTPUT
	$action AS the_action, inserted.*
)
 AS D
WHERE the_action = 'UPDATE';
SELECT *
FROM @InsertedOrders;