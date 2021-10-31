WITH SD
AS 
(
SELECT        
	FRS.ProductKey
	, SUM(FRS.SalesAmount) AS SalesAmount
	, D.CalendarYear
FROM FactResellerSales AS FRS
INNER JOIN 
	DimDate AS D
		ON FRS.OrderDateKey = D.DateKey
GROUP BY FRS.ProductKey,D.CalendarYear
),
SI
AS
(
SELECT 
	SD.ProductKey,
	SD.SalesAmount,
	CASE WHEN SD.CalendarYear ='2009'
		THEN SD.SalesAmount 
	END AS Sales2005,
	CASE WHEN SD.CalendarYear ='2010'
		THEN SD.SalesAmount 
	END AS Sales2006,
	CASE WHEN SD.CalendarYear ='2011'
		THEN SD.SalesAmount 
	END AS Sales2007,
	CASE WHEN SD.CalendarYear ='2012'
		THEN SD.SalesAmount 
	END AS Sales2008,
	CASE WHEN SD.CalendarYear ='2013'
		THEN SD.SalesAmount 
	END AS Sales2009,
		CASE WHEN SD.CalendarYear ='2014'
	THEN SD.SalesAmount 
		END AS Sales2010
FROM SD
),
Sales
AS
(
SELECT 
	SI.ProductKey,
	SUM(SI.Sales2005) AS '2009',
	SUM(SI.Sales2006) AS '2010',
	SUM(SI.Sales2007) AS '2011',
	SUM(SI.Sales2008) AS '2012',
	SUM(SI.Sales2009) AS '2013',
	SUM(SI.Sales2010) AS '2014',
	SUM(SI.SalesAmount) AS Total
FROM SI
GROUP BY SI.ProductKey
)
SELECT 
	P.EnglishProductName,
	S.[2009],
	S.[2010],
	S.[2011],
	S.[2012],
	S.[2013],
	S.[2014],
	S.Total
FROM Sales AS S
	INNER JOIN
		dbo.DimProduct AS P
ON S.ProductKey = P.ProductKey
ORDER BY P.EnglishProductName
