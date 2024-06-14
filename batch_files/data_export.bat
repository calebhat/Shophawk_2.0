sqlcmd -S GEARSERVER\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [User_Values] ,[Text1] FROM [PRODUCTION].[dbo].[User_Values] WHERE Text1 IS NOT NULL AND User_Values in false" -o "c:/phoenixapps/shophawkdev/csv_files/uservalues.csv" -W -w 1024 -s "`" -f 65001 -h -1 
sqlcmd -S GEARSERVER\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job_Operation] ,[Employee] ,[Work_Date] ,[Act_Setup_Hrs] ,[Act_Run_Hrs] ,[Act_Run_Qty] ,[Act_Scrap_Qty] ,[Note_Text] FROM [PRODUCTION].[dbo].[Job_Operation_Time] WHERE Job_Operation in (787827, 787826, 787825, 787824, 787823, 787822, 787821, 787820, 787819, 787818, 787817, 787816) ORDER BY Job_Operation DESC" -o "c:/phoenixapps/shophawkdev/csv_files/operationtime.csv" -W -w 1024 -s "`" -f 65001 -h -1

