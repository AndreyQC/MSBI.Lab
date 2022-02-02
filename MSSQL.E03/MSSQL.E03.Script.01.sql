/*=========================================
MSSQL.E03.Script.01.sql
=========================================*/

USE [TSQL2012];
GO


/*======================================================================================================================================================
 Using Subqueries, Table Expressions, and the APPLY Operator
========================================================================================================================================================*/
  
/*---------------------------------------------------------------------------------------- 
 Self-Contained Subqueries 
-----------------------------------------------------------------------------------------*/

SELECT 
    productid,
    productname,
    unitprice
FROM Production.Products
WHERE unitprice =
    (
        SELECT MIN(unitprice)
        FROM Production.Products
    );

--Error
SELECT 
    productid,
    productname,
    unitprice
FROM Production.Products
WHERE unitprice =
    (
        SELECT Top(10) unitprice
        FROM Production.Products
    );


	--often they use for filtering
SELECT 
    productid,
    productname,
    unitprice
FROM Production.Products
WHERE supplierid IN
    (
        SELECT supplierid
        FROM Production.Suppliers
        WHERE country = N'Japan'
    );

--Error
SELECT 
    productid,
    productname,
    unitprice
FROM Production.Products
WHERE supplierid IN
    (
        SELECT *
        FROM Production.Suppliers
        WHERE country = N'Japan'
    );


--Compare postal codes in two tables
SELECT DISTINCT postalcode FROM [Production].[Suppliers]
SELECT DISTINCT shippostalcode FROM [Sales].[Orders]
--Will the query return anything?
SELECT
	shippostalcode
FROM
	Sales.Orders
WHERE
	shippostalcode IN (
		SELECT shippostalcode FROM Production.Suppliers
	);



--The best practice is to specify table aliases if the query uses more than one table
SELECT
	ord.shippostalcode
FROM
	Sales.Orders AS ord
WHERE
	ord.shippostalcode IN (
		--SELECT spl.shippostalcode FROM Production.Suppliers AS spl
		SELECT spl.postalcode FROM Production.Suppliers AS spl
	);


--Be careful with NULL
SELECT 
    productid,
    productname,
    unitprice
FROM Production.Products
WHERE productid IN (1, 2, NULL);

--id = 1 OR id = 2 OR id = NULL
--true or false or unknown = TRUE


SELECT
    productid,
    productname,
    unitprice
FROM Production.Products
WHERE productid NOT IN (1, 2, NULL);

--id <> 1 AND id <> 2 AND id <> NULL
--true and true and unknown = FALSE


/*---------------------------------------------------------------------------------------- 
 Correlated Subqueries
-----------------------------------------------------------------------------------------*/

SELECT 
    categoryid,
    productid,
    productname,
    unitprice
FROM Production.Products AS P1
WHERE unitprice =
        (
            SELECT MIN(unitprice)
            FROM Production.Products AS P2
            WHERE P2.categoryid = P1.categoryid
        );


-- common practice
/*
EXISTS doesnt need to return the result set of the subquery; rather, it
returns only true or false, depending on whether the subquery returns any rows. For this reason,
the SQL Server Query Optimizer ignores the SELECT list of the subquery, and therefore,
whatever you specify there will not affect optimization choices like index selection.
*/


SELECT 
    custid,
    companyname
FROM Sales.Customers AS C
WHERE EXISTS
    (
        SELECT 1
        FROM Sales.Orders AS O
        WHERE O.custid = C.custid
        AND O.orderdate = '20070214'
    );

-- negative
SELECT 
    custid,
    companyname
FROM Sales.Customers AS C
WHERE NOT EXISTS
    (
        SELECT 1
        FROM Sales.Orders AS O
        WHERE O.custid = C.custid
        AND O.orderdate = '20070212'
    );


/*---------------------------------------------------------------------------------------- 
 Derived Tables
-----------------------------------------------------------------------------------------*/


SELECT categoryid, productid, productname, unitprice
FROM 
(
    SELECT
        ROW_NUMBER() OVER(PARTITION BY categoryid ORDER BY unitprice, productid) AS rownum,
        categoryid,
        productid,
        productname,
        unitprice
    FROM Production.Products
) AS D
WHERE rownum <= 2;


/*---------------------------------------------------------------------------------------- 
 CTEs
-----------------------------------------------------------------------------------------*/
WITH C AS
(
    SELECT
        ROW_NUMBER() OVER(PARTITION BY categoryid ORDER BY unitprice, productid) AS rownum,
        categoryid,
        productid,
        productname,
        unitprice
    FROM Production.Products
)
SELECT 
    categoryid,
    productid,
    productname,
    unitprice
FROM C
WHERE rownum <= 2;



WITH EmpsCTE AS(
    SELECT empid, mgrid, firstname, lastname
    FROM HR.Employees
)
SELECT
	Emp.empid,
	Emp.firstname,
	Emp.lastname,
	Emp.mgrid,
	Mgr.firstname AS mgrfirstname,
	Mgr.lastname AS mgrlastname
FROM
	EmpsCTE				AS Emp
	LEFT JOIN EmpsCTE	AS Mgr		ON Mgr.[empid] = Emp.[mgrid]
;


/*---------------------------------------------------------------------------------------- 
 Recursive CTE
-----------------------------------------------------------------------------------------*/


WITH EmpsCTE AS
(
    SELECT empid, mgrid, firstname, lastname, 0 AS distance
    FROM HR.Employees
    WHERE empid = 9

    UNION ALL

    SELECT M.empid, M.mgrid, M.firstname, M.lastname, S.distance + 1 AS distance
    FROM EmpsCTE AS S
        JOIN HR.Employees AS M
            ON S.mgrid = M.empid
)
SELECT empid, mgrid, firstname, lastname, distance
FROM EmpsCTE;

--The same logic
SELECT empid, mgrid, firstname, lastname, 0 AS distance
FROM HR.Employees
WHERE empid = 9

UNION ALL
SELECT empid, mgrid, firstname, lastname, 1 AS distance
FROM HR.Employees
WHERE empid = 5

UNION ALL
SELECT empid, mgrid, firstname, lastname, 2 AS distance
FROM HR.Employees
WHERE empid = 2

UNION ALL
SELECT empid, mgrid, firstname, lastname, 3 AS distance
FROM HR.Employees
WHERE empid = 1;


--Opposite direction: from managers downto subordinates
WITH EmpsCTE AS
(
    SELECT empid, mgrid, firstname, lastname, 0 AS distance
    FROM HR.Employees
    WHERE mgrid IS NULL

    UNION ALL

    SELECT M.empid, M.mgrid, M.firstname, M.lastname, S.distance + 1 AS distance
    FROM EmpsCTE AS S
        JOIN HR.Employees AS M
            ON S.empid = M.mgrid
)
SELECT empid, mgrid, firstname, lastname, distance
FROM EmpsCTE;


SELECT empid, mgrid, firstname, lastname, 0 AS distance
FROM HR.Employees
WHERE mgrid IS NULL

UNION ALL
SELECT empid, mgrid, firstname, lastname, 1 AS distance
FROM HR.Employees
WHERE mgrid = 1
    
UNION ALL
SELECT empid, mgrid, firstname, lastname, 2 AS distance
FROM HR.Employees
WHERE mgrid = 2
    
UNION ALL
SELECT empid, mgrid, firstname, lastname, 3 AS distance
FROM HR.Employees
WHERE mgrid IN (3,5)

UNION ALL
SELECT empid, mgrid, firstname, lastname, 3 AS distance
FROM HR.Employees
WHERE mgrid IN (4, 6, 7, 8, 9);



/*---------------------------------------------------------------------------------------- 
 APPLY Operator
-----------------------------------------------------------------------------------------*/


--*************************************************************************
-- CROSS APPLY
--*************************************************************************


IF NOT EXISTS(SELECT 1 FROM Production.Suppliers WHERE companyname = N'Supplier XYZ')
	INSERT INTO Production.Suppliers
		(companyname, contactname, contacttitle, address, city, postalcode, country, phone)
	VALUES(N'Supplier XYZ', N'Jiru', N'Head of Security', N'42 Sekimai Musashino-shi',
		N'Tokyo', N'01759', N'Japan', N'(02) 4311-2609');
--This supplier does not have any related products in the Production.Products table and is used in examples demonstrating nonmatches.


SELECT S.supplierid, S.companyname AS supplier
FROM Production.Suppliers AS S
WHERE S.country = N'Japan'


--As a more practical example, suppose that you write a query that returns the two products
--with the lowest unit prices for a specified suppliersay, supplier 1.

SELECT productid, productname, unitprice
FROM Production.Products
WHERE supplierid = 1
ORDER BY unitprice, productid
OFFSET 0 ROWS FETCH FIRST 2 ROWS ONLY;


SELECT S.supplierid, S.companyname AS supplier, A.*
FROM Production.Suppliers AS S
    CROSS APPLY 
        (
            SELECT productid, productname, unitprice
            FROM Production.Products AS P
            WHERE P.supplierid = S.supplierid
            ORDER BY unitprice, productid
            OFFSET 0 ROWS FETCH FIRST 2 ROWS ONLY
        ) AS A
    WHERE S.country = N'Japan';


SELECT S.supplierid, S.companyname AS supplier, A.*
FROM Production.Suppliers AS S
    OUTER APPLY  
        (
            SELECT productid, productname, unitprice
            FROM Production.Products AS P
            WHERE P.supplierid = S.supplierid
            ORDER BY unitprice, productid
            OFFSET 0 ROWS FETCH FIRST 2 ROWS ONLY
        ) AS A
    WHERE S.country = N'Japan';



--Clean up
DELETE
FROM Production.Suppliers
WHERE companyname = N'Supplier XYZ';


/*========================================================================================================================
- topicname: Grouping and Windowing
  subtopics:
   - subtopicname: Working with a Single Grouping Set
   - subtopicname: Working with Multiple Grouping Sets
========================================================================================================================*/

/*---------------------------------------------------------------------------------------- 
   - subtopicname: Working with a Single Grouping Set
-----------------------------------------------------------------------------------------*/

USE TSQL2012;

SELECT * FROM Sales.Orders

SELECT COUNT(*) AS NumOrders, MAX(freight) AS MaxFreight, MIN(freight) AS MinFreight
FROM Sales.Orders;


SELECT * FROM Sales.Orders; 

SELECT shipperid, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY shipperid;

-- group by several 
SELECT 
    shipperid,
    YEAR(shippeddate) AS shippedyear,
    COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY shipperid, YEAR(shippeddate)
ORDER BY shipperid;


-- filtering on group level
SELECT 
    shipperid,
    YEAR(shippeddate) AS shippedyear,
    COUNT(*) AS numorders
FROM Sales.Orders
WHERE shippeddate IS NOT NULL
GROUP BY shipperid, YEAR(shippeddate)
HAVING COUNT(*) > 100;

--HAVING can include the same columns as SELECT
SELECT 
    shipperid,
    YEAR(shippeddate) AS shippedyear,
    COUNT(*) AS numorders
FROM Sales.Orders
WHERE shippeddate IS NOT NULL
GROUP BY shipperid, YEAR(shippeddate)
HAVING COUNT(*) > 100
	OR shipperid = 1;


SELECT 
    shipperid,
    COUNT(*) AS numorders,
    COUNT(shippeddate) AS shippedorders,  -- <- Attention ignore NULL
    COUNT(DISTINCT shippeddate) AS numshippedorders,
	APPROX_COUNT_DISTINCT(shippeddate) AS aproxshippedorders,
    MIN(shippeddate) AS firstshipdate,
    MAX(shippeddate) AS lastshipdate,
    SUM(val) AS totalvalue
FROM Sales.OrderValues
GROUP BY shipperid;

--Note that the DISTINCT option is available not only to the COUNT function, but also to
--other general set functions. However, its more common to use it with COUNT.

--STRING_AGG
SELECT
	*
FROM
	[Sales].[Shippers]
;

SELECT
	STRING_AGG([companyname], N';') AS [AllCompanies]
FROM
	[Sales].[Shippers]
;

SELECT
	[value]
FROM
	STRING_SPLIT(N'Shipper GVSUA;Shipper ETYNR;Shipper ZHISN', N';')
;


-- !!!try to explain why this query is not valid?
SELECT 
    S.shipperid,
    --S.companyname,
    COUNT(*) AS numorders
FROM Sales.Shippers AS S
    JOIN Sales.Orders AS O
        ON S.shipperid = O.shipperid
GROUP BY S.shipperid;

-- How to get company name

-- Op1

SELECT 
    S.shipperid,
    S.companyname,
    COUNT(*) AS numorders
FROM Sales.Shippers AS S
    INNER JOIN Sales.Orders AS O
        ON S.shipperid = O.shipperid
GROUP BY S.shipperid, S.companyname;


--Op2

SELECT 
    S.shipperid,
    MAX(S.companyname) AS companyname,
    COUNT(*) AS numorders
FROM Sales.Shippers AS S
    INNER JOIN Sales.Orders AS O
        ON S.shipperid = O.shipperid
GROUP BY S.shipperid;

--Op3

WITH C AS
(
    SELECT shipperid,
           COUNT(*) AS numorders
    FROM Sales.Orders
    GROUP BY shipperid
)
SELECT 
    S.shipperid,
    S.companyname,
    numorders
FROM Sales.Shippers AS S
    INNER JOIN C
        ON S.shipperid = C.shipperid;


/*---------------------------------------------------------------------------------------- 
   - subtopicname: Working with Multiple Grouping Sets
-----------------------------------------------------------------------------------------*/


--GROUPING SETS

SELECT shipperid, YEAR(shippeddate) AS shipyear, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY GROUPING SETS
(
    ( shipperid, YEAR(shippeddate) ),
    ( YEAR(shippeddate) ),
    ( )
)
;

--The same logic
SELECT shipperid, YEAR(shippeddate) AS shipyear, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY shipperid, YEAR(shippeddate)

UNION ALL
SELECT NULL AS shipperid, YEAR(shippeddate) AS shipyear, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY YEAR(shippeddate)

UNION ALL
SELECT NULL AS shipperid, NULL AS shipyear, COUNT(*) AS numorders
FROM Sales.Orders



-- CUBE
SELECT shipperid, YEAR(shippeddate) AS shipyear, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY CUBE( shipperid, YEAR(shippeddate) );
-- will define all possible sets
--( shipperid, YEAR(shippeddate) )
--( shipperid )
--( YEAR(shippeddate) )
--( )


--ROLLUP
 -- use hierarchy
SELECT shipcountry, shipregion, shipcity, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY ROLLUP( shipcountry, shipregion, shipcity )
--( shipcountry, shipregion, shipcity )
--( shipcountry, shipregion )
--( shipcountry )
--( )


-- to make more convinient to use
SELECT
    shipcountry,	GROUPING(shipcountry) AS grpcountry,
    shipregion,		GROUPING(shipregion) AS grpregion,
    shipcity,		GROUPING(shipcity) AS grpcity,
    COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY ROLLUP( shipcountry, shipregion, shipcity );



SELECT 
    GROUPING_ID( shipcountry, shipregion, shipcity ) AS grp_id,
    shipcountry, 
    shipregion, 
    shipcity,
    COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY ROLLUP( shipcountry, shipregion, shipcity );

/*========================================================================================================================
- topicname: Pivoting and Unpivoting Data
  subtopics:
   - subtopicname: Pivoting Data
   - subtopicname: Unpivoting Data
========================================================================================================================*/

/*---------------------------------------------------------------------------------------- 
   - subtopicname: Pivoting Data
-----------------------------------------------------------------------------------------*/

WITH PivotData AS
(
	SELECT
		custid , -- grouping column
		shipperid, -- spreading column
		freight -- aggregation column
	FROM Sales.Orders
)
SELECT custid, [1], [2], [3], [4]
FROM PivotData
PIVOT(SUM(freight) FOR shipperid IN ([1],[2],[3],[4]) ) AS P;

--Wrong
SELECT custid, [1], [2], [3]
FROM Sales.Orders
PIVOT(SUM(freight) FOR shipperid IN ([1],[2],[3]) ) AS P;


--Alternate option
SELECT
	custid,
	SUM(CASE WHEN shipperid = 1 THEN freight END) AS [1],
	SUM(CASE WHEN shipperid = 2 THEN freight END) AS [2],
	SUM(CASE WHEN shipperid = 3 THEN freight END) AS [3],
	SUM(CASE WHEN shipperid = 4 THEN freight END) AS [4]
FROM Sales.Orders
GROUP BY custid

/*---------------------------------------------------------------------------------------- 
   - subtopicname: Unpivoting Data
-----------------------------------------------------------------------------------------*/

USE TSQL2012;
IF OBJECT_ID('Sales.FreightTotals') IS NOT NULL DROP TABLE Sales.FreightTotals;
GO
WITH PivotData AS
(
	SELECT
		custid , -- grouping column
		shipperid, -- spreading column
		freight -- aggregation column
	FROM Sales.Orders
)
SELECT *
INTO Sales.FreightTotals
FROM PivotData
PIVOT( SUM(freight) FOR shipperid IN ([1],[2],[3]) ) AS P;

SELECT * FROM Sales.FreightTotals;


SELECT custid, shipperid, freight
FROM Sales.FreightTotals
UNPIVOT( freight FOR shipperid IN([1],[2],[3]) ) AS U;


--Alternate option
WITH C AS(
	SELECT custid, shipperid, CHOOSE(shipperid, [1], [2], [3]) AS freight
	FROM Sales.FreightTotals
		CROSS JOIN (VALUES (1), (2), (3)) AS v(shipperid)
)
SELECT custid, shipperid, freight
FROM C
WHERE freight IS NOT NULL


IF OBJECT_ID('Sales.FreightTotals') IS NOT NULL DROP TABLE Sales.FreightTotals;




/*========================================================================================================================
 Using Window Functions

========================================================================================================================*/

/*---------------------------------------------------------------------------------------- 
 Window Aggregate Functions
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


--Determenistic and non-deterministic sorting
SELECT 
    custid,
    orderid,
	orderdate,
    val,
    SUM(val) OVER(PARTITION BY custid	ORDER BY orderdate, orderid) AS d_runningtotal,
	SUM(val) OVER(PARTITION BY custid	ORDER BY orderdate) AS nd_runningtotal
FROM Sales.OrderValues
WHERE custid = 40;



--ROWS vs RANGE
SELECT 
    custid,
    orderid,
    orderdate,
    val,
	SUM(val) OVER(
		PARTITION BY custid		ORDER BY orderdate
        RANGE	BETWEEN	UNBOUNDED PRECEDING    AND CURRENT ROW
    ) AS rangetotal,
    SUM(val) OVER(
		PARTITION BY custid		ORDER BY orderdate
        ROWS	BETWEEN	UNBOUNDED PRECEDING    AND CURRENT ROW
    ) AS rowstotal
FROM Sales.OrderValues
WHERE custid = 40;



SELECT 
    custid,
    orderid,
	orderdate,
    val,
    AVG(val) OVER(
		PARTITION BY custid	ORDER BY orderdate, orderid
		ROWS	BETWEEN	1 PRECEDING    AND 1 FOLLOWING
	) AS avg3orders
FROM Sales.OrderValues;



/*---------------------------------------------------------------------------------------- 
 Window Ranking Functions
-----------------------------------------------------------------------------------------*/
--RANKING Function

SELECT custid, orderid, val,
    ROW_NUMBER()	OVER(ORDER BY val) AS rownum,
    RANK()			OVER(ORDER BY val) AS rnk,
    DENSE_RANK()	OVER(ORDER BY val) AS densernk,
    NTILE(100)		OVER(ORDER BY val) AS ntile100
FROM Sales.OrderValues;



SELECT 
    custid,
    orderid,
	orderdate,
    val,
    ROW_NUMBER() OVER(PARTITION BY custid	ORDER BY orderdate, orderid) AS runningtotal
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
 Window Analytic Functions
-----------------------------------------------------------------------------------------*/

SELECT 
    custid,
    orderid,
    orderdate,
    val,
    LEAD(val) OVER(PARTITION BY custid ORDER BY orderdate, orderid) AS next_val,
    LAG(val) OVER(PARTITION BY custid ORDER BY orderdate, orderid) AS prev_val
FROM Sales.OrderValues;


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
    val - LAG(val) OVER(PARTITION BY custid ORDER BY orderdate, orderid) AS diffprev,
    val - LEAD(val) OVER(PARTITION BY custid ORDER BY orderdate, orderid) AS diffnext
FROM Sales.OrderValues;



SELECT 
    custid,
    orderid,
    orderdate,
    val,
    FIRST_VALUE(val) OVER(PARTITION BY custid ORDER BY orderdate, orderid) AS first_val
FROM Sales.OrderValues
ORDER BY custid, orderdate, orderid;


SELECT 
    custid,
    orderid,
    orderdate,
    val,
    FIRST_VALUE(val) 
            OVER
                (
                    PARTITION BY custid ORDER BY orderdate, orderid
                    --RANGE BETWEEN UNBOUNDED PRECEDING
                    --AND CURRENT ROW
                ) AS first_val,
    LAST_VALUE(val) 
            OVER
                (
                    PARTITION BY custid ORDER BY orderdate, orderid
                    --RANGE BETWEEN CURRENT ROW
                    --AND UNBOUNDED FOLLOWING
                ) AS last_val
FROM Sales.OrderValues
ORDER BY custid, orderdate, orderid;

