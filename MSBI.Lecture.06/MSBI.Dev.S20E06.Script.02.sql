--andreypotapov.database.windows.net
--Query source: PROCEDURE [staging].[WorkItem_ProcessFromJson]

DROP TABLE IF EXISTS #T1;
DROP TABLE IF EXISTS #T2;

SET STATISTICS TIME ON;


         SELECT 
            wie.ItemId,
            wie.[Relations] AS [ParentWorkItemId],
            wiss.WorkItemSourceSystemId,
            JSON_VALUE(wie.[Fields], '$."System.TeamProject"') AS [TeamProject],
            JSON_VALUE(wie.[Fields], '$."System.WorkItemType"') AS [WorkItemType],
            JSON_VALUE(wie.[Fields], '$."System.State"') AS [State],
            RTRIM(SUBSTRING(JSON_VALUE(wie.[Fields], '$."System.AssignedTo"'), 1, charindex (' <',JSON_VALUE(wie.[Fields], '$."System.AssignedTo"')))) AS [AssignedToName],
            REPLACE(LTRIM(STUFF(JSON_VALUE(wie.[Fields], '$."System.AssignedTo"'), 1, charindex('<', JSON_VALUE(wie.[Fields], '$."System.AssignedTo"')), ' ')), '>', '')  AS [AssignedToEmail],
            CONVERT(datetime2, JSON_VALUE(wie.[Fields], '$."System.CreatedDate"')) AS [CreatedDate],
            RTRIM(SUBSTRING(JSON_VALUE(wie.[Fields], '$."System.CreatedBy"'), 1, charindex (' <',JSON_VALUE(wie.[Fields], '$."System.CreatedBy"')))) AS [CreatedByName],
            REPLACE(LTRIM(STUFF(JSON_VALUE(wie.[Fields], '$."System.CreatedBy"'), 1, charindex('<', JSON_VALUE(wie.[Fields], '$."System.CreatedBy"')), ' ')), '>', '')  AS [CreatedByEmail],	
            CONVERT(datetime2, JSON_VALUE(wie.[Fields], '$."System.ChangedDate"')) AS [ChangedDate],
            RTRIM(SUBSTRING(JSON_VALUE(wie.[Fields], '$."System.ChangedBy"'), 1, charindex (' <',JSON_VALUE(wie.[Fields], '$."System.ChangedBy"')))) AS [ChangedByName],
            REPLACE(LTRIM(STUFF(JSON_VALUE(wie.[Fields], '$."System.ChangedBy"'), 1, charindex('<', JSON_VALUE(wie.[Fields], '$."System.ChangedBy"')), ' ')), '>', '')  AS [ChangedByEmail],
            JSON_VALUE(wie.[Fields], '$."System.Title"') AS [Title],
            JSON_VALUE(wie.[Fields], '$."Microsoft.VSTS.Common.Priority"') AS [Priority],
            CONVERT(datetime2, JSON_VALUE(wie.[Fields], '$."Microsoft.VSTS.Common.StateChangeDate"')) AS [StateChangeDate],
            RTRIM(SUBSTRING(JSON_VALUE(wie.[Fields], '$."Microsoft.VSTS.Common.ActivatedBy"'), 1, charindex (' <',JSON_VALUE(wie.[Fields], '$."Microsoft.VSTS.Common.ActivatedBy"')))) AS [ActivatedByName],
            REPLACE(LTRIM(STUFF(JSON_VALUE(wie.[Fields], '$."Microsoft.VSTS.Common.ActivatedBy"'), 1, charindex('<', JSON_VALUE(wie.[Fields], '$."Microsoft.VSTS.Common.ActivatedBy"')), ' ')), '>', '')  AS [ActivatedByEmail],
            wie.Tag AS [Tags],
            --Added by Boykov Sergey 20180219--
            JSON_VALUE(wie.[Fields], '$."Microsoft.VSTS.Common.Activity"') AS [Activity],
            JSON_VALUE(wie.[Fields], '$."Microsoft.VSTS.Scheduling.OriginalEstimate"') AS [EffortOriginalEstimate],
            JSON_VALUE(wie.[Fields], '$."Microsoft.VSTS.Scheduling.RemainingWork"') AS [EffortRemaining],
            JSON_VALUE(wie.[Fields], '$."Microsoft.VSTS.Scheduling.CompletedWork"') AS [EffortCompleted],
            JSON_VALUE(wie.[Fields], '$."System.IterationPath"') AS [IterationPath],
            ----
            wie.Fields AS [Json]
		INTO #T1
        FROM
            [staging].[TFSWorkItems_extracted] as wie WITH (NOLOCK)
                INNER JOIN [dbo].[WorkItemSourceSystem] AS wiss
                    ON wiss.SourceSystemUrl=REPLACE(wie.[Url],wie.ItemID,''); 





         SELECT 
            wie.ItemId,
            wie.[Relations] AS [ParentWorkItemId],
            wiss.WorkItemSourceSystemId,
            js.[TeamProject],
            js.[WorkItemType],
            js.[State],
            RTRIM(SUBSTRING(js.[AssignedTo], 1, charindex (' <', js.[AssignedTo]))) AS [AssignedToName],
            REPLACE(LTRIM(STUFF(js.[AssignedTo], 1, charindex('<', js.[AssignedTo]), ' ')), '>', '')  AS [AssignedToEmail],
            js.[CreatedDate],
            RTRIM(SUBSTRING(js.[CreatedBy], 1, charindex (' <',js.[CreatedBy]))) AS [CreatedByName],
            REPLACE(LTRIM(STUFF(js.[CreatedBy], 1, charindex('<', js.[CreatedBy]), ' ')), '>', '')  AS [CreatedByEmail],	
            js.[ChangedDate],
            RTRIM(SUBSTRING(js.[ChangedBy], 1, charindex (' <',js.[ChangedBy]))) AS [ChangedByName],
            REPLACE(LTRIM(STUFF(js.[ChangedBy], 1, charindex('<', js.[ChangedBy]), ' ')), '>', '')  AS [ChangedByEmail],
            js.[Title],
            js.[Priority],
            js.[StateChangeDate],
            RTRIM(SUBSTRING(js.[ActivatedBy], 1, charindex (' <',js.[ActivatedBy]))) AS [ActivatedByName],
            REPLACE(LTRIM(STUFF(js.[ActivatedBy], 1, charindex('<', js.[ActivatedBy]), ' ')), '>', '')  AS [ActivatedByEmail],
            wie.Tag AS [Tags],
            --Added by Boykov Sergey 20180219--
            js.[Activity],
            js.[EffortOriginalEstimate],
            js.[EffortRemaining],
            js.[EffortCompleted],
            js.[IterationPath],
            ----
            wie.Fields AS [Json]
		INTO #T2
        FROM
            [staging].[TFSWorkItems_extracted] as wie WITH (NOLOCK)
                INNER JOIN [dbo].[WorkItemSourceSystem] AS wiss
                    ON wiss.SourceSystemUrl=REPLACE(wie.[Url],wie.ItemID,'')
			OUTER APPLY OPENJSON(wie.[Fields]) WITH(
				[TeamProject]				NVARCHAR(500)	'$."System.TeamProject"',
				[WorkItemType]				NVARCHAR(100)	'$."System.WorkItemType"',
				[State]						NVARCHAR(100)	'$."System.State"',
				[AssignedTo]				NVARCHAR(1000)	'$."System.AssignedTo"',
				[CreatedDate]				DATETIME2		'$."System.CreatedDate"',
				[CreatedBy]					NVARCHAR(1000)	'$."System.CreatedBy"',
				[ChangedDate]				DATETIME2		'$."System.ChangedDate"',
				[ChangedBy]					NVARCHAR(1000)	'$."System.ChangedBy"',
				[Title]						NVARCHAR(MAX)	'$."System.Title"',
				[Priority]					TINYINT			'$."Microsoft.VSTS.Common.Priority"',
				[StateChangeDate]			DATETIME2		'$."Microsoft.VSTS.Common.StateChangeDate"',
				[ActivatedBy]				NVARCHAR(1000)	'$."Microsoft.VSTS.Common.ActivatedBy"',
				[Activity]					NVARCHAR(500)	'$."Microsoft.VSTS.Common.Activity"',
				[EffortOriginalEstimate]	NVARCHAR(MAX)	'$."Microsoft.VSTS.Scheduling.OriginalEstimate"',
				[EffortRemaining]			NVARCHAR(MAX)	'$."Microsoft.VSTS.Scheduling.RemainingWork"',
				[EffortCompleted]			NVARCHAR(MAX)	'$."Microsoft.VSTS.Scheduling.CompletedWork"',
				[IterationPath]				NVARCHAR(MAX)	'$."System.IterationPath"'
			) AS js
		;

SET STATISTICS TIME OFF;