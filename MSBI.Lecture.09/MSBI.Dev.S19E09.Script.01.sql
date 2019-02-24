/*=========================================
MSBI.DEV.COURSE.S18E09.SCRIPT
=========================================*/


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

/*=========================================

=========================================*/

SELECT * FROM sys.dm_tran_active_transactions


/*=========================================
LEt' s start transaction
=========================================*/
BEGIN TRAN

SELECT @@TRANCOUNT, XACT_STATE()

	BEGIN TRAN -- nested transaction

	SELECT @@TRANCOUNT, XACT_STATE()

	COMMIT TRAN

COMMIT TRAN

/*=========================================
savepoints
=========================================*/

WITH CU
AS
(
SELECT [custid]
      ,[companyname]
      ,[postalcode]
  FROM [Sales].[Customers]
  WHERE companyname IN  ('Customer NRZBB (test)','Customer MLTDN')
  )
  UPDATE CU
  SET [postalcode]='';

SELECT [custid]
      ,[companyname]
      ,[postalcode]
  FROM [Sales].[Customers]
  WHERE companyname IN  ('Customer NRZBB (test)','Customer MLTDN')




begin tran UpdateCustomer;

WITH CU
AS
(
SELECT [custid]
      ,[companyname]
      ,[postalcode]
  FROM [Sales].[Customers]  
  WHERE companyname= 'Customer NRZBB (test)'
  )
  UPDATE CU
  SET [postalcode]='10092'

SAVE TRANSACTION cupdate1


-- nested
BEGIN TRAN;

WITH CU
AS
(
SELECT [custid]
      ,[companyname]
      ,[postalcode]
  FROM [Sales].[Customers] 
  WHERE companyname= 'Customer MLTDN'
  )
  UPDATE CU
  SET [postalcode]='10071'

ROLLBACK cupdate1  -- TODO  check this



commit tran


SELECT [custid]
      ,[companyname]
      ,[postalcode]
  FROM [Sales].[Customers]
  WHERE companyname IN  ('Customer NRZBB (test)','Customer MLTDN')
/*=========================================

=========================================*/



IF EXISTS ( SELECT 1
			FROM sys.views
			WHERE name = 'DBlocks' )
DROP VIEW DBlocks ;
GO
CREATE VIEW DBlocks 
AS
SELECT request_session_id AS spid ,
	DB_NAME(resource_database_id) AS dbname ,
		CASE WHEN resource_type = 'OBJECT'
		THEN OBJECT_NAME(resource_associated_entity_id)
		WHEN resource_associated_entity_id = 0 THEN 'n/a'
		ELSE OBJECT_NAME(p.object_id)
		END AS entity_name ,
		index_id ,
		resource_type AS resource ,
		resource_description AS description ,
		request_mode AS mode ,
		request_status AS status
FROM sys.dm_tran_locks t
	LEFT JOIN sys.partitions p
ON p.partition_id = t.resource_associated_entity_id
	WHERE resource_database_id = DB_ID()
	AND resource_type <> 'DATABASE' ;

SELECT TOP 1000 [spid]
      ,[dbname]
      ,[entity_name]
      ,[index_id]
      ,[resource]
      ,[description]
      ,[mode]
      ,[status]
  FROM [TSQL2012].[dbo].[DBlocks]


  SELECT *  FROM sys.dm_tran_locks

/*=========================================
raising error
=========================================*/

RAISERROR ('Error in usp_InsertCategories stored procedure', 16, 0);
-- style formating
RAISERROR ('Error in % stored procedure', 16, 0, N'usp_InsertCategories');

GO
DECLARE @message AS NVARCHAR(1000) = 'Error in % stored procedure';
RAISERROR (@message, 16, 0, N'usp_InsertCategories');

GO
DECLARE @message AS NVARCHAR(1000) = 'Error in % stored procedure';
SELECT @message = FORMATMESSAGE (@message, N'usp_InsertCategories');
RAISERROR (@message, 16, 0);

-- throw
THROW 50000, 'Error in usp_InsertCategories stored procedure', 0;

GO
DECLARE @message AS NVARCHAR(1000) = 'Error in % stored procedure';
SELECT @message = FORMATMESSAGE (@message, N'usp_InsertCategories');
THROW 50000, @message, 0;

--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--A very simple RAISERROR int, 'string', was permitted in earlier versions of SQL Server but is
--no longer allowed in SQL Server 2012.

--difference betweeen raiseerror and throw
RAISERROR ('Hi there', 16, 0);
PRINT 'RAISERROR error'; -- Prints
GO
--THROW does terminate the batch
THROW 50000, 'Hi there', 0;
PRINT 'THROW error'; -- Does not print
GO

GO
DECLARE @message AS NVARCHAR(1000) = 'Error in % stored procedure';
SELECT @message = FORMATMESSAGE (@message, N'usp_InsertCategories');
THROW 50000, @message, 0;


SELECT TRY_CONVERT(DATETIME, '1752-12-31');
SELECT TRY_CONVERT(DATETIME, '1753-01-01');

SELECT TRY_PARSE('1' AS INTEGER);
SELECT TRY_PARSE('B' AS INTEGER);




