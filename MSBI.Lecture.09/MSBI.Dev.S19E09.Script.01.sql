/*=========================================
MSBI.DEV.COURSE.S18E09.SCRIPT
=========================================*/


/*=========================================

=========================================*/

SELECT * FROM sys.dm_tran_active_transactions;


/*=========================================
Prepare data
=========================================*/

USE TSQL2012;
GO

DROP TABLE IF EXISTS #Categories;
DROP TABLE IF EXISTS #Products;

SELECT
	[categoryid]	= [categoryid] + 0,
	[categoryname]
INTO
	#Categories
FROM
	[Production].[Categories]
;
SELECT
	[productid]		= [productid] + 0,
	[productname],
	[categoryid],
	[unitprice]
INTO
	#Products
FROM
	[Production].[Products]
;

--SELECT * FROM #Categories;
--SELECT * FROM #Products;

/*=========================================
Basic transaction
=========================================*/
SELECT * FROM #Categories WHERE [categoryid] = 10;
SELECT * FROM #Products WHERE [productid] = 1;

BEGIN TRAN;
	INSERT INTO
		#Categories
		([categoryid], [categoryname])
	VALUES
		(10, N'Category')
	;
	UPDATE
		#Products
	SET
		[categoryid] = 10
	WHERE
		[productid] = 1
	;
COMMIT TRAN;

SELECT * FROM #Categories WHERE [categoryid] = 10;
SELECT * FROM #Products WHERE [productid] = 1;

/*=========================================
Rollback transaction
=========================================*/
SELECT * FROM #Categories WHERE [categoryid] = 11;
SELECT * FROM #Products WHERE [productid] = 1;

BEGIN TRAN;
	INSERT INTO
		#Categories
		([categoryid], [categoryname])
	VALUES
		(11, N'Shmategory')
	;
	UPDATE
		#Products
	SET
		[categoryid] = 11
	WHERE
		[productid] = 1
	;

	SELECT * FROM #Categories WHERE [categoryid] = 11;
	SELECT * FROM #Products WHERE [productid] = 1;
ROLLBACK TRAN;

SELECT * FROM #Categories WHERE [categoryid] = 11;
SELECT * FROM #Products WHERE [productid] = 1;

/*=========================================
Nested transaction
=========================================*/

SELECT @@TRANCOUNT, XACT_STATE(), N'Start';

BEGIN TRAN;
	SELECT @@TRANCOUNT, XACT_STATE(), N'First transaction';

		BEGIN TRAN; -- nested transaction
			SELECT @@TRANCOUNT, XACT_STATE(), N'Second transaction';
		COMMIT TRAN;

	SELECT @@TRANCOUNT, XACT_STATE(), N'First commit';
COMMIT TRAN;

SELECT @@TRANCOUNT, XACT_STATE(), N'Second commit';


/*=========================================
Rollback transaction
=========================================*/

SELECT @@TRANCOUNT, XACT_STATE(), N'Start';

BEGIN TRAN;
	SELECT @@TRANCOUNT, XACT_STATE(), N'First transaction';

		BEGIN TRAN; -- nested transaction
			SELECT @@TRANCOUNT, XACT_STATE(), N'Second transaction';
		
ROLLBACK TRAN;	-- just once

SELECT @@TRANCOUNT, XACT_STATE(), N'Rollback';


/*=========================================
Rollback transaction
=========================================*/

SELECT * FROM #Categories WHERE [categoryid] = 11;
SELECT * FROM #Products WHERE [productid] = 1;

BEGIN TRAN;
	INSERT INTO
		#Categories
		([categoryid], [categoryname])
	VALUES
		(11, N'Shmategory')
	;

	BEGIN TRAN
		UPDATE
			#Products
		SET
			[categoryid] = 11
		WHERE
			[productid] = 1
		;
	COMMIT TRAN;

	SELECT * FROM #Categories WHERE [categoryid] = 11;
	SELECT * FROM #Products WHERE [productid] = 1;
ROLLBACK TRAN;

SELECT * FROM #Categories WHERE [categoryid] = 11;
SELECT * FROM #Products WHERE [productid] = 1;


/*=========================================
Save transaction
=========================================*/

SELECT * FROM #Categories WHERE [categoryid] = 11;
SELECT * FROM #Products WHERE [productid] = 1;

BEGIN TRAN;
	INSERT INTO
		#Categories
		([categoryid], [categoryname])
	VALUES
		(11, N'Shmategory')
	;

	SAVE TRAN SavePoint;
		UPDATE
			#Products
		SET
			[categoryid] = 11
		WHERE
			[productid] = 1
		;
	ROLLBACK TRAN SavePoint;
COMMIT TRAN;

SELECT * FROM #Categories WHERE [categoryid] = 11;
SELECT * FROM #Products WHERE [productid] = 1;


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

SELECT *  FROM sys.dm_tran_locks


/*=========================================
RAISERROR
=========================================*/

RAISERROR ('Error in usp_InsertCategories stored procedure', 16, 0);

-- style formating
RAISERROR ('Error in % stored procedure', 16, 0, N'usp_InsertCategories');

GO
DECLARE @message AS NVARCHAR(1000) = 'Error in % stored procedure';
RAISERROR (@message, 16, 0, N'usp_InsertCategories');

GO
DECLARE @message AS NVARCHAR(1000) = 'Error in % stored procedure';
SELECT @message = FORMATMESSAGE (@message, N'usp_InsertCategories');
RAISERROR (@message, 16, 0);

--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--A very simple RAISERROR int, 'string', was permitted in earlier versions of SQL Server but is
--no longer allowed in SQL Server 2012.


/*=========================================
THROW
=========================================*/
THROW 50000, 'Error in usp_InsertCategories stored procedure', 0;

GO
DECLARE @message AS NVARCHAR(1000) = 'Error in % stored procedure';
SELECT @message = FORMATMESSAGE (@message, N'usp_InsertCategories');
THROW 50000, @message, 0;


/*=========================================
Difference betweeen raiseerror and throw
=========================================*/
--RAISERROR doesn't terminate the batch
RAISERROR ('Hi there', 16, 0);
PRINT 'RAISERROR error'; -- Prints
GO
--THROW does terminate the batch
THROW 50000, 'Hi there', 0;
PRINT 'THROW error'; -- Does not print
GO


/*=========================================
TRY_CONVERT, TRY_CAST and TRY_PARSE
=========================================*/

SELECT TRY_CONVERT(DATETIME, '1752-12-31');
SELECT TRY_CONVERT(DATETIME, '1753-01-01');

SELECT TRY_CAST('1' AS INTEGER);
SELECT TRY_CAST('B' AS INTEGER);

SELECT TRY_PARSE('1' AS INTEGER);
SELECT TRY_PARSE('B' AS INTEGER);



/*=========================================
Using @@ERROR
=========================================*/

--works
DECLARE @errnum AS int;

SELECT 1/0;
SET @errnum = @@ERROR;
IF @errnum <> 0
    SELECT @errnum;

--doesn't work
SELECT 1/0;
IF @@ERROR <> 0
    SELECT @@ERROR;


/*=========================================
Work with Unstructured Error Handling
=========================================*/

SELECT * FROM Production.Products;

USE TSQL2012;
GO
DECLARE @errnum AS int;
     BEGIN TRAN;
          SET IDENTITY_INSERT Production.Products ON;
          -- Insert #1 will fail because of duplicate primary key
          INSERT 
               INTO Production.Products(productid, productname, supplierid,
                         categoryid, unitprice, discontinued)
               VALUES(1, N'Test1: Ok categoryid', 1, 1, 18.00, 0);
          SET @errnum = @@ERROR;
          IF @errnum <> 0
          BEGIN
               IF @@TRANCOUNT > 0 ROLLBACK TRAN;
               PRINT 'Insert #1 into Production.Products failed with error ' +
               CAST(@errnum AS VARCHAR);
          END;
            -- Insert #2 will succeed
          INSERT INTO Production.Products(productid, productname, supplierid,
				categoryid,unitprice, discontinued)
          VALUES(101, N'Test2: Bad categoryid', 1, 1, 18.00, 0);
          SET @errnum = @@ERROR;
          IF @errnum <> 0
          BEGIN
               IF @@TRANCOUNT > 0 ROLLBACK TRAN;
               PRINT 'Insert #2 into Production.Products failed with error ' +
               CAST(@errnum AS VARCHAR);
          END;
     SET IDENTITY_INSERT Production.Products OFF;
     IF @@TRANCOUNT > 0 COMMIT TRAN;
-- Remove the inserted row
DELETE FROM Production.Products WHERE productid = 101;
PRINT 'Deleted ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';



/*=========================================
--Use XACT_ABORT to Handle Errors
=========================================*/


USE TSQL2012;
GO
SET XACT_ABORT ON;
          PRINT 'Before error';
          SET IDENTITY_INSERT Production.Products ON;

          INSERT INTO Production.Products(productid, productname, supplierid, categoryid,
               unitprice, discontinued)
               VALUES(1, N'Test1: Ok categoryid', 1, 1, 18.00, 0);

          SET IDENTITY_INSERT Production.Products OFF;

          PRINT 'After error';
GO
          PRINT 'New batch';
SET XACT_ABORT OFF;


/*=========================================

=========================================*/
USE TSQL2012;
GO
SET XACT_ABORT ON;
     PRINT 'Before error';
          THROW 50000, 'Error in usp_InsertCategories stored procedure', 0;
     PRINT 'After error';
     GO
     PRINT 'New batch';
SET XACT_ABORT OFF;

/*=========================================

=========================================*/
USE TSQL2012;
GO
DECLARE @errnum AS int;
SET XACT_ABORT ON;
BEGIN TRAN;
     SET IDENTITY_INSERT Production.Products ON;
-- Insert #1 will fail because of duplicate primary key
     INSERT INTO Production.Products(productid, productname, supplierid,
          categoryid, unitprice, discontinued)
          VALUES(1, N'Test1: Ok categoryid', 1, 1, 18.00, 0);
          SET @errnum = @@ERROR;
     IF @errnum <> 0
     BEGIN
          IF @@TRANCOUNT > 0 ROLLBACK TRAN;
          PRINT 'Error in first INSERT';
     END;
-- Insert #2 no longer succeeds
     INSERT INTO Production.Products(productid, productname, supplierid,
          categoryid, unitprice, discontinued)
          VALUES(101, N'Test2: Bad categoryid', 1, 1, 18.00, 0);
          SET @errnum = @@ERROR;
     IF @errnum <> 0
     BEGIN
     -- Take actions based on the error
          IF @@TRANCOUNT > 0 ROLLBACK TRAN;
          PRINT 'Error in second INSERT';
     END;

SET IDENTITY_INSERT Production.Products OFF;

IF @@TRANCOUNT > 0 COMMIT TRAN;
GO
SELECT XACT_STATE(), @@TRANCOUNT;
GO
DELETE FROM Production.Products WHERE productid = 101;
PRINT 'Deleted ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
SET XACT_ABORT OFF;
GO



/*=========================================
Work with Structured Error Handling by Using TRY/CATCH
=========================================*/

USE TSQL2012;
GO
BEGIN TRY
     BEGIN TRAN;
          SET IDENTITY_INSERT Production.Products ON;

          INSERT INTO Production.Products(productid, productname, supplierid,
          categoryid, unitprice, discontinued)
          VALUES(1, N'Test1: Ok categoryid', 1, 1, 18.00, 0);

          INSERT INTO Production.Products(productid, productname, supplierid,
          categoryid, unitprice, discontinued)
          VALUES(101, N'Test2: Bad categoryid', 1, 10, 18.00, 0);

          SET IDENTITY_INSERT Production.Products OFF;
     COMMIT TRAN;
END TRY
BEGIN CATCH
     IF ERROR_NUMBER() = 2627 -- Duplicate key violation
          BEGIN
               PRINT 'Primary Key violation';
          END
     ELSE IF ERROR_NUMBER() = 547 -- Constraint violations
          BEGIN
               PRINT 'Constraint violation';
          END
     ELSE
          BEGIN
               PRINT 'Unhandled error';
          END;
     IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
END CATCH;

/*=========================================
Revise the CATCH block by using variables to capture error information and re-raise
the error using RAISERROR
=========================================*/


USE TSQL2012;
GO
SET NOCOUNT ON;
DECLARE @error_number AS INT, @error_message AS NVARCHAR(1000), @error_severity AS INT;
BEGIN TRY
     BEGIN TRAN;
          SET IDENTITY_INSERT Production.Products ON;

          INSERT 
               INTO Production.Products(productid, productname, supplierid, categoryid, unitprice, discontinued)
          VALUES(1, N'Test1: Ok categoryid', 1, 1, 18.00, 0);

          INSERT 
               INTO Production.Products(productid, productname, supplierid, categoryid, unitprice, discontinued)
          VALUES(101, N'Test2: Bad categoryid', 1, 10, 18.00, 0);

          SET IDENTITY_INSERT Production.Products OFF;
     COMMIT TRAN;
END TRY
BEGIN CATCH
     SELECT	XACT_STATE() as 'XACT_STATE',
               @@TRANCOUNT as '@@TRANCOUNT';
     SELECT @error_number = ERROR_NUMBER(),
            @error_message = ERROR_MESSAGE(),
            @error_severity = ERROR_SEVERITY();
     RAISERROR (@error_message, @error_severity, 1);
     IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
END CATCH;


/*=========================================
THROW statement without parameters to re-raise (re-throw) the original
error message and send it back to the client. This is by far the best method for reporting
the error back to the caller.
=========================================*/

USE TSQL2012;
GO
BEGIN TRY
     BEGIN TRAN;
          SET IDENTITY_INSERT Production.Products ON;

          INSERT 
               INTO Production.Products(productid, productname, supplierid, categoryid, unitprice, discontinued)
          VALUES(1, N'Test1: Ok categoryid', 1, 1, 18.00, 0);

          INSERT 
               INTO Production.Products(productid, productname, supplierid, categoryid, unitprice, discontinued)
          VALUES(101, N'Test2: Bad categoryid', 1, 10, 18.00, 0);

          SET IDENTITY_INSERT Production.Products OFF;
     COMMIT TRAN;
END TRY
BEGIN CATCH
     SELECT XACT_STATE() as 'XACT_STATE',
                @@TRANCOUNT as '@@TRANCOUNT';
     IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
          THROW;
END CATCH;
GO
SELECT XACT_STATE() as 'XACT_STATE', @@TRANCOUNT as '@@TRANCOUNT';