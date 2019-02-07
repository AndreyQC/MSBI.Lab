/*=========================================
MSBI.Dev.S19E04.Task04.sql
=========================================*/
/*===================================================================================
TASK05.01 
TOPIC			: GROUPING
DESCRIPTION		: use [AdventureWorks2014].Sales.SalesOrderHeader table
				  use [AdventureWorks2014].Sales.SalesTerritory table

get following columns 

[TerritoryName]					- get from table
[OrderYear]						- get from OrderDate
[OrderCount]					- calculate number of orders for each year and territory
[TotalDue]						- calculate total due for each year and territory

FILTERED BY OrderCount<100
ORDERED BY ShippedYear
=====================================================================================*/


--<<<<<<<<<<<<<<<<<    PUT YOUR CODE HERE   >>>>>>>>>>>>>>>>>








/*===================================================================================
TASK05.02 
TOPIC			: RANK
DESCRIPTION		: use [AdventureWorks2014].Sales.SalesOrderHeader table

get following columns 

[OrderYear]						- get from OrderDate
[TotalDue]						- calculate total due for each year and territory
[RankValue]						- you need to mark top half of sale years by TotalDue with the rank of 1 and the remaining years 
								  must be given rank of 2.
=====================================================================================*/

--<<<<<<<<<<<<<<<<<    PUT YOUR CODE HERE   >>>>>>>>>>>>>>>>>











/*===================================================================================
TASK05.03 
TOPIC			: WINDOW FUNCTION
DESCRIPTION		: use [AdventureWorks2014].Sales.SalesOrderHeader table
				  use [AdventureWorks2014].Sales.SalesTerritory table
get following columns 

[TerritoryName]					- get from table
[OrderYear]						- get from OrderDate
[TotalDue]						- calculate total due for each year and territory
[PrevTotalDue]					- calculate total due for the previous year and the same territory
=====================================================================================*/

--<<<<<<<<<<<<<<<<<    PUT YOUR CODE HERE   >>>>>>>>>>>>>>>>>










/*===================================================================================
TASK05.04 
TOPIC			: GROUPING
DESCRIPTION		: use [AdventureWorks2014].Sales.SalesOrderHeader table
				  use [AdventureWorks2014].Sales.SalesTerritory table
				  use [AdventureWorks2014].Sales.SalesPerson table
				  use [AdventureWorks2014].Person.Person table

GET FOLLOWING COLUMNS 

[Group]							- get from table Sales.SalesTerritory
[TerritoryName]					- get from Sales.SalesTerritory
[OrderYear]						- get from OrderDate
[SalesPerson]					- get [FirstName + ' ' + LastName] of Sales Person
[TotalDue]						- calculate totals TotalDue made by territory group, TerritoryName, OrderYear, and Sales Person
								- sub totals only at the territory group and TerritoryName level
								- a grand total of the TotalDue
=====================================================================================*/

--<<<<<<<<<<<<<<<<<    PUT YOUR CODE HERE   >>>>>>>>>>>>>>>>>


