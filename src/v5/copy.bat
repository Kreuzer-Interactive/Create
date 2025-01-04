@echo off
REM Check if destination directory exists
if not exist "\Code\dosbox\HD\SPACE2\V5\CREATE\" (
    echo Error: Destination directory does not exist!
    echo Creating: \Code\dosbox\HD\SPACE2\V5\CREATE
    md "\Code\dosbox\HD\SPACE2\V5\CREATE"
    if errorlevel 1 (
        echo Failed to create directory!
        pause
        exit /b 1
    )
)

REM Check if source files exist
if not exist "CREATE5.BAS" (
    echo Error: CREATE5.BAS not found!
    pause
    exit /b 1
)

if not exist "CFG.INI" (
    echo Error: CFG.INI not found!
    pause
    exit /b 1
)

REM Clean up old files
del \Code\dosbox\HD\SPACE2\V5\CREATE\CREATE5.BAS 2>nul
del \Code\dosbox\HD\SPACE2\V5\CREATE\CFG.INI 2>nul
del \Code\dosbox\HD\SPACE2\V5\CREATE\CREATE5.MAK 2>nul
del \Code\dosbox\HD\SPACE2\V5\CREATE\DEV.BAT 2>nul

REM Create directories if they don't exist
md \Code\dosbox\HD\SPACE2\V5\CREATE\assets 2>nul
md \Code\dosbox\HD\SPACE2\V5\CREATE\modules 2>nul

REM Copy main files
copy CREATE5.BAS \Code\dosbox\HD\SPACE2\V5\CREATE
if errorlevel 1 goto :error
copy CFG.INI \Code\dosbox\HD\SPACE2\V5\CREATE
if errorlevel 1 goto :error
copy CREATE5.MAK \Code\dosbox\HD\SPACE2\V5\CREATE
if errorlevel 1 goto :error
copy DEV.BAT \Code\dosbox\HD\SPACE2\V5\CREATE
if errorlevel 1 goto :error

REM Copy all assets and subdirectories
xcopy /s /y assets\*.* \Code\dosbox\HD\SPACE2\V5\CREATE\assets\
if errorlevel 1 goto :error

REM Copy all modules
xcopy /s /y modules\*.* \Code\dosbox\HD\SPACE2\V5\CREATE\modules\
if errorlevel 1 goto :error

echo Files copied successfully!
goto :end

:error
echo An error occurred during file copying!
pause
exit /b 1

:end
REM pause