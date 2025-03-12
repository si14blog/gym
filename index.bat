@echo off
setlocal enabledelayedexpansion

REM ---------------------------------------------------------------------------
REM 1) Configure SQL Server connection details
REM ---------------------------------------------------------------------------
set SQLSERVER=.\SQL2022
set DATABASE=Nuoro_DB
set OUTPUT_DIR=C:\Exports

REM Create the output directory if it doesn't exist
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

REM ---------------------------------------------------------------------------
REM 2) Test SQL Server Connection
REM ---------------------------------------------------------------------------
echo Testing connection to %SQLSERVER%...
sqlcmd -S %SQLSERVER% -E -Q "SELECT name FROM sys.databases;" >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to connect to SQL Server or insufficient permissions!
    echo Make sure your Windows user has access to %DATABASE%.
    pause
    exit /b 1
)

echo Connection successful!

REM ---------------------------------------------------------------------------
REM 3) Retrieve all table names (including schema) and save to tables.txt
REM ---------------------------------------------------------------------------
echo Retrieving table names from %DATABASE%...
sqlcmd -S %SQLSERVER% -E -d %DATABASE% -h -1 -W -Q "SELECT TABLE_SCHEMA + '.' + TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE'" > tables.txt

IF NOT EXIST tables.txt (
    echo ERROR: Failed to retrieve table names!
    pause
    exit /b 1
)

REM ---------------------------------------------------------------------------
REM 4) Loop through each table and export its data to a CSV file
REM ---------------------------------------------------------------------------
for /f "delims=" %%i in (tables.txt) do (
    set TABLENAME=%%i
    REM Extract schema and table name separately
    for /f "tokens=1,2 delims=." %%a in ("%%i") do (
        set SCHEMA=%%a
        set TABLE=%%b
    )

    REM Make sure the table name is valid before continuing
    if "!TABLE!"=="" (
        echo ERROR: Invalid table name encountered: %%i
        continue
    )

    REM Replace dots (.) in table names with underscores (_) for filenames
    set FILENAME=!SCHEMA!_!TABLE!

    REM Export data from the table (without the database prefix)
    echo Exporting data from table [!SCHEMA!.!TABLE!] to CSV...
    bcp "SELECT * FROM !SCHEMA!.!TABLE!" queryout "%OUTPUT_DIR%\!FILENAME!.csv" -S %SQLSERVER% -T -c -t,

    IF %ERRORLEVEL% NEQ 0 (
        echo ERROR: Failed to export data from !SCHEMA!.!TABLE!
    ) ELSE (
        echo Successfully exported data from !SCHEMA!.!TABLE! to !FILENAME!.csv
    )
)

REM ---------------------------------------------------------------------------
REM 5) Cleanup and exit
REM ---------------------------------------------------------------------------
echo.
echo All tables data exported successfully!
echo Check the CSV files in: %OUTPUT_DIR%
pause
exit /b 0
