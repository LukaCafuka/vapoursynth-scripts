@echo off
setlocal

REM === LOAD LOCAL CONFIG IF PRESENT ===
if exist "%~dp0config.local.bat" (
    call "%~dp0config.local.bat"
)

REM === FALLBACK / CHECKS ===
if "%NVENC%"=="" (
    echo ERROR: NVENC path is not configured.
    echo Create config.local.bat next to this script and add:
    echo set "NVENC=C:\Path\To\NVEncC64.exe"
    pause
    exit /b 1
)

if "%FFMPEG%"=="" set "FFMPEG=ffmpeg"
if "%VS_REQUESTS%"=="" set "VS_REQUESTS=8"

REM === CHECK INPUT SCRIPT ===
if "%~1"=="" (
    echo Usage:
    echo   render_nvenc.bat script.vpy output.mkv
    echo.
    echo Example:
    echo   render_nvenc.bat script_testing.vpy output_qtgmc.mkv
    echo.
    pause
    exit /b 1
)

set "SCRIPT=%~1"

REM === OUTPUT FILE ===
REM If second argument is given, use it.
REM Otherwise, auto-create output name from script name.
if "%~2"=="" (
    set "OUT=%~dpn1_hevc_8bit_420.mkv"
) else (
    set "OUT=%~2"
)

REM === CHECK NVENC PATH ===
if not exist "%NVENC%" (
    echo ERROR: NVEncC64.exe not found:
    echo "%NVENC%"
    echo.
    echo Edit this .bat file and correct the NVENC path.
    pause
    exit /b 1
)

REM === RENDER ===
echo Rendering script:
echo "%SCRIPT%"
echo.
echo Output file:
echo "%OUT%"
echo.

vspipe -c y4m "%SCRIPT%" - | "%NVENC%" --y4m -i - ^
  -c hevc ^
  --qvbr 20 ^
  --preset quality ^
  --tune hq ^
  --output-csp yuv420 ^
  --output-depth 8 ^
  --lookahead 32 ^
  --aq ^
  --aq-temporal ^
  -o "%OUT%"

echo.
echo Done.
pause