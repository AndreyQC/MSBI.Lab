/*=========================================
MSBI.DEV.COURSE.S21E08.SCRIPT
=========================================*/


/*=========================================
blocking
=========================================*/

USE TSQL2012;
BEGIN TRAN;

---------------------------------------------------------------

UPDATE HR.Employees
SET Region = N'10004'
WHERE empid = 1


---------------------------------------------------------------





---------------------------------------------------------------


UPDATE Production.Suppliers
SET Fax = N'555-1212'
WHERE supplierid = 1


---------------------------------------------------------------


IF @@TRANCOUNT > 0 ROLLBACK



/*=========================================
READ COMMITTED
=========================================*/

USE TSQL2012;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
-----------------------------------------------------



BEGIN TRAN;
------------------------------------------------------
SELECT empid, lastname, firstname, postalcode
FROM HR.Employees;

-------------------------------------------------------
COMMIT TRAN;




/*=========================================
READ UNCOMMITTED
Session 2
=========================================*/

USE TSQL2012;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
--1------------------------------------------------------------

--2------------------------------------------------------------
SELECT empid, lastname, firstname, postalcode
FROM HR.Employees
--3------------------------------------------------------------
--4------------------------------------------------------------
SELECT empid, lastname, firstname, postalcode
FROM HR.Employees;
--5------------------------------------------------------------
--6------------------------------------------------------------

SELECT empid, lastname, firstname
FROM HR.Employees WITH (READUNCOMMITTED);

SELECT empid, lastname, firstname
FROM HR.Employees WITH (NOLOCK);

/*=========================================
REPEATABLE READ
=========================================*/
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

BEGIN TRAN;
--1------------------------------------------------------------
SELECT empid, lastname, firstname, postalcode
FROM HR.Employees;
--2------------------------------------------------------------
--3------------------------------------------------------------
COMMIT TRAN;


/*=========================================
READ COMMITTED SNAPSHOT Session 1
=========================================*/

USE TSQL2012;
ALTER DATABASE TSQL2012 SET READ_COMMITTED_SNAPSHOT ON;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

--1------------------------------------------------------------
BEGIN TRAN;
--2------------------------------------------------------------
UPDATE HR.Employees
SET postalcode = N'10007'
WHERE empid = 1;
--3------------------------------------------------------------
--4------------------------------------------------------------
ROLLBACK TRAN;
--5------------------------------------------------------------
--6------------------------------------------------------------
-- Cleanup:
UPDATE HR.Employees
SET postalcode = N'10003'
WHERE empid = 1;




ALTER DATABASE TSQL2012 SET READ_COMMITTED_SNAPSHOT OFF;