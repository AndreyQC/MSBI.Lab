CREATE PROCEDURE [Library].[usp_BookItem_Get]
(
    @BookItemID      INT
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        --BEGIN TRANSACTION;

            SELECT  [BookItemID]
                    ,[BookID]
                    ,[sysCreatedAt]
                    ,[sysChangedAt]
                    ,[sysCreatedBy]
                    ,[sysChangedBy]
            FROM  [Library].[BookItem]
            WHERE  ([BookItemID] = @BookItemID OR @BookItemID IS NULL)

        --COMMIT TRANSACTION;
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

	THROW;
    END CATCH;
END
GO





CREATE PROCEDURE [Library].[usp_BookItem_Insert]
(
    @BookID         INT
    ,@BookItemID    INT     OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        BEGIN TRANSACTION;
            INSERT INTO [Library].[BookItem] 
            (
                [BookID]
            )
            VALUES 
            (
                @BookID
            );
            SET @BookItemID = SCOPE_IDENTITY();
        COMMIT TRANSACTION;

    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0
            BEGIN
                ROLLBACK TRANSACTION;
            END;

	THROW;
    END CATCH;
END
GO