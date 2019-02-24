/*=========================================
MSBI.DEV.S19E06.SCRIPT
=========================================*/


--SARG show 

create table dbo.Data
(
     VarcharKey varchar(10) not null,
     Placeholder char(200)
);
create unique clustered index IDX_Data_VarcharKey
on dbo.Data(VarcharKey);

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 CROSS JOIN N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 CROSS JOIN N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 CROSS JOIN N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 CROSS JOIN N4 as T2) -- 65,536 rows
,IDs(ID) as (select row_number() over (order by (select NULL)) from N5)
insert into dbo.Data(VarcharKey)
select convert(varchar(10),ID)
from IDs;

declare
@IntParam int = '200'
select * from dbo.Data where VarcharKey = @IntParam
select * from dbo.Data where VarcharKey = convert(varchar(10),@IntParam)


/*=========================================
XML Returning Results As XML with FOR XML
=========================================*/

 --start
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


-- add root

--FOR XML AUTO

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
FOR XML RAW,  ROOT('CustomersOrders');


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
FROM OPENXML (@DocHandle, '/CustomersOrders/Customer',11)
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


USE AdventureWorks2016CTP3 
GO 
SELECT p.Name, p.ProductNumber, pm.Instructions.query( 
  'declare namespace AW="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelManuInstructions "; 
  AW:root/AW:Location[@LaborHours>2.5]') As Locations 
FROM Production.Product p 
JOIN Production.ProductModel pm 
  ON p.ProductModelID = pm.ProductModelID 
WHERE pm.Instructions is not NULL


SELECT * FROM [Production].[ProductModel]



/*==============================================================================================================

JSON


==============================================================================================================*/


/*==============================================================================================================
Convert JSON collections to a rowset
==============================================================================================================*/

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
      "dob":"2005-11-04T12:00:00"
   }
]'  

SELECT *  
FROM OPENJSON(@json)  
  WITH (
            id int 'strict $.id',  
            firstName nvarchar(50) '$.info.name', 
            lastName nvarchar(50) '$.info.surname',  
            age int, 
            dateOfBirth datetime2 '$.dob'
        )  

/*==============================================================================================================
Convert SQL Server data to JSON or export JSON
andreypotapov.database.windows.net
==============================================================================================================*/
SELECT TOP(2)
    t.TaskId AS "Task.TaskId"
    ,t.Name AS "Task.Name"
    ,stl.[SubTaskLogId]
    ,stl.[StudentId] AS "Student.UserId"
    ,stud.[DisplayName] AS "Student.Name"
    ,stl.[SubTaskId] AS  "SubTask.SubTaskId"
    ,st.SubTaskName AS  "SubTask.Name"
    --,stl.[ReviewerId]
    ,stl.[Comment]
    ,stl.[Score]
    ,stl.[OnTime]
    ,stl.[Accuracy]
    ,stl.[Extra]
    ,stl.[TotalScore]
  FROM [task].[SubTaskLog] AS stl
      INNER JOIN [task].[SubTask] AS st
        ON st.SubTaskId = stl.SubTaskId
        INNER JOIN [task].[Task] AS t
            ON t.TaskId = st.TaskId
        INNER JOIN [dbo].[Users] AS stud
         ON  stud.[ID]= stl.StudentId
    ORDER BY t.TaskId  DESC
FOR JSON PATH

SELECT Name,Surname,
     JSON_VALUE(jsonCol,'$.info.address.PostCode') AS PostCode,
     JSON_VALUE(jsonCol,'$.info.address."Address Line 1"')+' '
     +JSON_VALUE(jsonCol,'$.info.address."Address Line 2"') AS Address,
     JSON_QUERY(jsonCol,'$.info.skills') AS Skills FROM People WHERE ISJSON(jsonCol)>0
 AND JSON_VALUE(jsonCol,'$.info.address.Town')='Belgrade'
 AND Status='Active'ORDER BY JSON_VALUE(jsonCol,'$.info.address.PostCode')

/*
andreypotapov.database.windows.net
*/
/*=================================================================================================================
   - subtopicname: Extract values from JSON text and use them in queries
=================================================================================================================*/
SELECT Name,Surname, JSON_VALUE(jsonCol,'$.info.address.PostCode') AS PostCode, JSON_VALUE(jsonCol,'$.info.address."Address Line 1"')+' '  +JSON_VALUE(jsonCol,'$.info.address."Address Line 2"') AS Address, JSON_QUERY(jsonCol,'$.info.skills') AS SkillsFROM PeopleWHERE ISJSON(jsonCol)>0 AND JSON_VALUE(jsonCol,'$.info.address.Town')='Belgrade' AND Status='Active'ORDER BY JSON_VALUE(jsonCol,'$.info.address.PostCode')

/*=================================================================================================================
   - subtopicname: Change JSON values
=================================================================================================================*/
   DECLARE @jsonInfo NVARCHAR(MAX)
SET @jsonInfo=JSON_MODIFY(@jsonInfo,'$.info.address[0].town','London') 

/*=================================================================================================================
   - subtopicname: Convert JSON collections to a rowset
=================================================================================================================*/
DECLARE @json NVARCHAR(MAX)SET @json =  N'[         { "id" : 2,"info": { "name": "John", "surname": "Smith" }, "age": 25 },         { "id" : 5,"info": { "name": "Jane", "surname": "Smith" }, "dob": "2005-11-04T12:00:00" }   ]'  
SELECT *  FROM OPENJSON(@json)    WITH (        id int 'strict $.id',          firstName nvarchar(50) '$.info.name',         lastName nvarchar(50) '$.info.surname',          age int, dateOfBirth datetime2 '$.dob'
        )  

/*=================================================================================================================
   - subtopicname: Convert SQL Server data to JSON or export JSON
=================================================================================================================*/
   