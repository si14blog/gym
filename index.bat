@echo off

REM ---------------------------------------------------------------------------
REM 1) Use sqlcmd to get all table names from the SQL Server database.
REM    -S .\SQL2022 => connect to local instance named SQL2022
REM    -E          => use Windows Authentication
REM    -d gym      => connect to the 'gym' database
REM ---------------------------------------------------------------------------
echo Retrieving table names from SQL Server...
sqlcmd -S .\SQL2022 -E -d gym -h -1 -W -Q "SELECT TABLE_NAME 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_TYPE='BASE TABLE'" > tables.txt

REM ---------------------------------------------------------------------------
REM 2) Loop over each table name in tables.txt, export the data via bcp to CSV.
REM    - We create CSV files named <TableName>.csv in the current directory.
REM ---------------------------------------------------------------------------
for /f "skip=0 delims=" %%i in (tables.txt) do (
    echo -----------------------------------------------------------
    echo Exporting table [%%i] to CSV...
    
    REM Export table to CSV using bcp:
    REM   - queryout => run a SELECT * and output to file
    REM   - -c => character data type
    REM   -t, => use comma as field terminator
    REM   -T => use trusted connection (Windows Auth)
    bcp "SELECT * FROM [gym].[dbo].[%%i]" queryout "%%i.csv" -S .\SQL2022 -T -c -t,

    echo Done with table [%%i].
)

REM ---------------------------------------------------------------------------
REM 3) Cleanup or final messages
REM ---------------------------------------------------------------------------
echo.
echo All tables exported to CSV files!
echo Check the current folder for <TableName>.csv files.
