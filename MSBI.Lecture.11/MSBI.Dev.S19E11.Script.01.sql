/*=========================================
MSBI.DEVELOPER.COURSE.S18E11.SCRIPT
=========================================*/


/*=====================================================================================================================
heap
========================================================================================================================*/
--IF OBJECT_ID('dbo.TestStructure', 'U') IS NOT NULL
--DROP table dbo.TestStructure
--GO

--CREATE TABLE dbo.TestStructure
--(
--    id INT NOT NULL,
--    filler1 CHAR(36) NOT NULL,
--    filler2 CHAR(216) NOT NULL
--);



---- review type
--SELECT 
--    OBJECT_NAME(object_id) AS table_name,
--    name AS index_name, 
--    type, type_desc
--FROM sys.indexes
--WHERE object_id = OBJECT_ID(N'dbo.TestStructure', N'U');
--go


---- review pages
--SELECT 
--    index_type_desc, 
--    page_count,
--    record_count, 
--    avg_page_space_used_in_percent
--FROM sys.dm_db_index_physical_stats
--(DB_ID(N'TSQL2012'), OBJECT_ID(N'dbo.TestStructure'), NULL, NULL , 'DETAILED');
--EXEC dbo.sp_spaceused @objname = N'dbo.TestStructure', @updateusage = true;


---- insert some data
--INSERT INTO dbo.TestStructure
--(id, filler1, filler2)
--VALUES
--(1, 'a', 'b');


--dbcc ind
--(
--'TSQL2012' /*Database Name*/
--,'dbo.TestStructure' /*Table Name*/
--,-1 /*Display information for all pages of all indexes*/
--);


---- Redirecting DBCC PAGE output to console
--dbcc traceon(3604)
--dbcc page
--(
--'TSQL2012' /*Database Name*/
--,1 /*File ID*/
--,622 /*Page ID*/
--,3 /*Output mode: 3 - display page header and row details */
--);
---- review pages agian


--SELECT 
--    index_type_desc, 
--    page_count,
--    record_count, 
--    avg_page_space_used_in_percent
--FROM sys.dm_db_index_physical_stats
--(DB_ID(N'TSQL2012'), OBJECT_ID(N'dbo.TestStructure'), NULL, NULL , 'DETAILED');
--EXEC dbo.sp_spaceused @objname = N'dbo.TestStructure', @updateusage = true;

---- insert much more
--DECLARE @i AS int = 1;
--WHILE @i < 30
--BEGIN
--SET @i = @i + 1;
--INSERT INTO dbo.TestStructure
--(id, filler1, filler2)
--VALUES
--(@i, 'a', 'b');
--END;


---- review pages agian
--SELECT index_type_desc, page_count,
--record_count, avg_page_space_used_in_percent
--FROM sys.dm_db_index_physical_stats
--(DB_ID(N'TSQL2012'), OBJECT_ID(N'dbo.TestStructure'), NULL, NULL , 'DETAILED');
--EXEC dbo.sp_spaceused @objname = N'dbo.TestStructure', @updateusage = true;

---- still one page


---- insert again
--INSERT INTO dbo.TestStructure
--(id, filler1, filler2)
--VALUES
--(31, 'a', 'b');


---- review pages agian
--SELECT index_type_desc, page_count,
--record_count, avg_page_space_used_in_percent
--FROM sys.dm_db_index_physical_stats
--(DB_ID(N'TSQL2012'), OBJECT_ID(N'dbo.TestStructure'), NULL, NULL , 'DETAILED');
--EXEC dbo.sp_spaceused @objname = N'dbo.TestStructure', @updateusage = true;



---- add 8 pages
--DECLARE @i AS int = 31;
--WHILE @i < 240
--BEGIN
--SET @i = @i + 1;
--INSERT INTO dbo.TestStructure
--(id, filler1, filler2)
--VALUES
--(@i, 'a', 'b');
--END;

---- review pages agian
--SELECT index_type_desc, page_count,
--record_count, avg_page_space_used_in_percent
--FROM sys.dm_db_index_physical_stats
--(DB_ID(N'TSQL2012'), OBJECT_ID(N'dbo.TestStructure'), NULL, NULL , 'DETAILED');
--EXEC dbo.sp_spaceused @objname = N'dbo.TestStructure', @updateusage = true;

--=============================================================================
-- clustered
--=============================================================================

--TRUNCATE TABLE dbo.TestStructure;
--CREATE CLUSTERED INDEX idx_cl_id ON dbo.TestStructure(id);

--SELECT index_type_desc, page_count,
--record_count, avg_page_space_used_in_percent
--FROM sys.dm_db_index_physical_stats
--(DB_ID(N'TSQL2012'), OBJECT_ID(N'dbo.TestStructure'), NULL, NULL , 'DETAILED');
--EXEC dbo.sp_spaceused @objname = N'dbo.TestStructure', @updateusage = true;

--go
---- add 621 pages
--DECLARE @i AS int = 0;
--WHILE @i < 18630
--BEGIN
--SET @i = @i + 1;
--INSERT INTO dbo.TestStructure
--(id, filler1, filler2)
--VALUES
--(@i, 'a', 'b');
--END;

---- observe page
--SELECT index_type_desc, index_depth, index_level, page_count,
--record_count, avg_page_space_used_in_percent
--FROM sys.dm_db_index_physical_stats
--(DB_ID(N'TSQL2012'), OBJECT_ID(N'dbo.TestStructure'), NULL, NULL , 'DETAILED');
--EXEC dbo.sp_spaceused @objname = N'dbo.TestStructure', @updateusage = true;


--INSERT INTO dbo.TestStructure
--(id, filler1, filler2)
--VALUES
--(1, 'a', 'b');



/*====================================================================================
Supporting Queries with Indexes
=====================================================================================*/

--SARG!!!!
SELECT 
    orderid, 
    custid, 
    orderdate, 
    shipname
FROM Sales.Orders
WHERE DATEDIFF(day, '20060709', orderdate) <= 2
	AND DATEDIFF(day, '20060709', orderdate) > 0;


SELECT 
    orderid, 
    custid, 
    orderdate, 
    shipname
FROM Sales.Orders
WHERE orderdate<=DATEADD(day, 2, '20060709') 
	AND   orderdate >'20060709'

-- compare plan
SELECT 
    orderid, 
    custid, 
    orderdate, 
    shipname
FROM Sales.Orders
WHERE orderdate IN ('20060710', '20060711');

SELECT 
    orderid, 
    custid, 
    orderdate, 
    shipname
FROM Sales.Orders
WHERE orderdate = '20060710'
	OR orderdate = '20060711';





DROP TABLE IF EXISTS [dbo].[OrdersIdx];
DROP TABLE IF EXISTS [dbo].[OrdersNonIdx];

CREATE TABLE [dbo].[OrdersNonIdx]
(
	[orderid]		INT NOT NULL	PRIMARY KEY CLUSTERED,
	[custid]		INT NULL,
	[shipregion]	NVARCHAR(15) NULL
);
CREATE TABLE [dbo].[OrdersIdx]
(
	[orderid]		INT NOT NULL	PRIMARY KEY CLUSTERED,
	[custid]		INT NULL,
	[shipregion]	NVARCHAR(15) NULL
);
CREATE NONCLUSTERED INDEX [IX_OrdersIdx_shipregion]
	ON [dbo].[OrdersIdx] ([shipregion]);
GO

INSERT INTO [dbo].[OrdersNonIdx]
SELECT [orderid], [custid], [shipregion]
FROM [Sales].[Orders]
;
INSERT INTO [dbo].[OrdersIdx]
SELECT [orderid], [custid], [shipregion]
FROM [Sales].[Orders]
;

--just select
SELECT orderid, custid, shipregion
FROM [dbo].[OrdersNonIdx];

SELECT orderid, custid, shipregion
FROM [dbo].[OrdersIdx];

-- where
SELECT orderid, shipregion
FROM [dbo].[OrdersNonIdx]
WHERE shipregion = N'Isle of Wight';

SELECT orderid, shipregion
FROM [dbo].[OrdersIdx]
WHERE shipregion = N'Isle of Wight';

-- group by
SELECT shipregion, COUNT(*) AS num_regions
FROM [dbo].[OrdersNonIdx]
GROUP BY shipregion;

SELECT shipregion, COUNT(*) AS num_regions
FROM [dbo].[OrdersIdx]
GROUP BY shipregion;

-- sorting
SELECT orderid, shipregion
FROM [dbo].[OrdersNonIdx]
ORDER BY shipregion;

SELECT orderid, shipregion
FROM [dbo].[OrdersIdx]
ORDER BY shipregion;


--index with update

--decreased performance
UPDATE [dbo].[OrdersIdx]
SET shipregion = N'Region 2'
WHERE custid = 2;

--increased performance
UPDATE [dbo].[OrdersIdx]
SET custid = 2
WHERE shipregion = N'Region 2';
	


--covering index
SELECT orderid, custid, shipregion
FROM [dbo].[OrdersIdx]
WHERE shipregion = N'Isle of Wight';

CREATE NONCLUSTERED INDEX [IX_OrdersIdx_shipregion]
	ON [dbo].[OrdersIdx] ([shipregion])
	INCLUDE ([custid])
	WITH (DROP_EXISTING = ON);	-- kind of alter index
GO


DROP TABLE IF EXISTS [dbo].[OrdersIdx];
DROP TABLE IF EXISTS [dbo].[OrdersNonIdx];


/*====================================================================================
indexed view
=====================================================================================*/
USE TSQL2012;

DROP VIEW IF EXISTS Sales.QuantityByCountry;
GO

SET STATISTICS IO ON;
-- Aggregate query with a join
SELECT 
    O.shipcountry, 
    SUM(OD.qty) AS totalordered
FROM Sales.OrderDetails AS OD
    INNER JOIN Sales.Orders AS O
        ON OD.orderid = O.orderid
GROUP BY O.shipcountry;

GO
-- Create a view from the query
CREATE OR ALTER VIEW Sales.QuantityByCountry
WITH SCHEMABINDING
AS
SELECT 
    O.shipcountry, 
    SUM(OD.qty) AS total_ordered,
    COUNT_BIG(*) AS number_of_rows
FROM Sales.OrderDetails AS OD
    INNER JOIN Sales.Orders AS O
        ON OD.orderid = O.orderid
GROUP BY O.shipcountry;
GO
-- Index the view
CREATE UNIQUE CLUSTERED INDEX idx_cl_shipcountry
ON Sales.QuantityByCountry(shipcountry);
GO

SELECT
	shipcountry, 
    total_ordered,
    number_of_rows
FROM Sales.QuantityByCountry WITH (NOEXPAND)


SET STATISTICS IO OFF;

DROP VIEW IF EXISTS Sales.QuantityByCountry;
GO


--=======================================================================
-- Statistic
--=======================================================================

DBCC SHOW_STATISTICS(N'Sales.Orders', N'idx_nc_empid');

DBCC SHOW_STATISTICS(N'Sales.Orders', N'idx_nc_empid') WITH STAT_HEADER;

DBCC SHOW_STATISTICS(N'Sales.Orders', N'idx_nc_empid') WITH HISTOGRAM;


SELECT
	sts.[stats_id],
	sts.[name]									AS [stat_name],
	col.[name]									AS [column_name],
	sts.[auto_created],
	ext.[rows],
	ext.[rows_sampled],
	ext.[modification_counter],
	ext.[last_updated]
FROM
	[sys].[stats]																	AS sts
	INNER JOIN [sys].[stats_columns]												AS scol		ON sts.[object_id] = scol.[object_id]
																								AND sts.[stats_id] = scol.[stats_id]
	INNER JOIN [sys].[columns]														AS col		ON scol.[object_id] = col.[object_id]
																								AND scol.[column_id] = col.[column_id]
	OUTER APPLY [sys].[dm_db_stats_properties] (sts.[object_id], sts.[stats_id])	AS ext
WHERE
	sts.[object_id] = OBJECT_ID(N'Sales.Orders', N'U')
;

--=======================================================================
-- drop statistic
--=======================================================================
DECLARE @statistics_name AS NVARCHAR(128), @ds AS NVARCHAR(1000);
DECLARE acs_cursor CURSOR FOR
SELECT name AS statistics_name
FROM sys.stats
WHERE object_id = OBJECT_ID(N'Sales.Orders', N'U')
AND auto_created = 1;
OPEN acs_cursor;

FETCH NEXT FROM acs_cursor INTO @statistics_name;

WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @ds = N'DROP STATISTICS Sales.Orders.' + @statistics_name +';';
        EXEC(@ds);
        FETCH NEXT FROM acs_cursor INTO @statistics_name;
    END;

CLOSE acs_cursor;
DEALLOCATE acs_cursor;


SELECT 
    OBJECT_NAME(object_id) AS table_name,
    name AS statistics_name, auto_created
FROM sys.stats
WHERE object_id = OBJECT_ID(N'Sales.Orders', N'U');


ALTER INDEX idx_nc_empid ON Sales.Orders REBUILD;
SELECT * FROM Sales.Orders

SELECT DISTINCT empid FROM Sales.Orders
DBCC SHOW_STATISTICS(N'Sales.Orders',N'idx_nc_empid') WITH HISTOGRAM;


DBCC SHOW_STATISTICS(N'Sales.Orders',N'idx_nc_empid') WITH STAT_HEADER;


CREATE NONCLUSTERED INDEX idx_nc_custid_shipcity ON Sales.Orders(custid, shipcity);

DBCC SHOW_STATISTICS(N'Sales.Orders',N'idx_nc_custid_shipcity') WITH HISTOGRAM;

SELECT 
    orderid, 
    shipaddress, 
    custid, 
    shipcity
FROM Sales.Orders
WHERE custid = 42;

SELECT 
    OBJECT_NAME(object_id) AS table_name,
    name AS statistics_name
FROM sys.stats
WHERE object_id = OBJECT_ID(N'Sales.Orders', N'U')
AND auto_created = 1;


SELECT 
    orderid, 
    custid, 
    shipcity
FROM Sales.Orders
WHERE shipcity = N'Vancouver';


SELECT 
    OBJECT_NAME(s.object_id) AS table_name,
    S.name AS statistics_name,
    C.name AS column_name
FROM sys.stats AS S
    INNER JOIN sys.stats_columns AS SC
        ON S.stats_id = SC.stats_id
    INNER JOIN sys.columns AS C
        ON S.object_id= C.object_id AND SC.column_id = C.column_id
WHERE S.object_id = OBJECT_ID(N'Sales.Orders', N'U')
    AND auto_created = 1;



/*=========================================================================================================================================
parameter sniffing demo
==========================================================================================================================================*/

-- observe  cache
select
    p.usecounts, p.cacheobjtype, p.objtype, p.size_in_bytes,t.[text], qp.query_plan
from
    sys.dm_exec_cached_plans p
        cross apply sys.dm_exec_sql_text(p.plan_handle) t
		cross apply sys.dm_exec_query_plan(p.plan_handle) qp
order by
    p.objtype desc


DROP TABLE IF EXISTS dbo.Employees;

create table dbo.Employees
(
    ID int not null,
    Number varchar(32) not null,
    Name varchar(100) not null,
    Salary money not null,
    Country varchar(64) not null,
    constraint PK_Employees
    primary key clustered(ID)
);
;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,N4(C) as (select 0 from N3 as T1 cross join N3 as T2) -- 256 rows
,N5(C) as (select 0 from N4 as T1 cross join N4 as T2 ) -- 65,536 rows
,Nums(Num) as (select row_number() over (order by (select null)) from N5)
insert 
    into dbo.Employees(ID, Number, Name, Salary, Country)
select
    Num,
    convert(varchar(5),Num),
    'USA Employee: ' + convert(varchar(5),Num),
    40000,
    'USA'
from Nums;

;with N1(C) as (select 0 union all select 0) -- 2 rows
,N2(C) as (select 0 from N1 as T1 cross join N1 as T2) -- 4 rows
,N3(C) as (select 0 from N2 as T1 cross join N2 as T2) -- 16 rows
,Nums(Num) as (select row_number() over (order by (select null)) from N3)
insert into dbo.Employees(ID, Number, Name, Salary, Country)
select
    65536 + Num,
    convert(varchar(5),65536 + Num),
    'Canada Employee: ' + convert(varchar(5),Num),
    40000,
    'Canada'
from Nums;

create nonclustered index IDX_Employees_Country
on dbo.Employees(Country);
go

select Avg(Salary) as [Avg Salary]
from dbo.Employees
where Country = 'USA';
	
select Avg(Salary) as [Avg Salary]
from dbo.Employees
where Country = 'Canada';

GO

CREATE OR ALTER proc dbo.GetAverageSalary 
	@Country varchar(64)
as
begin
    DECLARE @Country1 varchar(64);
    --SET @Country1=@Country;

    select Avg(Salary) as [Avg Salary]
    from dbo.Employees
    where Country = @Country
    --option (recompile)
    --option (optimize for(@Country='USA'))
    --option (optimize for(@Country UNKNOWN))
end
go

exec dbo.GetAverageSalary N'USA'
exec dbo.GetAverageSalary @Country='Canada';

dbcc freeproccache
go


exec dbo.GetAverageSalary @Country='Canada';
exec dbo.GetAverageSalary @Country='USA';


update dbo.Employees set Country='Germany' where Country='USA';
exec dbo.GetAverageSalary @Country='Germany';


-- observe  cache
select
    p.usecounts, p.cacheobjtype, p.objtype, p.size_in_bytes,t.[text], qp.query_plan
from
    sys.dm_exec_cached_plans p
        cross apply sys.dm_exec_sql_text(p.plan_handle) t
		cross apply sys.dm_exec_query_plan(p.plan_handle) qp
--where
        --p.cacheobjtype like 'Compiled Plan%' and
        --t.[text] like '%Employees%'
order by
    p.objtype desc
option (recompile)

SELECT * FROM dbo.Employees WHERE Country='Canada'


DROP TABLE IF EXISTS dbo.Employees;

/*=========================================================================================================================================
end of parameter sniffing demo
==========================================================================================================================================*/



/*=========================================================================================================================================
-- create exte events
==========================================================================================================================================*/


/*==============================================================================================================================================


SET STATISTICS IO ON

*/

CHECKPOINT;
DBCC DROPCLEANBUFFERS;

SET STATISTICS IO ON;
SELECT * FROM Sales.Customers;
SELECT * FROM Sales.Orders;


SELECT 
    C.custid, 
    C.companyname,
    O.orderid, 
    O.orderdate
FROM Sales.Customers AS C
    INNER JOIN Sales.Orders AS O
ON C.custid = O.custid

SELECT 
    C.custid, 
    C.companyname,
    O.orderid, 
    O.orderdate
FROM Sales.Customers AS C
    INNER JOIN Sales.Orders AS O
        ON C.custid = O.custid
WHERE O.custid < 5

SET STATISTICS IO OFF;


/*==============================================================================================================================================


SET STATISTICS TIME ON;

*/

DBCC FREEPROCCACHE;
CHECKPOINT;
DBCC DROPCLEANBUFFERS;

SET STATISTICS TIME ON;


SELECT 
    C.custid, 
    C.companyname,
    O.orderid, 
    O.orderdate
FROM Sales.Customers AS C
    INNER JOIN Sales.Orders AS O
        ON C.custid = O.custid;



DBCC DROPCLEANBUFFERS;
SELECT 
    C.custid, 
    C.companyname,
    O.orderid, 
    O.orderdate
FROM Sales.Customers AS C
    INNER JOIN Sales.Orders AS O
        ON C.custid = O.custid
WHERE O.custid < 5;

SET STATISTICS TIME OFF;



--============================================================================================================================================
--The Most Important DMOs for Query Tuning
--============================================================================================================================================
SELECT 
    cpu_count AS logical_cpu_count,
    cpu_count / hyperthread_ratio AS physical_cpu_count,
    CAST(physical_memory_kb / 1024. AS int) AS physical_memory__mb,
    sqlserver_start_time
FROM sys.dm_os_sys_info;

--============================================================================================================================================
-- dm_os_waiting_tasks
--============================================================================================================================================
SELECT 
    S.login_name
    , S.host_name
    , S.program_name
    ,WT.session_id
    , WT.wait_duration_ms
    , WT.wait_type
    ,WT.blocking_session_id
    , WT.resource_description
FROM sys.dm_os_waiting_tasks AS WT
    INNER JOIN sys.dm_exec_sessions AS S
        ON WT.session_id = S.session_id
WHERE s.is_user_process = 1;

--============================================================================================================================================
--sys.dm_exec_requests
--============================================================================================================================================
SELECT 
    S.login_name, 
    S.host_name, 
    S.program_name,
    R.command, 
    T.text,
    R.wait_type, 
    R.wait_time, 
    R.blocking_session_id
FROM sys.dm_exec_requests AS R
    INNER JOIN sys.dm_exec_sessions AS S
        ON R.session_id = S.session_id
    OUTER APPLY sys.dm_exec_sql_text(R.sql_handle) AS T
WHERE S.is_user_process = 1;

--============================================================================================================================================
-- most time consuming
--============================================================================================================================================
SELECT TOP (5)
    (total_logical_reads + total_logical_writes) AS total_logical_IO,
    execution_count,
    (total_logical_reads/execution_count) AS avg_logical_reads,
    (total_logical_writes/execution_count) AS avg_logical_writes,
    (
    SELECT SUBSTRING
        (text, statement_start_offset/2 + 1,
            (CASE WHEN statement_end_offset = -1
            THEN LEN(CONVERT(nvarchar(MAX),text)) * 2
            ELSE statement_end_offset
            END - statement_start_offset)
        /2)
    FROM sys.dm_exec_sql_text(sql_handle)
    ) AS query_text
FROM sys.dm_exec_query_stats
ORDER BY (total_logical_reads + total_logical_writes) DESC;



--============================================================================================================================================
--indexes that were not used from the last start of the instance
--============================================================================================================================================
SELECT 
    OBJECT_NAME(I.object_id) AS objectname,
    I.name AS indexname,
    I.index_id AS indexid
FROM sys.indexes AS I
    INNER JOIN sys.objects AS O
        ON O.object_id = I.object_id
WHERE I.object_id > 100
    AND I.type_desc = 'NONCLUSTERED'
    AND I.index_id NOT IN
        (
        SELECT S.index_id
        FROM sys.dm_db_index_usage_stats AS S
        WHERE S.object_id=I.object_id
        AND I.index_id=S.index_id
        AND database_id = DB_ID('TSQL2012')
        )
ORDER BY objectname, indexname;

--============================================================================================================================================
--Find missing indexes
--============================================================================================================================================
SELECT MID.statement AS [Database.Schema.Table],
    MIC.column_id AS ColumnId,
    MIC.column_name AS ColumnName,
    MIC.column_usage AS ColumnUsage,
    MIGS.user_seeks AS UserSeeks,
    MIGS.user_scans AS UserScans,
    MIGS.last_user_seek AS LastUserSeek,
    MIGS.avg_total_user_cost AS AvgQueryCostReduction,
    MIGS.avg_user_impact AS AvgPctBenefit
FROM sys.dm_db_missing_index_details AS MID
    CROSS APPLY sys.dm_db_missing_index_columns (MID.index_handle) AS MIC
        INNER JOIN sys.dm_db_missing_index_groups AS MIG
            ON MIG.index_handle = MID.index_handle
    INNER JOIN sys.dm_db_missing_index_group_stats AS MIGS
        ON MIG.index_group_handle=MIGS.group_handle
ORDER BY MIGS.avg_user_impact DESC;

------------------------------




--============================================================================================================================================
--Execution plan
--============================================================================================================================================

SELECT 
    C.custid, 
    MIN(C.companyname) AS companyname,
    COUNT(*) AS numorders
FROM Sales.Customers AS C
    INNER JOIN Sales.Orders AS O
        ON C.custid = O.custid
WHERE O.custid = '5'
GROUP BY C.custid
HAVING COUNT(*) > 6;


/*===============================================================================================================================
JOINs
=================================================================================================================================*/

SELECT 
    C.custid, 
    C.companyname,
    O.orderid, 
    O.orderdate
FROM Sales.Customers AS C
    INNER JOIN Sales.Orders AS O
        ON C.custid = O.custid
ORDER BY C.custid, O.orderid;


SELECT 
    C.custid, 
    C.companyname,
    O.orderid, 
    O.orderdate
FROM Sales.Customers AS C
    INNER MERGE JOIN   Sales.Orders AS O 
        ON C.custid = O.custid
ORDER BY C.custid, O.orderid;


SELECT 
    C.custid, 
    C.companyname,
    O.orderid, 
    O.orderdate
FROM Sales.Customers AS C
    INNER LOOP JOIN  Sales.Orders AS O
        ON C.custid = O.custid
ORDER BY C.custid, O.orderid;

SELECT 
    C.custid, 
    C.companyname,
    O.orderid, 
    O.orderdate
FROM Sales.Customers AS C
    INNER HASH JOIN  Sales.Orders AS O
        ON C.custid = O.custid
ORDER BY C.custid, O.orderid;





--=======================================================================
-- Understanding Cursors, Sets, and Temporary Tables
--=======================================================================
USE TSQL2012; 
 
IF OBJECT_ID('Sales.ProcessCustomer') IS NOT NULL   DROP PROC Sales.ProcessCustomer; 
GO 
 
CREATE PROC Sales.ProcessCustomer (   @custid AS INT ) 
AS  
PRINT 'Processing customer ' + CAST(@custid AS VARCHAR(10)); 
GO


--=======================================================================
-- Cursor
--=======================================================================
SET NOCOUNT ON; 
 
DECLARE @curcustid AS INT; 
 
DECLARE cust_cursor CURSOR FAST_FORWARD FOR   
SELECT custid   
FROM Sales.Customers;

OPEN cust_cursor; 
 
FETCH NEXT FROM cust_cursor INTO @curcustid; 
 
WHILE @@FETCH_STATUS = 0 
BEGIN   
    EXEC Sales.ProcessCustomer @custid = @curcustid; 
    FETCH NEXT FROM cust_cursor INTO @curcustid; 
END; 
 
CLOSE cust_cursor; 
 
DEALLOCATE cust_cursor; 
GO
 
--=======================================================================
-- another approach
--=======================================================================
SET NOCOUNT ON; 
 
DECLARE @curcustid AS INT; 
 
SET @curcustid = 
(
    SELECT TOP (1) custid
    FROM Sales.Customers
    ORDER BY custid
); 
 
WHILE @curcustid IS NOT NULL 
BEGIN   
EXEC Sales.ProcessCustomer @custid = @curcustid;      
SET @curcustid = 
(
    SELECT TOP (1) custid                     
    FROM Sales.Customers                     
    WHERE custid > @curcustid                     
    ORDER BY custid
); 
END; 
GO


--=======================================================================
-- using temporary tables vs. table variables
--=======================================================================
 
 -- temp table
 CREATE TABLE #T1 (   col1 INT NOT NULL ); 
 
INSERT INTO #T1(col1) VALUES(10), (11), (12); 
 
EXEC('SELECT col1 FROM #T1;');
 GO 
 
SELECT col1 FROM #T1; 
GO 
 
DROP TABLE #T1;
 GO

 -- table variable
 DECLARE @T1 AS TABLE (   col1 INT NOT NULL ); 
 
INSERT INTO @T1(col1) VALUES(10), (11), (12); 

SELECT * FROM @T1

EXEC('SELECT col1 FROM @T1;'); 
GO

--SELECT * FROM @T1; 
GO



 -- transaction
CREATE TABLE #T1 (   col1 INT NOT NULL ); 
 
BEGIN TRAN 
 
  INSERT INTO #T1(col1) VALUES(10); 
 
ROLLBACK TRAN 
 
SELECT col1 FROM #T1; 
 
DROP TABLE #T1; 
GO


DECLARE @T1 AS TABLE (   col1 INT NOT NULL ); 
 
BEGIN TRAN 
 
  INSERT INTO @T1(col1) VALUES(10); 
 
ROLLBACK TRAN 
 
SELECT col1 FROM @T1;
