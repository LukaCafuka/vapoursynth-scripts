@echo off
setlocal EnableExtensions

REM ============================================================
REM FFV1 VapourSynth Render Script
REM Usage:
REM   render_ffv1.bat script.vpy output.mkv [output_index] [requests]
REM
REM Examples:
REM   render_ffv1.bat tvz1987script.vpy I:\tvz-rendered.mkv
REM   render_ffv1.bat tvz1987script.vpy I:\tvz-rendered.mkv 3
REM   render_ffv1.bat tvz1987script.vpy I:\tvz-rendered.mkv 3 4
REM ============================================================

REM === CONFIG ===
set "FFMPEG=ffmpeg"

REM === INPUTS ===
set "SCRIPT=%~1"
set "OUT=%~2"
set "OUTPUT_INDEX=%~3"
set "VS_REQUESTS=%~4"

REM === DEFAULTS ===
if "%OUTPUT_INDEX%"=="" set "OUTPUT_INDEX=0"
if "%VS_REQUESTS%"=="" set "VS_REQUESTS=4"

REM === CHECKS ===
if "%SCRIPT%"=="" (
    echo ERROR: Missing VapourSynth script.
    echo.
    echo Usage:
    echo   render_ffv1.bat script.vpy output.mkv [output_index] [requests]
    echo.
    pause
    exit /b 1
)

if "%OUT%"=="" (
    echo ERROR: Missing output file.
    echo.
    echo Usage:
    echo   render_ffv1.bat script.vpy output.mkv [output_index] [requests]
    echo.
    pause
    exit /b 1
)

if not exist "%SCRIPT%" (
    echo ERROR: Script not found:
    echo "%SCRIPT%"
    pause
    exit /b 1
)

echo.
echo Rendering FFV1 lossless video
echo.
echo Script:       "%SCRIPT%"
echo Output:       "%OUT%"
echo VS output:    %OUTPUT_INDEX%
echo VS requests:  %VS_REQUESTS%
echo.
echo Starting render...
echo.

REM === RENDER ===
vspipe -o %OUTPUT_INDEX% -c y4m -r %VS_REQUESTS% --progress "%SCRIPT%" - | "%FFMPEG%" -y -i - ^
  -an ^
  -c:v ffv1 ^
  -level 3 ^
  -g 1 ^
  -slicecrc 1 ^
  "%OUT%"

if errorlevel 1 (
    echo.
    echo ERROR: Render failed.
    pause
    exit /b 1
)

echo.
echo Done:
echo "%OUT%"
pause