  sqlcmd -S GEARSERVER\SQLEXPRESS -d PRODUCTION -E -Q "SELECT DISTINCT [WC_Vendor] FROM [PRODUCTION].[dbo].[Job_Operation] WHERE Last_Updated >= DATEADD(YEAR, -1, GETDATE())" -o "c:/phoenixapps/shophawk/csv_files/workcenters.csv" -W -w 1024 -s "`" -f 65001 -h -1
