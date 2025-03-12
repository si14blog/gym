@echo off
setlocal enabledelayedexpansion

REM ---------------------------------------------------------------------------
REM 1) Define SQL Server instance and database name
REM ---------------------------------------------------------------------------
set SQLSERVER=.\SQL2022
set DATABASE=Nucro_DB
set OUTPUT_DIR=%CD%

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
REM 3) Get all table names (including schema) and save to tables.txt
REM ---------------------------------------------------------------------------
echo Retrieving table names from %DATABASE%...
sqlcmd -S %SQLSERVER% -E -d %DATABASE% -h -1 -W -Q "SELECT TABLE_SCHEMA + '.' + TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE'" > tables.txt

IF NOT EXIST tables.txt (
    echo ERROR: Failed to retrieve table names!
    pause
    exit /b 1
)

REM ---------------------------------------------------------------------------
REM 4) Loop through each table and export to CSV
REM ---------------------------------------------------------------------------
for /f "delims=" %%i in (tables.txt) do (
    set TABLENAME=%%i
    set TABLENAME=!TABLENAME:.=_!

    echo Exporting table [%%i] to CSV...
    bcp "SELECT * FROM [%DATABASE%].%%i" queryout "%OUTPUT_DIR%\!TABLENAME!.csv" -S %SQLSERVER% -T -c -t, 

    IF %ERRORLEVEL% NEQ 0 (
        echo ERROR: Failed to export table %%i
    ) ELSE (
        echo Successfully exported %%i to !TABLENAME!.csv
    )
)

echo.
echo All tables exported successfully!
pause
exit /b 0
