/*=========================================
MSBI.Dev.S19E05.Script.01
=========================================*/

/*========================================================================================================================
- topicname: Using Window Functions
  subtopics:
   - subtopicname: Window Aggregate Functions
     keywords: [FRAMES]
   - subtopicname: Window Ranking Functions
     keywords: [ROW_NUMBER, RANK, DENSE_RANK, NTILE]
   - subtopicname: Window Offset Functions
     keywords: [LAG, LEAD]
- topicname: Creating and Altering Tables
  subtopics:
   - subtopicname: Managing and Configuring Databases
   - subtopicname: Naming Tables and Columns
   - subtopicname: Choosing Column Data Types
   - subtopicname: NULL and Default Values
   - subtopicname: The Identity Property and Sequence Numbers
   - subtopicname: Computed Columns
   - subtopicname: Table Compression
- topicname: Enforcing Data Integrity
  subtopics:
   - subtopicname: Primary Key Constraints
   - subtopicname: Unique Constraints
   - subtopicname: Foreign Key Constraints
   - subtopicname: Check Constraints
   - subtopicname: Default Constraints
- topicname: SSDT How to manage database as a source code
  subtopics:
   - subtopicname: SSDT review
   - subtopicname: Create a project
   - subtopicname: Merge changes
   - subtopicname: Deploy to server
   - subtopicname: Homework assignment
---     
========================================================================================================================*/

/*---------------------------------------------------------------------------------------- 
   - subtopicname: Window Aggregate Functions
-----------------------------------------------------------------------------------------*/

SELECT 
    custid,
    orderid,
    val,
    SUM(val) OVER(PARTITION BY custid) AS custtotal,
    SUM(val) OVER() AS grandtotal
FROM Sales.OrderValues;


SELECT custid, orderid,
    val,
    CAST(
			100.0 * val / SUM(val) OVER(PARTITION BY custid)
		AS NUMERIC(5, 2))	AS pctcust,
    CAST(
			100.0 * val / SUM(val) OVER()
		AS NUMERIC(5, 2))	AS pcttotal
FROM Sales.OrderValues;

--Running total
SELECT 
    custid,
    orderid,
	orderdate,
    val,
    SUM(val) OVER(PARTITION BY custid	ORDER BY orderdate, orderid) AS runningtotal,
	SUM(val) OVER(PARTITION BY custid) AS custtotal
FROM Sales.OrderValues;


--Running total with frame
SELECT 
    custid,
    orderid,
    orderdate,
    val,
    SUM(val) OVER(
		PARTITION BY custid		ORDER BY orderdate,	 orderid
        ROWS BETWEEN	UNBOUNDED PRECEDING    AND CURRENT ROW
    ) AS runningtotal
FROM Sales.OrderValues;

--
WITH RunningTotals AS
(
    SELECT 
        custid,
        orderid,
        orderdate, 
        val,
        SUM(val) OVER(PARTITION BY custid 	ORDER BY orderdate, orderid
                        ROWS BETWEEN UNBOUNDED PRECEDING
                        AND CURRENT ROW) 
        AS runningtotal
    FROM Sales.OrderValues
)
SELECT *
FROM RunningTotals
WHERE runningtotal > 10000.00;






/*---------------------------------------------------------------------------------------- 
   - subtopicname: Window Ranking Functions
-----------------------------------------------------------------------------------------*/
--RANKING Function

SELECT custid, orderid, val,
    ROW_NUMBER() OVER(ORDER BY val) AS rownum,
    RANK() OVER(ORDER BY val) AS rnk,
    DENSE_RANK() OVER(ORDER BY val) AS densernk,
    NTILE(100) OVER(ORDER BY val) AS ntile100
FROM Sales.OrderValues;


--Count Distinct
SELECT COUNT(DISTINCT orderdate) AS dcount FROM Sales.OrderValues;


WITH RankedDates AS(
	SELECT
		custid,
		orderid,
		orderdate,
		ROW_NUMBER() OVER(PARTITION BY orderdate ORDER BY (SELECT 1)) AS rnum
	FROM Sales.OrderValues
)
SELECT
	custid,
	orderid,
	orderdate,
	SUM(CASE WHEN rnum = 1	THEN 1	ELSE 0	END) OVER() AS dcount
FROM
	RankedDates;



--Query to produce test data

DECLARE @low AS BIGINT
DECLARE @high AS BIGINT
SET @low=1;
SET @high=100000;

WITH
L0 AS (SELECT c FROM (VALUES(1),(1)) AS D(c)),			--2
L1 AS (SELECT 1 AS c FROM L0 AS A CROSS JOIN L0 AS B),	--4
L2 AS (SELECT 1 AS c FROM L1 AS A CROSS JOIN L1 AS B),	--16
L3 AS (SELECT 1 AS c FROM L2 AS A CROSS JOIN L2 AS B),	--256
L4 AS (SELECT 1 AS c FROM L3 AS A CROSS JOIN L3 AS B),	--65 536
L5 AS (SELECT 1 AS c FROM L4 AS A CROSS JOIN L4 AS B),	--4 294 967 296
Nums AS (
	SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS rownum FROM L5
)
SELECT @low + rownum - 1 AS n
FROM Nums
ORDER BY rownum
OFFSET 0 ROWS FETCH FIRST @high - @low + 1 ROWS ONLY;

/*---------------------------------------------------------------------------------------- 
   - subtopicname: Window Offset Functions
-----------------------------------------------------------------------------------------*/

SELECT 
    custid,
    orderid,
    orderdate,
    val,
    LEAD(val,2) OVER(PARTITION BY custid ORDER BY orderdate, orderid) AS next_val,
    LAG(val,2) OVER(PARTITION BY custid ORDER BY orderdate, orderid) AS prev_val
FROM Sales.OrderValues;

SELECT 
    custid,
    orderid,
    orderdate,
    val,
    LEAD(val,2,0) OVER(PARTITION BY custid ORDER BY orderdate, orderid) AS next_val,
    LAG(val,2,0) OVER(PARTITION BY custid ORDER BY orderdate, orderid) AS prev_val
FROM Sales.OrderValues;

SELECT 
    custid,
    orderid,
    orderdate,
    val,
    val - LAG(val) OVER(PARTITION BY custid ORDER BY orderdate, orderid) AS diffprev
    --val - LEAD(val) OVER(PARTITION BY custid ORDER BY orderdate, orderid) AS diffnext
FROM Sales.OrderValues;


SELECT 
    custid,
    orderid,
    orderdate,
    val,
    --val - LAG(val) OVER(PARTITION BY custid ORDER BY orderdate, orderid) AS diffprev,
    val - LEAD(val) OVER(PARTITION BY custid ORDER BY orderdate, orderid) AS diffnext
FROM Sales.OrderValues;


SELECT 
    custid,
    orderid,
    orderdate,
    val,
    FIRST_VALUE(val) 
            OVER
                (
                    PARTITION BY custid ORDER BY orderdate, orderid
                    ROWS BETWEEN UNBOUNDED PRECEDING
                    AND CURRENT ROW
                ) AS first_val,
    LAST_VALUE(val) 
            OVER
                (
                    PARTITION BY custid ORDER BY orderdate, orderid
                    ROWS BETWEEN CURRENT ROW
                    AND UNBOUNDED FOLLOWING
                ) AS last_val
FROM Sales.OrderValues
ORDER BY custid, orderdate, orderid;





/*========================================================================================================================
- topicname: Creating and Altering Tables
  subtopics:
   - subtopicname: Managing and Configuring Databases
   - subtopicname: Naming Tables and Columns
   - subtopicname: Choosing Column Data Types
   - subtopicname: NULL and Default Values
   - subtopicname: The Identity Property and Sequence Numbers
   - subtopicname: Computed Columns
   - subtopicname: Table Compression

========================================================================================================================*/

CREATE TABLE Production.CategoriesTest1
(
	categoryid INT IDENTITY(1,1) NOT NULL,
	categoryname NVARCHAR(15) NOT NULL,
	description NVARCHAR(200) NOT NULL
)
GO

--schemas
SELECT TOP (10) categoryname FROM Production.Categories;

-- create schema
go
CREATE SCHEMA Production AUTHORIZATION dbo;
GO

-- move table from schema to schema
ALTER SCHEMA Sales TRANSFER Production.Categories;
ALTER SCHEMA Production TRANSFER Sales.Categories;


/*---------------------------------------------------------------------------------------- 
   - subtopicname: Computed Columns
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
ADD initialcost AS unitprice * qty



/*---------------------------------------------------------------------------------------- 
   - subtopicname: Table Compression
-----------------------------------------------------------------------------------------*/

CREATE TABLE Sales.OrderDetails
(
    orderid INT NOT NULL,
)
WITH (DATA_COMPRESSION = ROW);

-- rebuild 
ALTER TABLE Sales.OrderDetails
REBUILD WITH (DATA_COMPRESSION = PAGE);

/*---------------------------------------------------------------------------------------- 
   - subtopicname: altering table
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
ADD categoryname NVARCHAR(15) NOT NULL;
GO
ALTER TABLE Production.CategoriesTest
ADD description NVARCHAR(200) NOT NULL;
GO

--= try  to insert
INSERT Production.CategoriesTest 
(categoryid, categoryname, description)
SELECT categoryid, categoryname, description
FROM Production.Categories;
GO

-- enable identity insert

TRUNCATE TABLE Production.CategoriesTest;

SET IDENTITY_INSERT Production.CategoriesTest ON;
INSERT Production.CategoriesTest (categoryid, categoryname, description)
SELECT categoryid, categoryname, description
FROM Production.Categories;
GO
SET IDENTITY_INSERT Production.CategoriesTest OFF;
GO

--Make the description column larger.
ALTER TABLE Production.CategoriesTest
ALTER COLUMN description VARCHAR(500);
GO


/*========================================================================================================================
- topicname: Enforcing Data Integrity
  subtopics:
   - subtopicname: Primary Key Constraints
   - subtopicname: Unique Constraints
   - subtopicname: Foreign Key Constraints
   - subtopicname: Check Constraints
   - subtopicname: Default Constraints

========================================================================================================================*/


/*---------------------------------------------------------------------------------------- 
   - subtopicname: Primary Key Constraints
-----------------------------------------------------------------------------------------*/
DROP TABLE IF EXISTS Production.CategoriesTest3;
GO

CREATE TABLE Production.CategoriesTest3
(
    categoryid INT NOT NULL IDENTITY,
    categoryname NVARCHAR(15) NOT NULL,
    description NVARCHAR(200) NOT NULL,
    CONSTRAINT PK_CategoriesTest3 PRIMARY KEY(categoryid)
);

SET IDENTITY_INSERT [Production].[CategoriesTest3] ON;
INSERT INTO [Production].[CategoriesTest3]
           ([categoryid],[categoryname],[description])
     VALUES
           (1,'testa','tet')
SET IDENTITY_INSERT [Production].[CategoriesTest3] OFF;


-- add to existing table
ALTER TABLE Production.Categories
ADD CONSTRAINT PK_Categories PRIMARY KEY(categoryid);
GO


DROP TABLE IF EXISTS Production.CategoriesTest3;
GO


--PK is not only over clustered index. Clustered index is not only unique
DROP TABLE IF EXISTS Production.CategoriesTest4;
GO

CREATE TABLE Production.CategoriesTest4
(
    categoryid INT NOT NULL IDENTITY,
    categoryname NVARCHAR(15) NOT NULL,
    description NVARCHAR(200) NOT NULL,
    CONSTRAINT PK_CategoriesTest4 PRIMARY KEY NONCLUSTERED(categoryid)
);
GO

CREATE CLUSTERED INDEX [CI_Production_CategoriesTest4]	--Non unique!
	ON [Production].[CategoriesTest4] ([categoryname]);
GO

DROP TABLE IF EXISTS Production.CategoriesTest4;
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
   - subtopicname: Unique Constraints
-----------------------------------------------------------------------------------------*/

ALTER TABLE Production.Categories
	ADD CONSTRAINT UC_Categories UNIQUE (categoryname);
GO
--The unique constraint does not require the column to be NOT NULL. You can allow NULL in
--a column and still have a unique constraint, but only one row can be NULL.


SELECT *
FROM sys.key_constraints
WHERE type = 'UQ';

/*---------------------------------------------------------------------------------------- 
   - subtopicname: Foreign Key Constraints
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
   - subtopicname: Check Constraints
-----------------------------------------------------------------------------------------*/


ALTER TABLE Production.Products WITH CHECK
ADD CONSTRAINT CHK_Products_unitprice
CHECK (unitprice>=0);
GO

--
SELECT *
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID('Production.Products');

/*---------------------------------------------------------------------------------------- 
   - subtopicname: Default Constraints
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

















