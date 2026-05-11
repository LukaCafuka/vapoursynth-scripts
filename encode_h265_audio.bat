@echo off
setlocal EnableExtensions

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

REM === USAGE ===
if "%~6"=="" (
    echo Usage:
    echo   render_cut_nvenc_audio.bat script.vpy source.avi output.mkv start_frame end_frame source_fps [copy^|norm^|pcm]
    echo.
    echo Examples:
    echo   render_cut_nvenc_audio.bat script_testing.vpy "G:\recordings\kaseta.avi" output.mkv 38612 81771 25 copy
    echo   render_cut_nvenc_audio.bat script_testing.vpy "G:\recordings\kaseta.avi" output_norm.mkv 38612 81771 25 norm
    echo   render_cut_nvenc_audio.bat script_testing.vpy "G:\recordings\kaseta.avi" output_pcm.mkv 38612 81771 25 pcm
    echo.
    pause
    exit /b 1
)

set "SCRIPT=%~1"
set "SOURCE=%~2"
set "OUT=%~3"
set "START_FRAME=%~4"
set "END_FRAME=%~5"
set "SOURCE_FPS=%~6"
set "AUDIO_MODE=%~7"

if "%AUDIO_MODE%"=="" set "AUDIO_MODE=copy"

REM === CHECKS ===
if not exist "%SCRIPT%" (
    echo ERROR: Script not found:
    echo "%SCRIPT%"
    pause
    exit /b 1
)

if not exist "%SOURCE%" (
    echo ERROR: Source not found:
    echo "%SOURCE%"
    pause
    exit /b 1
)

if not exist "%NVENC%" (
    echo ERROR: NVEncC64.exe not found:
    echo "%NVENC%"
    pause
    exit /b 1
)

REM === CALCULATE AUDIO START + DURATION FROM SOURCE FRAMES ===
for /f "usebackq delims=" %%A in (`python -c "s=%START_FRAME%/%SOURCE_FPS%; print(f'{s:.9f}')"`) do set "START_SEC=%%A"
for /f "usebackq delims=" %%A in (`python -c "d=(%END_FRAME%-%START_FRAME%)/%SOURCE_FPS%; print(f'{d:.9f}')"`) do set "DUR_SEC=%%A"

set "TEMPVIDEO=%TEMP%\vs_nvenc_video_%RANDOM%%RANDOM%.mkv"

echo.
echo Script:
echo "%SCRIPT%"
echo.
echo Source:
echo "%SOURCE%"
echo.
echo Output:
echo "%OUT%"
echo.
echo Start frame: %START_FRAME%
echo End frame:   %END_FRAME%
echo Source FPS:  %SOURCE_FPS%
echo Audio start: %START_SEC% sec
echo Duration:    %DUR_SEC% sec
echo Audio mode:  %AUDIO_MODE%
echo.

REM === PASS SAME SOURCE + CUT TO VAPOURSYNTH ===
set "SOURCE_FILE=%SOURCE%"
set "START_FRAME=%START_FRAME%"
set "END_FRAME=%END_FRAME%"

REM Important: render final output only.
REM DEBUG_OUTPUTS=0 means VapourSynth output 0 is Final.
set "DEBUG_OUTPUTS=0"

echo Rendering video-only final output...
echo.

vspipe -o 5 -c y4m -r %VS_REQUESTS% --progress "%SCRIPT%" - | "%NVENC%" --y4m -i - ^
  -c hevc ^
  --qvbr 20 ^
  --preset performance ^
  --tune hq ^
  --output-csp yuv420 ^
  --output-depth 8 ^
  --lookahead 16 ^
  --aq ^
  -o "%TEMPVIDEO%"

if errorlevel 1 (
    echo.
    echo ERROR: Video render failed.
    if exist "%TEMPVIDEO%" del "%TEMPVIDEO%"
    pause
    exit /b 1
)

echo.
echo Muxing synced audio...
echo.

if /I "%AUDIO_MODE%"=="copy" (
    "%FFMPEG%" -y ^
      -i "%TEMPVIDEO%" ^
      -ss %START_SEC% -t %DUR_SEC% -i "%SOURCE%" ^
      -map 0:v:0 ^
      -map 1:a? ^
      -c:v copy ^
      -c:a copy ^
      -shortest ^
      "%OUT%"
) else if /I "%AUDIO_MODE%"=="norm" (
    "%FFMPEG%" -y ^
      -i "%TEMPVIDEO%" ^
      -i "%SOURCE%" ^
      -map 0:v:0 ^
      -map 1:a:0? ^
      -filter:a "atrim=start=%START_SEC%:duration=%DUR_SEC%,asetpts=PTS-STARTPTS,loudnorm=I=-16:LRA=11:TP=-1.5" ^
      -c:v copy ^
      -c:a aac ^
      -b:a 192k ^
      -shortest ^
      "%OUT%"
) else if /I "%AUDIO_MODE%"=="pcm" (
    "%FFMPEG%" -y ^
      -i "%TEMPVIDEO%" ^
      -i "%SOURCE%" ^
      -map 0:v:0 ^
      -map 1:a:0? ^
      -filter:a "atrim=start=%START_SEC%:duration=%DUR_SEC%,asetpts=PTS-STARTPTS" ^
      -c:v copy ^
      -c:a pcm_s16le ^
      -shortest ^
      "%OUT%"
) else (
    echo ERROR: Unknown AUDIO_MODE "%AUDIO_MODE%".
    echo Use copy, norm, or pcm.
    if exist "%TEMPVIDEO%" del "%TEMPVIDEO%"
    pause
    exit /b 1
)

if errorlevel 1 (
    echo.
    echo ERROR: Audio mux failed.
    if exist "%TEMPVIDEO%" del "%TEMPVIDEO%"
    pause
    exit /b 1
)

del "%TEMPVIDEO%"

echo.
echo Done:
echo "%OUT%"
pause