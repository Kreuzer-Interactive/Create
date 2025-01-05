@echo off
REM Usage: copy.bat <source_dir> <dest_dir>
IF "%1"=="" GOTO usage
IF "%2"=="" GOTO usage

REM Check if destination directory exists
if not exist "%2" (
    echo Error: Destination directory does not exist!
    echo Creating: %2
    md "%2"
    if errorlevel 1 (
        echo Failed to create directory!
        pause
        exit /b 1
    )
)

REM Check if source files exist
if not exist "%1\CREATE5.BAS" (
    echo Error: CREATE5.BAS not found in %1!
    pause
    exit /b 1
)

if not exist "%1\CFG.INI" (
    echo Error: CFG.INI not found in %1!
    pause
    exit /b 1
)

REM Clean up old files
del %2\CREATE5.BAS 2>nul
del %2\CFG.INI 2>nul
del %2\CREATE5.MAK 2>nul
del %2\DEV.BAT 2>nul

REM Create directories if they don't exist
md %2\assets 2>nul
md %2\modules 2>nul

REM Copy main files
copy "%1\CREATE5.BAS" "%2"
if errorlevel 1 goto :error
copy "%1\CFG.INI" "%2"
if errorlevel 1 goto :error
copy "%1\CREATE5.MAK" "%2"
if errorlevel 1 goto :error
copy "%1\DEV.BAT" "%2"
if errorlevel 1 goto :error

REM Copy all assets and subdirectories
xcopy /s /y "%1\assets\*.*" "%2\assets\"
if errorlevel 1 goto :error

REM Copy all modules
xcopy /s /y "%1\modules\*.*" "%2\modules\"
if errorlevel 1 goto :error

echo Files copied successfully!
goto :end

:usage
echo Usage: copy.bat ^<source_dir^> ^<dest_dir^>
echo Example: copy.bat . \Code\dosbox\HD\SPACE2\V5\CREATE
exit /b 1

:error
echo An error occurred during file copying!
pause
exit /b 1

:end
REM pause