/*=========================================
MSBI.DEV.S21E10.SCRIPT
=========================================*/

USE [TSQL2012];

/*=========================================
XML Returning Results As XML with FOR XML
=========================================*/

--FOR XML RAW
SELECT 
     Customer.custid,
     Customer.companyname,
     [Order].orderid,
     [Order].orderdate
FROM Sales.Customers AS Customer
     INNER JOIN Sales.Orders AS [Order]
          ON Customer.custid = [Order].custid
WHERE 
          Customer.custid <= 2
     AND [Order].orderid %2 = 0
ORDER BY Customer.custid, [Order].orderid
FOR XML RAW;


--FOR XML AUTO

SELECT 
     Customer.custid,
     Customer.companyname,
     [Order].orderid,
     [Order].orderdate
FROM Sales.Customers AS Customer
     INNER JOIN Sales.Orders AS [Order]
          ON Customer.custid = [Order].custid
WHERE 
          Customer.custid <= 2
     AND [Order].orderid %2 = 0
ORDER BY Customer.custid, [Order].orderid
FOR XML AUTO, ELEMENTS, ROOT('CustomersOrders');


--Namespaces

WITH XMLNAMESPACES('TK461-CustomersOrders' AS co)
SELECT 
     [co:Customer].custid AS [co:custid],
     [co:Customer].companyname AS [co:companyname],
     [co:Order].orderid AS [co:orderid],
     [co:Order].orderdate AS [co:orderdate]
FROM Sales.Customers AS [co:Customer]
     INNER JOIN Sales.Orders AS [co:Order]
          ON [co:Customer].custid = [co:Order].custid
WHERE 
          [co:Customer].custid <= 2
     AND [co:Order].orderid %2 = 0
ORDER BY [co:Customer].custid, [co:Order].orderid
FOR XML AUTO, ELEMENTS, ROOT('CustomersOrders');



WITH XMLNAMESPACES('TK461-CustomersOrders' AS co)
SELECT 
     [co:Customer].custid AS [co:custid],
     [co:Customer].companyname AS [co:companyname],
     [co:Order].orderid AS [co:orderid],
     [co:Order].orderdate AS [co:orderdate]
FROM Sales.Customers AS [co:Customer]
     INNER JOIN Sales.Orders AS [co:Order]
          ON [co:Customer].custid = [co:Order].custid
WHERE 
          [co:Customer].custid <= 2
     AND [co:Order].orderid %2 = 0
ORDER BY [co:Customer].custid, [co:Order].orderid
FOR XML AUTO,  ROOT('CustomersOrders');


-- create XSD
SELECT 
     [Customer].custid AS [custid],
     [Customer].companyname AS [companyname],
     [Order].orderid AS [orderid],
     [Order].orderdate AS [orderdate]
FROM Sales.Customers AS [Customer]
     INNER JOIN Sales.Orders AS [Order]
          ON [Customer].custid = [Order].custid
WHERE 1 = 2
FOR XML AUTO, ELEMENTS,
XMLSCHEMA('TK461-CustomersOrders');

--FOR XML PATH

SELECT 
     Customer.custid AS [@custid],
     Customer.companyname AS [companyname]
FROM Sales.Customers AS Customer
WHERE Customer.custid <= 2
ORDER BY Customer.custid
FOR XML PATH ('Customer'), ROOT('Customers');


-- nested for xml path
SELECT 
     Customer.custid AS [@custid],
     Customer.companyname AS [@companyname],
     (
          SELECT 
               [Order].orderid AS [@orderid],
               [Order].orderdate AS [@orderdate]
          FROM Sales.Orders AS [Order]
          WHERE Customer.custid = [Order].custid
               AND [Order].orderid %2 = 0
          ORDER BY [Order].orderid
          FOR XML PATH('Order'), TYPE
     )
FROM Sales.Customers AS Customer
WHERE Customer.custid <= 2
ORDER BY Customer.custid
FOR XML PATH('Customer'), ROOT('Customers');



--=====================================================================================================
--Shredding XML to Tables
--=====================================================================================================
DECLARE @DocHandle AS INT;
DECLARE @XmlDocument AS NVARCHAR(1000);
SET @XmlDocument = N'
     <CustomersOrders>
          <Customer custid="1">
		      <companyname>Customer NRZBB</companyname>
                  <Order orderid="10692">
                    <orderdate>2007-10-03T00:00:00</orderdate>
                  </Order>
                  <Order orderid="10702">
                    <orderdate>2007-10-13T00:00:00</orderdate>
                  </Order>
                  <Order orderid="10952">
                    <orderdate>2008-03-16T00:00:00</orderdate>
                  </Order>
          </Customer>
          <Customer custid="2">
              <companyname>Customer MLTDN</companyname>
                  <Order orderid="10308">
                    <orderdate>2006-09-18T00:00:00</orderdate>
                  </Order>
                  <Order orderid="10926">
                    <orderdate>2008-03-04T00:00:00</orderdate>
                  </Order>
          </Customer>
     </CustomersOrders>';
-- Create an internal representation
EXEC sys.sp_xml_preparedocument @DocHandle OUTPUT, @XmlDocument;

-- Attribute-centric mapping
SELECT *
FROM OPENXML (@DocHandle, '/CustomersOrders/Customer',1)
WITH (custid INT, companyname NVARCHAR(40));
-- Element-centric mapping
SELECT *
FROM OPENXML (@DocHandle, '/CustomersOrders/Customer',2)
WITH (custid INT, companyname NVARCHAR(40));
-- Attribute- and element-centric mapping
-- Combining flag 8 with flags 1 and 2
SELECT *
FROM OPENXML (@DocHandle, '/CustomersOrders/Customer',3)
WITH (custid INT, companyname NVARCHAR(40));

-- Remove the DOM
EXEC sys.sp_xml_removedocument @DocHandle;
GO


--=====================================================================================================
--Querying XML Data with XQuery
--=====================================================================================================
--XQuery

DECLARE @x AS XML;
SET @x=N'
<root>
	<a>1
        <c>3</c>
        <d>4</d>
	</a>
	<b>2</b>
</root>';
SELECT
@x.query('*') AS Complete_Sequence,
@x.query('data(*)') AS Complete_Data,
@x.query('data(root/a/c)') AS Element_c_Data;


-- XQuery

DECLARE @xx AS XML;
SET @xx='
<CustomersOrders xmlns:co="TK461-CustomersOrders">
	<co:Customer co:custid="1" co:companyname="Customer NRZBB">
		<co:Order co:orderid="10692" co:orderdate="2007-10-03T00:00:00" />
		<co:Order co:orderid="10702" co:orderdate="2007-10-13T00:00:00" />
		<co:Order co:orderid="10952" co:orderdate="2008-03-16T00:00:00" />
	</co:Customer>
	<co:Customer co:custid="2" co:companyname="Customer MLTDN">
		<co:Order co:orderid="10308" co:orderdate="2006-09-18T00:00:00" />
		<co:Order co:orderid="10926" co:orderdate="2008-03-04T00:00:00" />
	</co:Customer>
</CustomersOrders>';
-- Namespace in prolog of XQuery
SELECT @xx.query('(: explicit namespace :) declare namespace co="TK461-CustomersOrders";
//co:Customer[1]/*') AS [Explicit namespace];
-- Default namespace for all elements in prolog of XQuery
SELECT @xx.query('
(: default namespace :)
declare default element namespace "TK461-CustomersOrders";
//Customer[1]/*') AS [Default element namespace];
-- Namespace defined in WITH clause of T-SQL SELECT
WITH XMLNAMESPACES('TK461-CustomersOrders' AS co)
SELECT @xx.query('
(: namespace declared in T-SQL :)
//co:Customer[1]/*') AS [Namespace in WITH clause];


-- using XQuery functions
DECLARE @x3 AS XML;
SET @x3='
<CustomersOrders>
	<Customer custid="1" companyname="Customer NRZBB">
		<Order orderid="10692" orderdate="2007-10-03T00:00:00" />
		<Order orderid="10702" orderdate="2007-10-13T00:00:00" />
		<Order orderid="10952" orderdate="2008-03-16T00:00:00" />
	</Customer>
	<Customer custid="2" companyname="Customer MLTDN">
		<Order orderid="10308" orderdate="2006-09-18T00:00:00" />
		<Order orderid="10926" orderdate="2008-03-04T00:00:00" />
	</Customer>
</CustomersOrders>';
SELECT @x3.query('
				for $i in //Customer
				return
				<OrdersInfo>
				{ $i/@companyname }
				<NumberOfOrders>
				{ count($i/Order) }
				</NumberOfOrders>
				<LastOrder>
				{ max($i/Order/@orderid) }
				</LastOrder>
				</OrdersInfo>
');


DECLARE @x4 AS XML;
SET @x4 = N'
<CustomersOrders>
	<Customer custid="1">
		<!-- Comment 111 -->
		<companyname>Customer NRZBB</companyname>
		<Order orderid="10692">
		<orderdate>2007-10-03T00:00:00</orderdate>
		</Order>
		<Order orderid="10702">
		<orderdate>2007-10-13T00:00:00</orderdate>
		</Order>
		<Order orderid="10952">
		<orderdate>2008-03-16T00:00:00</orderdate>
		</Order>
	</Customer>
<Customer custid="2">
<!-- Comment 222 -->
<companyname>Customer MLTDN</companyname>
<Order orderid="10308">
<orderdate>2006-09-18T00:00:00</orderdate>
</Order>
<Order orderid="10952">
<orderdate>2008-03-04T00:00:00</orderdate>
</Order>
</Customer>
</CustomersOrders>';

--Return the second customer who has at least one order. The result should be similar to
--the abbreviated result here.
SELECT @x4.query('(/CustomersOrders/Customer/
Order/parent::Customer)[2]')
AS [ 2nd Customer with at least one Order];



-- update
SET @x4.modify('replace value of
/CustomersOrders[1]/Customer[1]/companyname[1]/text()[1]
with "New Company Name"');
SELECT @x4.value('(/CustomersOrders/Customer/companyname)[1]',
'NVARCHAR(20)')
AS [First Customer New Name];

select @x4

--============================================================================================
--Using the XML Data Type for Dynamic Schema
--============================================================================================
ALTER TABLE Production.Products
ADD additionalattributes XML NULL;


-- Auxiliary tables
CREATE TABLE dbo.Beverages
(
percentvitaminsRDA INT
);
CREATE TABLE dbo.Condiments
(
shortdescription NVARCHAR(50)
);
GO
-- Store the Schemas in a Variable and Create the Collection
DECLARE @mySchema NVARCHAR(MAX);
SET @mySchema = N'';
SET @mySchema = @mySchema +
(SELECT *
FROM Beverages
FOR XML AUTO, ELEMENTS, XMLSCHEMA('Beverages'));
SET @mySchema = @mySchema +
(SELECT *
FROM Condiments
FOR XML AUTO, ELEMENTS, XMLSCHEMA('Condiments'));
SELECT CAST(@mySchema AS XML);

CREATE XML SCHEMA COLLECTION dbo.ProductsAdditionalAttributes AS @mySchema;
GO

--clean up

--drop shemacollection
USE [TSQL2012]

ALTER TABLE [Production].[Products] DROP CONSTRAINT [ck_Namespace]
GO


/****** Object:  XmlSchemaCollection [ProductsAdditionalAttributes]    Script Date: 3/1/2016 9:12:17 AM ******/
DROP XML SCHEMA COLLECTION  [dbo].[ProductsAdditionalAttributes]
GO

ALTER TABLE Production.Products
DROP COLUMN additionalattributes


-- Drop Auxiliary Tables
DROP TABLE dbo.Beverages, dbo.Condiments;
GO

ALTER TABLE Production.Products
ALTER COLUMN additionalattributes
XML(dbo.ProductsAdditionalAttributes);
GO

-- Function to Retrieve the Namespace
CREATE FUNCTION dbo.GetNamespace(@chkcol XML)
RETURNS NVARCHAR(15)
AS
BEGIN
RETURN @chkcol.value('namespace-uri((/*)[1])','NVARCHAR(15)')
END;
GO
-- Function to Retrieve the Category Name
CREATE FUNCTION dbo.GetCategoryName(@catid INT)
RETURNS NVARCHAR(15)
AS
BEGIN
RETURN
(SELECT categoryname
FROM Production.Categories
WHERE categoryid = @catid)
END;
GO
-- Add the Constraint
ALTER TABLE Production.Products ADD CONSTRAINT ck_Namespace
CHECK (dbo.GetNamespace(additionalattributes) =
dbo.GetCategoryName(categoryid));
GO


-- Beverage
UPDATE Production.Products
SET additionalattributes = N'
<Beverages xmlns="Beverages">
<percentvitaminsRDA>27</percentvitaminsRDA>
</Beverages>'
WHERE productid = 1;
-- Condiment
UPDATE Production.Products
SET additionalattributes = N'
<Condiments xmlns="Condiments">
<shortdescription>very sweet</shortdescription>
</Condiments>'
WHERE productid = 3;

SELECT * FROM Production.Products
--check

-- String instead of int
UPDATE Production.Products
SET additionalattributes = N'
<Beverages xmlns="Beverages">
<percentvitaminsRDA>twenty seven</percentvitaminsRDA>
</Beverages>'
WHERE productid = 1;
-- Wrong namespace
UPDATE Production.Products
SET additionalattributes = N'
<Condiments xmlns="Condiments">
<shortdescription>very sweet</shortdescription>
</Condiments>'
WHERE productid = 2;
-- Wrong element
UPDATE Production.Products
SET additionalattributes = N'
<Condiments xmlns="Condiments">
<unknownelement>very sweet</unknownelement>
</Condiments>'
WHERE productid = 3;



--clean up

/*
ALTER TABLE Production.Products
DROP CONSTRAINT ck_Namespace;
ALTER TABLE Production.Products
DROP COLUMN additionalattributes;
DROP XML SCHEMA COLLECTION dbo.ProductsAdditionalAttributes;
DROP FUNCTION dbo.GetNamespace;
DROP FUNCTION dbo.GetCategoryName;
GO
*/


USE AdventureWorks2019;
GO 

SELECT * FROM [Production].[ProductModel];

SELECT p.Name, p.ProductNumber, pm.Instructions.query( 
  'declare namespace AW="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelManuInstructions "; 
  AW:root/AW:Location[@LaborHours>2.5]') As Locations 
FROM Production.Product p 
JOIN Production.ProductModel pm 
  ON p.ProductModelID = pm.ProductModelID 
WHERE pm.Instructions is not NULL






/*==============================================================================================================

JSON


==============================================================================================================*/


USE [TSQL2012];
GO

/*==============================================================================================================
Convert SQL Server data to JSON or export JSON
andreypotapov.database.windows.net
==============================================================================================================*/

--For json auto
SELECT 
     Customer.custid,
     Customer.companyname,
     [Order].orderid,
     [Order].orderdate
FROM Sales.Customers AS Customer
     INNER JOIN Sales.Orders AS [Order]
          ON Customer.custid = [Order].custid
WHERE 
	Customer.custid <= 2
	AND [Order].orderid %2 = 0
ORDER BY Customer.custid, [Order].orderid
FOR JSON AUTO;

--For json path
SELECT 
     Customer.custid,
     Customer.companyname,
     [Order].orderid,
     [Order].orderdate
FROM Sales.Customers AS Customer
     INNER JOIN Sales.Orders AS [Order]
          ON Customer.custid = [Order].custid
WHERE 
	Customer.custid <= 2
	AND [Order].orderid %2 = 0
ORDER BY Customer.custid, [Order].orderid
FOR JSON PATH;

--For json path: specify objects
SELECT 
     Customer.custid		AS [Customer.Id],
     Customer.companyname	AS [Customer.CompanyName],
     [Order].orderid		AS [Order.Id],
     [Order].orderdate		AS [Order.Date]
FROM Sales.Customers AS Customer
     INNER JOIN Sales.Orders AS [Order]
          ON Customer.custid = [Order].custid
WHERE 
	Customer.custid <= 2
	AND [Order].orderid %2 = 0
ORDER BY Customer.custid, [Order].orderid
FOR JSON PATH;

--For json path: root object and array
SELECT 
     Customer.custid		AS [Customer.Id],
     Customer.companyname	AS [Customer.CompanyName],
	 [Customer.Orders] = 
		 (
			  SELECT 
					[Order].orderid		AS [OrderId],
					[Order].orderdate	AS [OrderDate]
			  FROM Sales.Orders AS [Order]
			  WHERE Customer.custid = [Order].custid
					AND [Order].orderid %2 = 0
			  ORDER BY [Order].orderid
			  FOR JSON AUTO
		 )
FROM Sales.Customers AS Customer
WHERE Customer.custid <= 2
ORDER BY Customer.custid
FOR JSON PATH, ROOT('Customers');

--Null values and root array
SELECT
	custid,
	city,
	region
FROM Sales.Customers
WHERE custid = 1
FOR JSON PATH;

SELECT
	custid,
	city,
	region
FROM Sales.Customers
WHERE custid = 1
FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER;


/*==============================================================================================================
Convert JSON collections to a rowset
==============================================================================================================*/

--Verify json
DECLARE
	@GoodJSON NVARCHAR(MAX) = N'{"key": "value"}',
	@BadJSON NVARCHAR(MAX) = N'{"key" ',
	@EmptyJSON NVARCHAR(MAX);

SELECT
	ISJSON(@GoodJSON)	AS [GoodJSON],
	ISJSON(@BadJSON)	AS [BadJSON],
	ISJSON(@EmptyJSON)	AS [EmptyJSON]
;


--Simple OPENJSON
DECLARE @json NVARCHAR(MAX)
SET @json =  
N'  
   {  
      "id":2,
      "info":{  
         "name":"John",
         "surname":"Smith"
      },
      "age":25
	}
';
SELECT *  
FROM OPENJSON(@json);

GO

--Structured OPENJSON
DECLARE @json NVARCHAR(MAX)
SET @json =  
N'[  
   {  
      "id":2,
      "info":{  
         "name":"John",
         "surname":"Smith"
      },
      "age":25
   },
   {  
      "id":5,
      "info":{  
         "name":"Jane",
         "surname":"Smith"
      },
	  "age": null,
      "dob":"2005-11-04T12:00:00"
   }
]'  

SELECT *  
FROM OPENJSON(@json)  
  WITH (
            id int 'strict $.id',  
            firstName nvarchar(50) '$.info.name', 
            lastName nvarchar(50) '$.info.surname',  
            age int,		--bad practice
            dateOfBirth datetime2 '$.dob'
        );


--Strict and lax: working with missed key
DECLARE @Json1 NVARCHAR(MAX) = N'{"ID": 1}';
SELECT Id FROM OPENJSON(@Json1) WITH (Id INT '$.Id');	--The same as 'lax$.id'
SELECT Id FROM OPENJSON(@Json1) WITH (Id INT 'strict$.Id');

--Strict just check if the key exists, null is still allowed
DECLARE @Json2 NVARCHAR(MAX) = N'{"Id": null}';
SELECT Id FROM OPENJSON(@Json2) WITH (Id INT 'strict$.Id');

GO

--Array of objects

DECLARE @JSON NVARCHAR(MAX) = N'
    {
        "CustomerId": 1,
        "CompanyName": "Customer NRZBB",
        "Orders": [
          {
            "OrderId": 10692,
            "OrderDate": "2007-10-03T00:00:00"
          },
          {
            "OrderId": 10702,
            "OrderDate": "2007-10-13T00:00:00"
          }
		]
	}
';
SELECT
	cust.CustomerId, cust.CompanyName, ord.OrderId, ord.OrderDate
FROM
	OPENJSON(@JSON) WITH(
		CustomerId	INT				'strict$.CustomerId',
		CompanyName	NVARCHAR(100)	'$.CompanyName',
		Orders		NVARCHAR(MAX)	'$.Orders'		AS JSON
	) AS cust
	CROSS APPLY OPENJSON(cust.Orders) WITH(
		OrderId		INT				'$.OrderId',
		OrderDate	DATETIME		'$.OrderDate'
	) AS ord
;

GO


--Array of values

DECLARE @JSON NVARCHAR(MAX) = N'
    {
        "CustomerId": 1,
        "CompanyName": "Customer NRZBB",
        "Orders": [10692, 10702, 10952]
	}
';
SELECT
	cust.CustomerId, cust.CompanyName, ord.[value] AS OrderId
FROM
	OPENJSON(@JSON) WITH(
		CustomerId	INT				'strict$.CustomerId',
		CompanyName	NVARCHAR(100)	'$.CompanyName',
		Orders		NVARCHAR(MAX)	'$.Orders'		AS JSON
	) AS cust
	CROSS APPLY OPENJSON(cust.Orders) AS ord
;

GO


--Path in OPENJSON

DECLARE @JSON NVARCHAR(MAX) = N'
    {
        "CustomerId": 1,
        "CompanyName": "Customer NRZBB",
        "Orders": [10692, 10702, 10952]
	}
';
SELECT
	ord.[value] AS OrderId
FROM
	OPENJSON(@JSON, N'$.Orders') AS ord
;

GO


--JSON_VALUE and JSON_QUERY

DECLARE @JSON NVARCHAR(MAX) = N'
    {
        "CustomerId": 1,
        "CompanyName": "Customer NRZBB",
        "Orders": [10692, 10702, 10952]
	}
';
SELECT
	JSON_VALUE(@JSON, N'$.CustomerId')	AS CustomerId,
	JSON_VALUE(@JSON, N'$.CompanyName')	AS CompanyName,
	JSON_VALUE(@JSON, N'$.Orders[0]')	AS FirstOrderId,

	JSON_QUERY(@JSON, N'$.Orders')		AS Orders,
	JSON_QUERY(@JSON, N'$')				AS JsonData
;
GO

--Json in array wrappers
DECLARE @JSON NVARCHAR(MAX) = N'
[
	{
        "CustomerId": 1,
        "CompanyName": "Customer NRZBB",
        "Orders": [10692, 10702, 10952]
	}
]
';
SELECT
	JSON_VALUE(@JSON, N'$[0].CustomerId')	AS CustomerId,
	JSON_VALUE(@JSON, N'$[0].CompanyName')	AS CompanyName,
	JSON_VALUE(@JSON, N'$[0].Orders[0]')	AS FirstOrderId,
	JSON_QUERY(@JSON, N'$[0].Orders')		AS Orders
;
GO

/*=================================================================================================================
   - subtopicname: Change JSON values
=================================================================================================================*/
DECLARE @JSON NVARCHAR(MAX) = N'
    {
        "CustomerId": 1,
        "CompanyName": "Customer NRZBB",
        "Orders": [10692, 10702, 10952]
	}
';
SELECT
	JSON_MODIFY(@JSON, N'$.CompanyName', N'Customer AAA')
;
GO

--Multiple JSON_MODIFY
DECLARE @JSON NVARCHAR(MAX) = N'
    {
        "CustomerId": 1,
        "CompanyName": "Customer NRZBB",
        "Orders": [10692, 10702, 10952]
	}
';
SELECT
	JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(@JSON,
		N'$.CustomerId', 99),		--Update
		N'$.CompanyName', NULL),	--Delete
		N'append $.Orders', 22222)	--Add value
;


--Show MSBI.Dev.S20E06.Script.01



--=======================================================================
-- using temporary tables vs. table variables
--=======================================================================
 
--Local and Global Temp Tables
DROP TABLE IF EXISTS #Local;
DROP TABLE IF EXISTS ##Global;

CREATE TABLE #Local (   col1 INT NOT NULL );
CREATE TABLE ##Global (   col1 INT NOT NULL );

SELECT * FROM #Local;
SELECT * FROM ##Global;

DROP TABLE IF EXISTS #Local;
DROP TABLE IF EXISTS ##Global;
GO

-- Temp Table Features
DROP TABLE IF EXISTS #T1;
CREATE TABLE #T1 (   col1 INT NOT NULL ); 
 
INSERT INTO #T1(col1) VALUES(10), (11), (12); 

SELECT col1 FROM #T1;

EXEC('SELECT col1 FROM #T1;');

TRUNCATE TABLE #T1;

GO
SELECT col1 FROM #T1;
 
DROP TABLE IF EXISTS #T1;
GO

-- Table Variable Features

--ALTER DATABASE [TSQL2012] SET COMPATIBILITY_LEVEL = 140; --SQL 2017
--ALTER DATABASE [TSQL2012] SET COMPATIBILITY_LEVEL = 150; --SQL 2019

DECLARE @T1 AS TABLE (   col1 INT NOT NULL ); 
 
INSERT INTO @T1(col1) VALUES(10), (11), (12); 

SELECT * FROM @T1 --OPTION(RECOMPILE);

EXEC('SELECT col1 FROM @T1;');

--TRUNCATE TABLE @T1;
GO

--SELECT * FROM @T1;
GO



-- Transactions
DROP TABLE IF EXISTS #T1;
CREATE TABLE #T1 (   col1 INT NOT NULL ); 
 
BEGIN TRAN
  INSERT INTO #T1(col1) VALUES(10); 
ROLLBACK TRAN
 
SELECT col1 FROM #T1; 
 
DROP TABLE IF EXISTS #T1; 
GO


DECLARE @T1 AS TABLE (   col1 INT NOT NULL ); 
 
BEGIN TRAN
  INSERT INTO @T1(col1) VALUES(10);
ROLLBACK TRAN
 
SELECT col1 FROM @T1;


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


--Parent temp table
CREATE OR ALTER PROCEDURE Production.InsertProducts
AS
BEGIN
	SET NOCOUNT ON;

    INSERT Production.Products
		(productname, supplierid, categoryid, unitprice, discontinued)
	OUTPUT
		inserted.productname, inserted.supplierid, inserted.categoryid, inserted.unitprice, inserted.discontinued
	SELECT
		productname, supplierid, categoryid, unitprice, discontinued
	FROM #Products;
END;
GO

DROP TABLE IF EXISTS #Products;
CREATE TABLE #Products
(
	[productname] [nvarchar](40) NOT NULL,
	[supplierid] [int] NOT NULL,
	[categoryid] [int] NOT NULL,
	[unitprice] [money] NOT NULL,
	[discontinued] [bit] NOT NULL,
);


INSERT INTO #Products
	(productname, supplierid, categoryid, unitprice, discontinued)
VALUES
	(N'New Product 5', 1, 1, 10.0, 0),
	(N'New Product 6', 1, 1, 10.0, 0);
;

EXEC Production.InsertProducts;
GO


--Clean up
DROP TYPE IF EXISTS [typ_ProductTable];
DELETE Production.Products WHERE productname LIKE N'New Product%';
GO