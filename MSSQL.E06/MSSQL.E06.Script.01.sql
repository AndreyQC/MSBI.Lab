/*=========================================
MSBI.DEV.S21E10.SCRIPT
=========================================*/

USE [TSQL2012];


/*=========================================
Blocking observation
=========================================*/

DROP VIEW IF EXISTS DBlocks ;
GO
CREATE VIEW DBlocks 
AS
	SELECT
		request_session_id AS spid ,
		DB_NAME(resource_database_id) AS dbname ,
		CASE
			WHEN resource_type = 'OBJECT'
				THEN OBJECT_NAME(resource_associated_entity_id)
			WHEN resource_associated_entity_id = 0
				THEN 'n/a'
			ELSE OBJECT_NAME(p.object_id)
		END AS entity_name ,
		index_id ,
		resource_type AS resource ,
		resource_description AS description ,
		request_mode AS mode ,
		request_status AS status
	FROM
		sys.dm_tran_locks t
		LEFT JOIN sys.partitions p
			ON p.partition_id = t.resource_associated_entity_id
	WHERE
		resource_database_id = DB_ID()
		AND resource_type <> 'DATABASE' ;
GO

SELECT TOP 1000 [spid]
      ,[dbname]
      ,[entity_name]
      ,[index_id]
      ,[resource]
      ,[description]
      ,[mode]
      ,[status]
  FROM [TSQL2012].[dbo].[DBlocks]
WHERE [mode] IN ('S', 'X')


EXEC sp_who2;

--Show MSSQL.E06.Script.02.blocking.sql


--=======================================================================
--Using temporary tables vs. table variables
--=======================================================================
 
--Local and Global Temp Tables
DROP TABLE IF EXISTS #Local;
DROP TABLE IF EXISTS ##Global;

CREATE TABLE #Local (   col1 INT NOT NULL );
CREATE TABLE ##Global (   col1 INT NOT NULL );

SELECT * FROM #Local;
SELECT * FROM ##Global;
--Try the same in another session

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
FOR XML AUTO,  ROOT('CustomersOrders');



--FOR XML PATH

SELECT 
     Customer.custid		AS [@custid],
     Customer.companyname	AS [companyname]
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
     ) AS [Orders]
FROM Sales.Customers AS Customer
WHERE Customer.custid <= 2
ORDER BY Customer.custid
FOR XML PATH('Customer'), ROOT('Customers');



--=====================================================================================================
--Shredding XML to Tables
--=====================================================================================================

--Basic example

DECLARE @DocHandle AS INT;
DECLARE @XmlDocument AS NVARCHAR(2000);
SET @XmlDocument = N'
     <CustomersOrders>
          <Customer custid="1">
		      <companyname>Customer NRZBB</companyname>
			  <Orders>
                  <Order orderid="10692">
                    <orderdate>2007-10-03T00:00:00</orderdate>
                  </Order>
                  <Order orderid="10702">
                    <orderdate>2007-10-13T00:00:00</orderdate>
                  </Order>
                  <Order orderid="10952">
                    <orderdate>2008-03-16T00:00:00</orderdate>
                  </Order>
				</Orders>
          </Customer>
          <Customer custid="2">
              <companyname>Customer MLTDN</companyname>
			  <Orders>
                  <Order orderid="10308">
                    <orderdate>2006-09-18T00:00:00</orderdate>
                  </Order>
                  <Order orderid="10926">
                    <orderdate>2008-03-04T00:00:00</orderdate>
                  </Order>
				</Orders>
          </Customer>
     </CustomersOrders>';
-- Create an internal representation
EXEC sys.sp_xml_preparedocument @DocHandle OUTPUT, @XmlDocument;

SELECT
	custid,
	companyname
FROM
	OPENXML (@DocHandle, '/CustomersOrders/Customer') WITH (
		custid		INT				'@custid',
		companyname NVARCHAR(40)	'companyname'
	);

-- Remove the DOM
EXEC sys.sp_xml_removedocument @DocHandle;
GO


--Specifying paths

DECLARE @DocHandle AS INT;
DECLARE @XmlDocument AS NVARCHAR(2000);
SET @XmlDocument = N'
     <CustomersOrders>
          <Customer custid="1">
		      <companyname>Customer NRZBB</companyname>
			  <Orders>
                  <Order orderid="10692">
                    <orderdate>2007-10-03T00:00:00</orderdate>
                  </Order>
                  <Order orderid="10702">
                    <orderdate>2007-10-13T00:00:00</orderdate>
                  </Order>
                  <Order orderid="10952">
                    <orderdate>2008-03-16T00:00:00</orderdate>
                  </Order>
				</Orders>
          </Customer>
          <Customer custid="2">
              <companyname>Customer MLTDN</companyname>
			  <Orders>
                  <Order orderid="10308">
                    <orderdate>2006-09-18T00:00:00</orderdate>
                  </Order>
                  <Order orderid="10926">
                    <orderdate>2008-03-04T00:00:00</orderdate>
                  </Order>
				</Orders>
          </Customer>
     </CustomersOrders>';
-- Create an internal representation
EXEC sys.sp_xml_preparedocument @DocHandle OUTPUT, @XmlDocument;

SELECT
	custid,
	companyname,
	orderid,
	orderdate
FROM
	OPENXML (@DocHandle, '/CustomersOrders/Customer/Orders') WITH (
		orderid		INT				'Order/@orderid',
		orderdate	DATETIME		'Order/orderdate',
		custid		INT				'../@custid',
		companyname NVARCHAR(40)	'../companyname'
	);

-- Remove the DOM
EXEC sys.sp_xml_removedocument @DocHandle;
GO


DECLARE @DocHandle AS INT;
DECLARE @XmlDocument AS NVARCHAR(2000);
SET @XmlDocument = N'
     <CustomersOrders>
          <Customer custid="1">
		      <companyname>Customer NRZBB</companyname>
			  <Orders>
                  <Order orderid="10692">
                    <orderdate>2007-10-03T00:00:00</orderdate>
                  </Order>
                  <Order orderid="10702">
                    <orderdate>2007-10-13T00:00:00</orderdate>
                  </Order>
                  <Order orderid="10952">
                    <orderdate>2008-03-16T00:00:00</orderdate>
                  </Order>
				</Orders>
          </Customer>
          <Customer custid="2">
              <companyname>Customer MLTDN</companyname>
			  <Orders>
                  <Order orderid="10308">
                    <orderdate>2006-09-18T00:00:00</orderdate>
                  </Order>
                  <Order orderid="10926">
                    <orderdate>2008-03-04T00:00:00</orderdate>
                  </Order>
				</Orders>
          </Customer>
     </CustomersOrders>';
-- Create an internal representation
EXEC sys.sp_xml_preparedocument @DocHandle OUTPUT, @XmlDocument;

SELECT
	custid,
	companyname,
	orderid,
	orderdate
FROM
	OPENXML (@DocHandle, '/CustomersOrders/Customer/Orders/Order') WITH (
		orderid		INT				'@orderid',
		orderdate	DATETIME		'orderdate',
		custid		INT				'../../@custid',
		companyname NVARCHAR(40)	'../../companyname'
	);

-- Remove the DOM
EXEC sys.sp_xml_removedocument @DocHandle;
GO



--Working with namespaces

DECLARE @DocHandle AS INT;
DECLARE @XmlDocument AS NVARCHAR(2000);
SET @XmlDocument = N'
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

-- Create an internal representation
EXEC sys.sp_xml_preparedocument @DocHandle OUTPUT, @XmlDocument, '<CustomersOrders xmlns:co="TK461-CustomersOrders"/>';

SELECT
	custid,
	companyname
FROM
	OPENXML (@DocHandle, '/CustomersOrders/co:Customer') WITH (
		custid		INT				'@co:custid',
		companyname NVARCHAR(40)	'@co:companyname'
	);


-- Remove the DOM
EXEC sys.sp_xml_removedocument @DocHandle;
GO


--=====================================================================================================
--XML Data Type Methods
--=====================================================================================================

--Value
DECLARE @XmlDocument AS XML;
SET @XmlDocument = N'
     <CustomersOrders>
          <Customer custid="1">
		      <companyname>Customer NRZBB</companyname>
			  <Orders>
                  <Order orderid="10692">
                    <orderdate>2007-10-03T00:00:00</orderdate>
                  </Order>
                  <Order orderid="10702">
                    <orderdate>2007-10-13T00:00:00</orderdate>
                  </Order>
                  <Order orderid="10952">
                    <orderdate>2008-03-16T00:00:00</orderdate>
                  </Order>
				</Orders>
          </Customer>
          <Customer custid="2">
              <companyname>Customer MLTDN</companyname>
			  <Orders>
                  <Order orderid="10308">
                    <orderdate>2006-09-18T00:00:00</orderdate>
                  </Order>
                  <Order orderid="10926">
                    <orderdate>2008-03-04T00:00:00</orderdate>
                  </Order>
				</Orders>
          </Customer>
     </CustomersOrders>';

SELECT
	custid		= @XmlDocument.value('(/CustomersOrders/Customer/@custid)[1]',		'int'),
	companyname	= @XmlDocument.value('(/CustomersOrders/Customer/companyname)[1]',	'nvarchar(100)');

GO

--Nodes
DECLARE @XmlDocument AS XML;
SET @XmlDocument = N'
     <CustomersOrders>
          <Customer custid="1">
		      <companyname>Customer NRZBB</companyname>
			  <Orders>
                  <Order orderid="10692">
                    <orderdate>2007-10-03T00:00:00</orderdate>
                  </Order>
                  <Order orderid="10702">
                    <orderdate>2007-10-13T00:00:00</orderdate>
                  </Order>
                  <Order orderid="10952">
                    <orderdate>2008-03-16T00:00:00</orderdate>
                  </Order>
				</Orders>
          </Customer>
          <Customer custid="2">
              <companyname>Customer MLTDN</companyname>
			  <Orders>
                  <Order orderid="10308">
                    <orderdate>2006-09-18T00:00:00</orderdate>
                  </Order>
                  <Order orderid="10926">
                    <orderdate>2008-03-04T00:00:00</orderdate>
                  </Order>
				</Orders>
          </Customer>
     </CustomersOrders>';

SELECT
	custid		= cstm.value('@custid[1]',		'int'),
	companyname	= cstm.value('companyname[1]',	'nvarchar(100)')
FROM @XmlDocument.nodes('/CustomersOrders/Customer') AS nds(cstm); 

GO

--Nodes with APPLY
DECLARE @XmlDocument AS XML;
SET @XmlDocument = N'
     <CustomersOrders>
          <Customer custid="1">
		      <companyname>Customer NRZBB</companyname>
			  <Orders>
                  <Order orderid="10692">
                    <orderdate>2007-10-03T00:00:00</orderdate>
                  </Order>
                  <Order orderid="10702">
                    <orderdate>2007-10-13T00:00:00</orderdate>
                  </Order>
                  <Order orderid="10952">
                    <orderdate>2008-03-16T00:00:00</orderdate>
                  </Order>
				</Orders>
          </Customer>
          <Customer custid="2">
              <companyname>Customer MLTDN</companyname>
			  <Orders>
                  <Order orderid="10308">
                    <orderdate>2006-09-18T00:00:00</orderdate>
                  </Order>
                  <Order orderid="10926">
                    <orderdate>2008-03-04T00:00:00</orderdate>
                  </Order>
				</Orders>
          </Customer>
     </CustomersOrders>';

SELECT
	custid		= cstm.value('@custid[1]',		'int'),
	companyname	= cstm.value('companyname[1]',	'nvarchar(100)'),
	orderid		= ord.value('@orderid[1]',		'int'),
	orderdate	= ord.value('orderdate[1]',		'datetime')
FROM
	@XmlDocument.nodes('/CustomersOrders/Customer') AS nds1(cstm)
	CROSS APPLY nds1.cstm.nodes('Orders/Order') AS nds2(ord); 

GO



--Working with XML data type stored in DB
USE [AdventureWorks2019];
GO

SELECT
	[BusinessEntityID],
	[FirstName],
	[LastName],
	[AdditionalContactInfo]
FROM [Person].[Person]
WHERE [AdditionalContactInfo] IS NOT NULL



WITH XMLNAMESPACES (
	DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ContactInfo',
	'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ContactTypes' AS act,
	'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ContactRecord' AS crm
)
SELECT
	[BusinessEntityID],
	[FirstName],
	[LastName],
	[Phone]	= phn.value('act:number[1]', 'varchar(100)')
FROM
	[Person].[Person] AS psn
	OUTER APPLY psn.AdditionalContactInfo.nodes('/AdditionalContactInfo/act:telephoneNumber') AS nds(phn)
WHERE [AdditionalContactInfo] IS NOT NULL;



--Query Method (XQuery)
WITH XMLNAMESPACES (
	DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ContactInfo',
	'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ContactTypes' AS act,
	'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ContactRecord' AS crm
)
SELECT
	[BusinessEntityID],
	[FirstName],
	[LastName],
	[Element]		= phn.query('*'),
	[ElementValue]	= phn.query('data(act:telephoneNumber/act:number)[1]'),
	[ElementCount]	= phn.query('count(act:telephoneNumber/act:number)')
FROM
	[Person].[Person] AS psn
	OUTER APPLY psn.AdditionalContactInfo.nodes('/AdditionalContactInfo') AS nds(phn)
WHERE [AdditionalContactInfo] IS NOT NULL;




/*==============================================================================================================

JSON


==============================================================================================================*/


USE [TSQL2012];
GO

/*==============================================================================================================
Convert SQL Server data to JSON or export JSON
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
            id			int				'$.id',  
            firstName	nvarchar(50)	'$.info.name', 
            lastName	nvarchar(50)	'$.info.surname',  
            age			int,		--bad practice
            dateOfBirth	datetime2		'$.dob'
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


--Show MSSQL.E06.Script.04.json.sql

