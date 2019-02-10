/*=========================================
MSBI.Dev.S19E04.Script.01
=========================================*/

/*
- topicname: Using Subqueries, Table Expressions, and the APPLY Operator
  subtopics:
   - subtopicname: Self-Contained Subqueries
   - subtopicname: Correlated Subqueries
   - subtopicname: Table Expressions
   - subtopicname: Derived Tables
   - subtopicname: CTEs
   - subtopicname: recursive CTE
   - subtopicname: Views and Inline Table-Valued Functions
   - subtopicname: APPLY
   - subtopicname: CROSS APPLY
   - subtopicname: OUTER APPLY
- topicname: Using Set Operators
  subtopics:
   - subtopicname: UNION
   - subtopicname: UNION ALL
   - subtopicname: EXCEPT
   - subtopicname: INTERSECT
- topicname: Grouping and Windowing
  subtopics:
   - subtopicname: Working with a Single Grouping Set
   - subtopicname: Working with Multiple Grouping Sets
- topicname: Pivoting and Unpivoting Data
  subtopics:
   - subtopicname: Pivoting Data
   - subtopicname: Unpivoting Data
- topicname: Using Window Functions
  subtopics:
   - subtopicname: Window Aggregate Functions
     keywords: [FRAMES]
   - subtopicname: Window Ranking Functions
     keywords: [ROW_NUMBER, RANK, DENSE_RANK, NTILE]
   - subtopicname: Window Offset Functions
     keywords: [LAG, LEAD]
*/


/*======================================================================================================================================================
- topicname: Using Subqueries, Table Expressions, and the APPLY Operator
========================================================================================================================================================*/
  
/*---------------------------------------------------------------------------------------- 
- subtopicname: Self-Contained Subqueries 
-----------------------------------------------------------------------------------------*/

SELECT 
    productid,
    productname,
    unitprice
FROM Production.Products
WHERE unitprice =
    (
        SELECT MAX(unitprice)
        FROM Production.Products
    );

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

/*---------------------------------------------------------------------------------------- 
   - subtopicname: Correlated Subqueries
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

-- add to task

SELECT 
    custid,
    companyname
FROM Sales.Customers AS C
WHERE EXISTS
    (
        SELECT 1
        FROM Sales.Orders AS O
        WHERE O.custid = C.custid
        AND O.orderdate = '20070212'
    );

-- negative
SELECT 
    custid,
    companyname
FROM Sales.Customers AS C
WHERE NOT EXISTS
    (
        SELECT *
        FROM Sales.Orders AS O
        WHERE O.custid = C.custid
        AND O.orderdate = '20070212'
    );


/*---------------------------------------------------------------------------------------- 
   - subtopicname: Derived Tables
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
WHERE rownum <= 1;


/*---------------------------------------------------------------------------------------- 
   - subtopicname: CTEs
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



/*---------------------------------------------------------------------------------------- 
   - subtopicname: recursive CTE
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




/*---------------------------------------------------------------------------------------- 
   - subtopicname: Views and Inline Table-Valued Functions
-----------------------------------------------------------------------------------------*/


IF OBJECT_ID('Sales.RankedProducts', 'V') IS NOT NULL DROP VIEW Sales.RankedProducts;
GO
CREATE VIEW Sales.RankedProducts
AS
SELECT
    ROW_NUMBER() OVER(PARTITION BY categoryid ORDER BY unitprice, productid) AS rownum,
    categoryid,
    productid,
    productname,
    unitprice
FROM Production.Products;
GO

SELECT categoryid, productid, productname, unitprice
FROM Sales.RankedProducts
WHERE rownum <= 2;

--*************************************************************************
--function
--*************************************************************************
IF OBJECT_ID('HR.GetManagers', 'IF') IS NOT NULL DROP FUNCTION HR.GetManagers;
GO
CREATE FUNCTION HR.GetManagers(@empid AS INT) RETURNS TABLE
AS
RETURN
WITH EmpsCTE AS
(
    SELECT empid, mgrid, firstname, lastname, 0 AS distance
    FROM HR.Employees
    WHERE empid = @empid

    UNION ALL

    SELECT M.empid, M.mgrid, M.firstname, M.lastname, S.distance + 1 AS distance
    FROM EmpsCTE AS S
    JOIN HR.Employees AS M
    ON S.mgrid = M.empid
)
SELECT empid, mgrid, firstname, lastname, distance
FROM EmpsCTE;
GO
--

SELECT *
FROM HR.GetManagers(9) AS M;



/*---------------------------------------------------------------------------------------- 
   - subtopicname: CROSS APPLY
   - subtopicname: OUTER APPLY
-----------------------------------------------------------------------------------------*/

--*************************************************************************
-- CROSS APPLY
--*************************************************************************
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
            OFFSET 0 ROWS FETCH FIRST 3 ROWS ONLY
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



/*=========================================
sorting with null
=========================================*/
use AdventureWorks2014
select [MiddleName] from  [Person].[Person] order by  [MiddleName]



/*========================================================================================================================
- topicname: Using Set Operators
  subtopics:
   - subtopicname: UNION
   - subtopicname: UNION ALL
   - subtopicname: EXCEPT
   - subtopicname: INTERSECT
========================================================================================================================*/

    /*---------------------------------------------------------------------------------------- 
    - subtopicname: UNION
    -----------------------------------------------------------------------------------------*/

USE TSQL2012;
SELECT country, region, city
FROM HR.Employees
UNION
SELECT country, region, city
FROM Sales.Customers
ORDER BY country;


/*---------------------------------------------------------------------------------------- 
    - subtopicname: UNION ALL
-----------------------------------------------------------------------------------------*/
SELECT country As COUNTRY1, region, city
FROM HR.Employees
UNION ALL
SELECT country, region, city
FROM Sales.Customers
ORDER BY country;

/*---------------------------------------------------------------------------------------- 
   - subtopicname: INTERSECT
-----------------------------------------------------------------------------------------*/


SELECT country, region, city
FROM HR.Employees
INTERSECT
SELECT country, region, city
FROM Sales.Customers;

/*---------------------------------------------------------------------------------------- 
   - subtopicname: EXCEPT
-----------------------------------------------------------------------------------------*/

--EXCEPT
SELECT country, region, city
FROM HR.Employees
--WHERE city= 'Redmond'
EXCEPT
SELECT country, region, city
FROM Sales.Customers
--WHERE city= 'Redmond';


--EXCEPT --compare with previous

SELECT country, region, city
FROM Sales.Customers
EXCEPT
SELECT country, region, city
FROM HR.Employees;


-- INTERSECT precedes UNION and EXCEPT, and
--UNION and EXCEPT are considered equal


-- any some all

IF OBJECT_ID('dbo.T1', N'U') IS NOT NULL DROP table dbo.t1;
CREATE TABLE T1
(ID int) ;
GO
INSERT T1 VALUES (1) ;
INSERT T1 VALUES (2) ;
INSERT T1 VALUES (3) ;
INSERT T1 VALUES (4) ;

IF 3 < SOME (SELECT ID FROM T1)
PRINT 'TRUE' 
ELSE
PRINT 'FALSE' ;

IF 3 < ALL (SELECT ID FROM T1)
PRINT 'TRUE' 
ELSE
PRINT 'FALSE' ;


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

SELECT STDEV(freight) FROM Sales.Orders

SELECT COUNT(*) AS numorders
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
HAVING COUNT(*) < 100;


SELECT 
    shipperid,
    COUNT(*) AS numorders,
    COUNT(shippeddate) AS shippedorders,  -- <- Attention ignore NULL
    COUNT(DISTINCT shippeddate) AS numshippedorders,
    MIN(shippeddate) AS firstshipdate,
    MAX(shippeddate) AS lastshipdate,
    SUM(val) AS totalvalue
FROM Sales.OrderValues
GROUP BY shipperid;

--Note that the DISTINCT option is available not only to the COUNT function, but also to
--other general set functions. However, its more common to use it with COUNT.




-- !!!try to explain why this query is not valid?
SELECT 
    S.shipperid,
    S.companyname,
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

--SELECT DISTINCT
--S.shipperid, S.companyname
--FROM Sales.Shippers AS S
--Op2

SELECT 
    S.shipperid,
    MAX(S.companyname) AS numorders,
    COUNT(*) AS shippedorders
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
    --( shipperid ),
    ( YEAR(shippeddate) ),
    ( )
);

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
--( shipcountry, shipregion, shipcity )
 --( shipcountry, shipregion )
 --( shipcountry )
 --( )

 -- use hierarchy
 SELECT shipcountry, shipregion, shipcity, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY ROLLUP( shipcountry, shipregion, shipcity )


-- to make more convinient to use
SELECT
    shipcountry, GROUPING(shipcountry) AS grpcountry,
    shipregion , GROUPING(shipregion) AS grpcountry,
    shipcity , GROUPING(shipcity) AS grpcountry,
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

SELECT custid, [1], [2], [3]
FROM Sales.Orders
PIVOT(SUM(freight) FOR shipperid IN ([1],[2],[3]) ) AS P;

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

IF OBJECT_ID('Sales.FreightTotals') IS NOT NULL DROP TABLE Sales.FreightTotals;

/*========================================================================================================================
-- topicname: Using Window Functions
  subtopics:
   - subtopicname: Window Aggregate Functions
     keywords: [FRAMES]
   - subtopicname: Window Ranking Functions
     keywords: [ROW_NUMBER, RANK, DENSE_RANK, NTILE]
   - subtopicname: Window Offset Functions
     keywords: [LAG, LEAD]
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
    CAST(100.0 * val / SUM(val) OVER(PARTITION BY custid) AS NUMERIC(5, 2)) AS pctcust,
    CAST(100.0 * val / SUM(val) OVER() AS NUMERIC(5, 2)) AS pcttotal
FROM Sales.OrderValues;

-- frame
SELECT 
    custid,
    orderid,
    orderdate,
    val,
    SUM(val) OVER
    (
    PARTITION BY custid ORDER BY orderdate,	 orderid
        ROWS BETWEEN UNBOUNDED PRECEDING
    AND CURRENT ROW
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
WHERE runningtotal < 1000.00;

--ROWS BETWEEN 2 PRECEDING AND CURRENT ROW.


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


/*---------------------------------------------------------------------------------------- 
   - subtopicname: Window Offset Functions
-----------------------------------------------------------------------------------------*/

SELECT 
    custid,
    orderid,
    orderdate,
    val,
    LAG(val,2,0) OVER(PARTITION BY custid ORDER BY orderdate, orderid) AS prev_val,
    LEAD(val,2,0) OVER(PARTITION BY custid ORDER BY orderdate, orderid) AS next_val
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
FROM Sales.OrderValues;



--Query to produce test data


DECLARE @low AS BIGINT
DECLARE @high AS BIGINT
SET @low=1;
SET @high=1000000;

WITH
L0 AS (SELECT c FROM (VALUES(1),(1)) AS D(c)),
L1 AS (SELECT 1 AS c FROM L0 AS A CROSS JOIN L0 AS B),
L2 AS (SELECT 1 AS c FROM L1 AS A CROSS JOIN L1 AS B),
L3 AS (SELECT 1 AS c FROM L2 AS A CROSS JOIN L2 AS B),
L4 AS (SELECT 1 AS c FROM L3 AS A CROSS JOIN L3 AS B),
L5 AS (SELECT 1 AS c FROM L4 AS A CROSS JOIN L4 AS B),
Nums AS (SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS rownum
FROM L5)
SELECT @low + rownum - 1 AS n
FROM Nums
ORDER BY rownum
OFFSET 0 ROWS FETCH FIRST @high - @low + 1 ROWS ONLY;

