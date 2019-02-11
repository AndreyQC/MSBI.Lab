/*=========================================
MSBI.Dev.S19E03.Script.01
=========================================*/

USE TSQL2012

--CASE Expression and Related Functions

--the simple form

SELECT productid,
        productname,
        unitprice,
        discontinued,
          CASE discontinued
               WHEN 0 THEN 'No'
               WHEN 1 THEN 'Yes'
                    ELSE 'Unknown'
          END
          AS discontinued_desc
FROM Production.Products;


--The searched form of the CASE expression

SELECT productid,
          productname,
          unitprice,
          CASE
               WHEN productname =   N'Product HHYDP'    THEN 'sfdfdfdf'
               WHEN unitprice   <   20.00               THEN 'Low'
               WHEN unitprice   <   40.00               THEN 'Medium'
               WHEN unitprice   >=  40.00               THEN 'High'
               ELSE 'Unknown'
          END AS pricerange
FROM Production.Products;


--COALESCE(<exp1>, <exp2>, , <expn>)
--is similar to the following.
--CASE
--WHEN <exp1> IS NOT NULL THEN <exp1>
--WHEN <exp2> IS NOT NULL THEN <exp2>
--
--WHEN <expn> IS NOT NULL THEN <expn>
--ELSE NULL
--END


DECLARE
@x AS VARCHAR(3) = NULL,
@y AS VARCHAR(10) = '1234567890';

DECLARE @z AS INT = 1;

SELECT COALESCE(@x,@y, @z);

SELECT ISNULL(@x, 0);

SELECT COALESCE(@x, @y) AS [COALESCE], ISNULL(@x, @y) AS [ISNULL];

select CHOOSE(2, 'x', 'y', 'z');

SELECT IIF(NULL<>NULL,'false','true');

SELECT COALESCE(2,NULL);



/*=======================================================
Filtering and Sorting Data

========================================================*/
--Predicates, Three-Valued Logic, and Search Arguments

SELECT empid, firstname, lastname, country, region, city
FROM HR.Employees
WHERE country = N'USA';

SELECT empid, firstname, lastname, country, region, city
FROM HR.Employees
WHERE region = N'WA';

SELECT empid, firstname, lastname, country, region, city
FROM HR.Employees
WHERE region <> N'WA';

SELECT empid, firstname, lastname, country, region, city
FROM HR.Employees
WHERE region <> N'WA'
OR region IS NULL;

SELECT empid, firstname, lastname, country, region, city
FROM HR.Employees
WHERE ISNULL(region,'') ='' OR region <> N'WA';



--sarg

--!!! include to task

SELECT GETDATE(), GETUTCDATE()

DECLARE @dt DATETIME = '2008-04-13 00:00:00.000'-- GETDATE();
SET @dt=NULL
SELECT orderid, orderdate, empid--,shippeddate
FROM Sales.Orders
WHERE COALESCE(shippeddate, '19000101') = COALESCE(@dt, '19000101');

SELECT orderid, orderdate, empid
FROM Sales.Orders
WHERE shippeddate = @dt
OR (shippeddate IS NULL AND @dt IS NULL);

--Filtering Character Data

SELECT empid, firstname, lastname
FROM HR.Employees
WHERE lastname = 'Davis';

SELECT empid, firstname, lastname
FROM HR.Employees
WHERE lastname = N'Davis';


-- LIKE

SELECT empid, firstname, lastname
FROM HR.Employees
WHERE lastname LIKE N'D%';


--Filtering Date and Time Data

SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE orderdate = '02/12/07';



SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE orderdate = '20070212';

-- best way to select inerval

SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE YEAR(orderdate) = 2007 AND MONTH(orderdate) = 2;

-- Andrey ! before show add test record with  20070203
SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE orderdate >= '20070201' AND orderdate <= '20070228 23:59:59.999';


-- 

SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
--ORDER BY orderdate DESC
WHERE orderdate BETWEEN '20070201' AND '20070228 23:59:59.999'


DECLARE @dt1 AS DATETIME = '20070228 23:59:59.999';
SELECT @dt1;

--Filtering Data with TOP

SELECT 
--TOP (1)
 orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC, orderid desc;

10248
11077
11077

11074
11075
11076
11077

SELECT TOP (1) PERCENT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC;

DECLARE @n AS BIGINT = 10;
SELECT TOP (@n) orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC;

-- it can work without ORDER clause
SELECT TOP (3) orderid, orderdate, custid, empid
FROM Sales.Orders;
-- to keep consistant
SELECT TOP (3) orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY NEWID();

-- show determenistic
SELECT TOP (3) orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC;
--what if there are other rows 
SELECT TOP (1) WITH TIES orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC;



--Filtering Data with OFFSET-FETCH

SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC, orderid DESC
OFFSET 50 ROWS FETCH NEXT 25 ROWS ONLY;


SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC, orderid DESC
OFFSET 0 ROWS FETCH FIRST 25 ROWS ONLY;

--requests to skip 50 rows, returning all the rest.
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC, orderid DESC
OFFSET 50 ROWS;

--filter a certain number of rows based on arbitrary order
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY (SELECT NULL)
OFFSET 0 ROWS FETCH FIRST 3 ROWS ONLY;

--paginator
DECLARE @pagesize AS BIGINT = 25, @pagenum AS BIGINT = 4;
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC, orderid DESC
OFFSET (@pagesize - 1) * @pagesize ROWS FETCH NEXT @pagesize ROWS ONLY;


/*===========================================================================
Combining Sets

=============================================================================*/

USE TSQL2012;
INSERT INTO Production.Suppliers
(companyname, contactname, contacttitle, address, city, postalcode, country, phone)
VALUES(N'Supplier XYZ', N'Jiru', N'Head of Security', N'42 Sekimai Musashino-shi',
N'Tokyo', N'01759', N'Japan', N'(02) 4311-2609');

SELECT * FROM Production.Suppliers

--This supplier does not have any related products in the Production.Products table and is used in examples demonstrating nonmatches.


-- cross join

SELECT D.n AS theday,
  S.n AS shiftno
FROM dbo.Nums AS D
 CROSS JOIN dbo.Nums AS S
 WHERE D.n <= 7
  AND S.N <= 3
ORDER BY theday, shiftno;

-- inner join

SELECT
    S.companyname AS supplier,
    S.country,
    P.productid,
    P.productname,
    P.unitprice
FROM Production.Suppliers AS S
    INNER JOIN Production.Products AS P
        ON P.supplierid = S.supplierid -- AND S.country = N'Japan'
WHERE S.country = N'Japan';

-- for inner we can move filter to ON
SELECT
    S.companyname AS supplier,
    S.country,
    P.productid,
    P.productname,
    P.unitprice
FROM Production.Suppliers AS S
    INNER JOIN Production.Products AS P
        ON S.supplierid = P.supplierid
        AND S.country = N'Japan';

--Outer Joins

SELECT
    S.companyname AS supplier,
    S.country,
    P.productid,
    P.productname,
    P.unitprice
FROM Production.Suppliers AS S
    LEFT OUTER JOIN Production.Products AS P
        ON S.supplierid = P.supplierid 
   --AND S.country = N'Japan'
WHERE S.country = N'Japan';


SELECT
 S.companyname AS supplier,
 S.country

FROM Production.Suppliers AS S
WHERE S.country = N'Japan';
--with outer joins, the ON and WHERE clauses play
--very different roles, and therefore, they arent interchangeable

SELECT
 S.companyname AS supplier,
 S.country,
 P.productid,
 P.productname,
 P.unitprice
FROM Production.Suppliers AS S
 LEFT OUTER JOIN Production.Products AS P
 ON S.supplierid = P.supplierid
  AND S.country = N'Japan';


SELECT E.empid,
 E.firstname + N' ' + E.lastname AS emp,
 M.firstname + N' ' + M.lastname AS mgr
FROM HR.Employees AS E
 LEFT OUTER JOIN HR.Employees AS M
  ON E.mgrid = M.empid;



--multi joins

SELECT
 S.companyname AS supplier,
 S.country,
 P.productid,
 P.productname,
 P.unitprice,
 C.categoryname
FROM Production.Suppliers AS S
 LEFT OUTER JOIN Production.Products AS P
  ON S.supplierid = P.supplierid
 INNER JOIN Production.Categories AS C
  ON C.categoryid = P.categoryid
WHERE S.country = N'Japan';

SELECT
 S.companyname AS supplier,
 S.country,
 P.productid,
 P.productname,
 P.unitprice,
 C.categoryname
FROM Production.Suppliers AS S
LEFT OUTER JOIN
 (
  Production.Products AS P
  INNER JOIN Production.Categories AS C
  ON C.categoryid = P.categoryid
 )
 ON S.supplierid = P.supplierid
WHERE S.country = N'Japan';




