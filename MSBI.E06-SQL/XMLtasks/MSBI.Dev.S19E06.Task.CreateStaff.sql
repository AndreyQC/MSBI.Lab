IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[M_USER_PREFERENCRES]') AND type in (N'U'))
DROP TABLE [dbo].[M_USER_PREFERENCRES]

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[M_USER]') AND type in (N'U'))
DROP TABLE [dbo].[M_USER]

CREATE TABLE [M_USER]
(
    [user_id]       numeric(18,0) not null,
    first_name      nvarchar(64),
    last_name       nvarchar(64),
    middle_name     nvarchar(64),
    address         nvarchar(256),
    city            nvarchar(64),
    country         nvarchar(64),
    user_company    nvarchar(64),
    phone           nvarchar(64),
    email           nvarchar(900),
    age             int     
)

ALTER TABLE M_USER
   ADD CONSTRAINT PK_M_USER PRIMARY KEY CLUSTERED ([user_id])

CREATE TABLE [M_USER_PREFERENCRES]
(
    [user_id]       numeric(18,0) not null,
    preferences     xml
)

ALTER TABLE M_USER_PREFERENCRES
   ADD CONSTRAINT PK_M_USER_PREFERENCRES PRIMARY KEY CLUSTERED ([user_id])

ALTER TABLE M_USER_PREFERENCRES
   ADD CONSTRAINT FK_M_USER_PREFERENCRES_REF_M_USER FOREIGN KEY ([user_id])
      REFERENCES M_USER ([user_id])

INSERT INTO [M_USER]
    ([user_id], first_name, last_name, middle_name, address, city, country, user_company,
     phone, email, age)
VALUES
    (1, 'Anil', 'Sistla', 'K', '40 Fulton Street', 'New York', 'USA', 'Anil & Ko',
     '(212)328 7225', 'anil.sistla@yahoo.com', 27)

INSERT INTO [M_USER]
    ([user_id], first_name, last_name, middle_name, address, city, country, user_company,
     phone, email, age)
VALUES
    (2, 'Keith', 'Watt', NULL, '21 Riverside Road', 'Boston', 'USA', 'Basketball Dream',
     '(212)513 1859', 'keith.watt@yahoo.com', 33)

INSERT INTO [M_USER]
    ([user_id], first_name, last_name, middle_name, address, city, country, user_company,
     phone, email, age)
VALUES
    (3, 'Jason', 'Patel', NULL, '54 Northern Beach', 'Los Angeles', 'USA', 'XBox forever',
     '(212)427 1963', 'jason.patel@yahoo.com', 31)

INSERT INTO [M_USER]
    ([user_id], first_name, last_name, middle_name, address, city, country, user_company,
     phone, email, age)
VALUES
    (4, 'Andy', 'Liu', NULL, '97 Chan Kai Shi', 'Taipei', 'Taiwan', 'China computers',
     '(318)444 8888', 'andy.liu@yahoo.com', 26)

INSERT INTO [M_USER]
    ([user_id], first_name, last_name, middle_name, address, city, country, user_company,
     phone, email, age)
VALUES
    (5, 'Alex', 'Marrs', NULL, '42 Fulton Street', 'New York', 'USA', 'The Company',
     '(212)427 6587', 'alex.marrs@yahoo.com', 29)
    
;
WITH XMLNAMESPACES (DEFAULT 'http://schemas.test.com/XMLTest')
INSERT INTO [M_USER_PREFERENCRES]
    ([user_id], preferences)
SELECT ut.[user_id],
       (SELECT age          AS [Age],
               'None'       AS [AgeDescription],
               email        AS [Email],
               first_name   AS [FirstName],
               last_name    AS [LastName],
               middle_name  AS [MiddleName],
               phone        AS [Phone]
            FROM [M_USER] ut1
            WHERE ut1.[user_id] = ut.[user_id]
        FOR XML PATH('PersonalData'), ROOT('UserInfo'))
    FROM [M_USER] ut