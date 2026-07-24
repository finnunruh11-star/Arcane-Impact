@echo off
setlocal

set "PROJECT_DIR=%~dp0"
set "GODOT_EXE="

if not exist "%PROJECT_DIR%project.godot" (
    echo Arcane Impact could not find project.godot next to this launcher.
    echo Keep Start_Arcane_Impact.bat in the ARCANE_IMPACT project folder.
    pause
    exit /b 1
)

for %%G in (godot.exe godot4.exe) do (
    if not defined GODOT_EXE (
        for /f "delims=" %%P in ('where %%G 2^>nul') do if not defined GODOT_EXE set "GODOT_EXE=%%P"
    )
)

if not defined GODOT_EXE if exist "%PROJECT_DIR%Godot.exe" set "GODOT_EXE=%PROJECT_DIR%Godot.exe"

if not defined GODOT_EXE (
    for /f "delims=" %%P in ('where /r "%LOCALAPPDATA%\Microsoft\WinGet\Packages" Godot_v*-stable_win64.exe 2^>nul') do if not defined GODOT_EXE set "GODOT_EXE=%%P"
)

if not defined GODOT_EXE (
    for /f "delims=" %%P in ('where /r "%LOCALAPPDATA%\Microsoft\WinGet\Packages" Godot*_console.exe 2^>nul') do if not defined GODOT_EXE set "GODOT_EXE=%%P"
)

if not defined GODOT_EXE (
    echo Godot 4 could not be found.
    echo.
    echo Install it with:
    echo     winget install GodotEngine.GodotEngine
    echo.
    echo Then run this launcher again.
    pause
    exit /b 1
)

if /i "%~1"=="--check" (
    echo Launcher ready.
    echo Godot:  %GODOT_EXE%
    echo Project: %PROJECT_DIR%
    exit /b 0
)

start "Arcane Impact" /D "%PROJECT_DIR%" "%GODOT_EXE%" --path "%PROJECT_DIR%"
exit /b 0
