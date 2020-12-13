   SET STATISTICS TIME ON;
   
    SELECT  wil.[ItemId] AS WorkItemId
            ,(SELECT wit.[WorkItemTypeId]
                FROM [dbo].[WorkItemType] AS wit WHERE wit.[WorkItemTypeName] = wil.[WorkItemType]) AS WorkItemTypeId
            ,(SELECT tp.[TeamProjectId] 
                FROM [dbo].[TeamProject] AS tp	WHERE tp.[TeamProjectName] = wil.[TeamProject]) AS TeamProjectId
            ,(SELECT st.[StateId] 
                FROM [dbo].[State] AS st WHERE st.[StateName] = wil.[State]) AS CurrentStateId
            ,(CASE WHEN (wil.[State] = 'New' AND wil.StateChangeDate IS NULL) THEN
                    (SELECT dd.[DateKey] 
                    FROM [dbo].[DimDate] AS dd WHERE dd.[FullDate] = CAST(wil.[CreatedDate] AS DATE))
                WHEN wil.[WorkItemType] = 'System Alert' THEN
                    (SELECT dd.[DateKey] 
                    FROM [dbo].[DimDate] AS dd WHERE dd.[FullDate] = CAST(wil.[ChangedDate] AS DATE))
                ELSE
                    COALESCE((SELECT dd.[DateKey] 
                    FROM [dbo].[DimDate] AS dd WHERE dd.[FullDate] = CAST(wil.[StateChangeDate] AS DATE)), NULL, -1)
              END
              ) AS CurrentStateDateKey                
            ,(SELECT dd.[DateKey] 
                FROM [dbo].[DimDate] AS dd WHERE dd.[FullDate] = CAST(wil.[CreatedDate] AS DATE))  AS CreatedDateKey
            ,wil.[Title] AS Title
            ,COALESCE((SELECT p.[PriorityId] 
                FROM [dbo].[Priority] AS p WHERE p.[PriorityValue] = wil.[Priority]), NULL, -1) AS  PriorityId
            ,COALESCE((SELECT u.[ID] 
                FROM [dbo].[Users] AS u WHERE u.[UserName] = wil.[AssignedToName]), NULL, -1) AS AssignedToId
            ,(SELECT u.[ID] 
                FROM [dbo].[Users] AS u	WHERE u.[UserName] = wil.ChangedByName) AS ChangeById
            ,wil.[CreatedDate] AS CreatedDateTime
            ,(CASE WHEN (wil.[State] = 'New' AND wil.StateChangeDate IS NULL) THEN
                    wil.[CreatedDate]
                WHEN wil.[WorkItemType] = 'System Alert' THEN
                    wil.[ChangedDate]
                ELSE wil.[StateChangeDate]
             END) AS CurrentStateDateTime
             --Added by Boykov Sergey 20180219--
            , (SELECT a.[ActivityId]
                FROM [dbo].[Activity] AS a WHERE a.[ActivityName] = wil.[Activity]) AS [ActivityId]
            , wil.[EffortOriginalEstimate] AS [EffortOriginalEstimate]
            , wil.[EffortRemaining] AS [EffortRemaining]
            , wil.[EffortCompleted] AS [EffortCompleted]
            , wil.[IterationPath] AS [IterationPath]            ----
    FROM [staging].[TFSWorkItems_Loaded] AS wil

/*=============================================================================================================================================
another way


==============================================================================================================================================*/

SELECT  
     wil.[ItemId]                                       AS WorkItemId
    ,wit.[WorkItemTypeId]                               AS WorkItemTypeId
    ,tp.[TeamProjectId]                                 AS TeamProjectId
    ,st.[StateId]                                       AS StateId
    ,(CASE WHEN (wil.[State] = 'New' AND wil.StateChangeDate IS NULL) THEN
            (SELECT dd.[DateKey] 
            FROM [dbo].[DimDate] AS dd WHERE dd.[FullDate] = CAST(wil.[CreatedDate] AS DATE))
        WHEN wil.[WorkItemType] = 'System Alert' THEN
            (SELECT dd.[DateKey] 
            FROM [dbo].[DimDate] AS dd WHERE dd.[FullDate] = CAST(wil.[ChangedDate] AS DATE))
        ELSE
            COALESCE((SELECT dd.[DateKey] 
            FROM [dbo].[DimDate] AS dd WHERE dd.[FullDate] = CAST(wil.[StateChangeDate] AS DATE)), NULL, -1)
        END
        ) AS CurrentStateDateKey                
    ,dd.[DateKey]                                       AS CreatedDateKey
    ,wil.[Title]                                        AS Title
    ,COALESCE(p.[PriorityId],-1)                        AS  PriorityId
    ,COALESCE(au.[ID]       ,-1)                        AS  AssignedToId
    ,COALESCE(cu.[ID]       ,-1)                        AS  ChangeById
    ,a.[ActivityId]                                     AS  ActivityId
    ,wil.[CreatedDate]                                  AS CreatedDateTime
    ,CASE 
        WHEN (wil.[State] = 'New' AND wil.StateChangeDate IS NULL)  THEN wil.[CreatedDate]
        WHEN wil.[WorkItemType] = 'System Alert'                    THEN wil.[ChangedDate]
        ELSE wil.[StateChangeDate]
        END                                             AS CurrentStateDateTime
    ,wil.[EffortOriginalEstimate]                       AS [EffortOriginalEstimate]
    ,wil.[EffortRemaining]                              AS [EffortRemaining]
    ,wil.[EffortCompleted]                              AS [EffortCompleted]
    ,wil.[IterationPath]                                AS [IterationPath]
FROM [staging].[TFSWorkItems_Loaded] AS wil
    INNER JOIN [dbo].[WorkItemType] AS wit 
        ON wit.[WorkItemTypeName] = wil.[WorkItemType]
    INNER JOIN [dbo].[TeamProject] AS tp
        ON tp.[TeamProjectName] = wil.[TeamProject]
    INNER JOIN [dbo].[State] AS st 
        ON st.[StateName] = wil.[State]
    INNER JOIN [dbo].[DimDate] AS dd 
        ON dd.[FullDate] = CAST(wil.[CreatedDate] AS DATE)
    INNER JOIN [dbo].[Activity] AS a 
        ON a.[ActivityName] = wil.[Activity]
    LEFT OUTER JOIN [dbo].[Priority] AS p 
        ON p.[PriorityValue] = wil.[Priority]
    LEFT OUTER JOIN [dbo].[Users] AS au 
        ON au.[UserName] = wil.[AssignedToName]
    LEFT OUTER JOIN [dbo].[Users] AS cu 
        ON cu.[UserName] = wil.[ChangedByName]

/*
SELECT  wil.[ItemId] AS WorkItemId
,(SELECT wit.[WorkItemTypeId]
    FROM [dbo].[WorkItemType] AS wit WHERE wit.[WorkItemTypeName] = wil.[WorkItemType]) AS WorkItemTypeId
    FROM [staging].[TFSWorkItems_Loaded] AS wil

SELECT  
    wil.[ItemId] AS WorkItemId
    ,wit.[WorkItemTypeId]
                FROM [staging].[TFSWorkItems_Loaded] AS wil
    INNER JOIN [dbo].[WorkItemType] AS wit 
        ON wit.[WorkItemTypeName] = wil.[WorkItemType]
        */

        SET STATISTICS TIME OFF;