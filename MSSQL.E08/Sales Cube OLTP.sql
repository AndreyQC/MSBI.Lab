WITH SD
AS 
(
SELECT 
	S.ProductID
	,SUM( S.UnitPrice * S.OrderQty) AS SalesAmount
	, DATEPART(yy,SH.OrderDate) AS SalesYear
FROM Sales.SalesOrderDetail AS S
	INNER JOIN 
		Sales.SalesOrderHeader AS SH
			ON S.SalesOrderID = SH.SalesOrderID 
GROUP BY S.ProductID,DATEPART(yy,SH.OrderDate)
),
SI
AS
(
SELECT 
	SD.ProductID,
	SD.SalesAmount,
	CASE WHEN SD.SalesYear = 2011
		THEN SD.SalesAmount 
	END AS Sales2011,
	CASE WHEN SD.SalesYear = 2012
		THEN SD.SalesAmount 
	END AS Sales2012,
	CASE WHEN SD.SalesYear = 2013
		THEN SD.SalesAmount 
	END AS Sales2013,
	CASE WHEN SD.SalesYear = 2014
		THEN SD.SalesAmount 
	END AS Sales2014,
	CASE WHEN SD.SalesYear = 2015
		THEN SD.SalesAmount 
	END AS Sales2015,
	CASE WHEN SD.SalesYear = 2016
		THEN SD.SalesAmount 
	END AS Sales2016
FROM SD
),
Sales
AS
(
SELECT 
	SI.ProductID,
	SUM(SI.Sales2011) AS '2011',
	SUM(SI.Sales2012) AS '2012',
	SUM(SI.Sales2013) AS '2013',
	SUM(SI.Sales2014) AS '2014',
	SUM(SI.Sales2015) AS '2015',
	SUM(SI.Sales2016) AS '2016',
	SUM(SI.SalesAmount) AS Total
FROM SI
GROUP BY SI.ProductID
)
SELECT 
	P.Name,
	S.[2011],
	S.[2012],
	S.[2013],
	S.[2014],
	S.[2015],
	S.[2016],
	S.Total
FROM Sales AS S
	INNER JOIN
		Production.Product AS P
ON S.ProductID = P.ProductID
ORDER BY P.Name

