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
	CASE WHEN SD.SalesYear ='2005'
		THEN SD.SalesAmount 
	END AS Sales2005,
	CASE WHEN SD.SalesYear ='2006'
		THEN SD.SalesAmount 
	END AS Sales2006,
	CASE WHEN SD.SalesYear ='2007'
		THEN SD.SalesAmount 
	END AS Sales2007,
	CASE WHEN SD.SalesYear ='2008'
		THEN SD.SalesAmount 
	END AS Sales2008,
	CASE WHEN SD.SalesYear ='2009'
		THEN SD.SalesAmount 
	END AS Sales2009,
		CASE WHEN SD.SalesYear ='2010'
	THEN SD.SalesAmount 
		END AS Sales2010
FROM SD
),
Sales
AS
(
SELECT 
	SI.ProductID,
	SUM(SI.Sales2005) AS '2005',
	SUM(SI.Sales2006) AS '2006',
	SUM(SI.Sales2007) AS '2007',
	SUM(SI.Sales2008) AS '2008',
	SUM(SI.Sales2009) AS '2009',
	SUM(SI.Sales2010) AS '2010',
	SUM(SI.SalesAmount) AS Total
FROM SI
GROUP BY SI.ProductID
)
SELECT 
	P.Name,
	S.[2005],
	S.[2006],
	S.[2007],
	S.[2008],
	S.[2009],
	S.[2010],
	S.Total
FROM Sales AS S
	INNER JOIN
		Production.Product AS P
ON S.ProductID = P.ProductID
ORDER BY P.Name

