@setlocal EnableExtensions DisableDelayedExpansion
@ECHO OFF
@REM hb_syslog: Released to Public Domain.

SET "HB_ROOT=%~dp0.."
SET "HB_OUT_DIR=%HB_ROOT%\exe\win\msvc64"
SET "HB_OUT=%HB_OUT_DIR%\hb_syslog.exe"

IF NOT EXIST "%HB_OUT_DIR%" MKDIR "%HB_OUT_DIR%"
IF EXIST "%HB_OUT%" DEL /Q "%HB_OUT%"
IF ERRORLEVEL 1 (
   ECHO [hb_syslog] Could not delete %HB_OUT%.
   endlocal & exit /b 1
)
IF EXIST "%HB_OUT%" (
   ECHO [hb_syslog] Could not delete %HB_OUT%.
   endlocal & exit /b 1
)

IF NOT DEFINED HB_BASE_PATH SET "HB_BASE_PATH=F:\harbour_msvc\bin\win\msvc64\hbmk2.exe"
IF NOT EXIST "%HB_BASE_PATH%" (
   FOR /F "delims=" %%H IN ('where hbmk2.exe 2^>NUL') DO (
      SET "HB_BASE_PATH=%%H"
      GOTO :FoundHBMK2
   )
)
:FoundHBMK2
IF NOT EXIST "%HB_BASE_PATH%" (
   ECHO [hb_syslog] Missing hbmk2.exe. Set HB_BASE_PATH or add hbmk2.exe to PATH.
   endlocal & exit /b 1
)

IF NOT DEFINED HB_VCVARSALL SET "HB_VCVARSALL=%ProgramFiles%\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat"
IF NOT EXIST "%HB_VCVARSALL%" (
   ECHO [hb_syslog] Missing vcvarsall.bat: %HB_VCVARSALL%
   ECHO [hb_syslog] Set HB_VCVARSALL to a Visual Studio amd64 environment script.
   endlocal & exit /b 1
)

call "%HB_VCVARSALL%" amd64
IF ERRORLEVEL 1 (
   ECHO [hb_syslog] vcvarsall.bat failed.
   endlocal & exit /b 1
)

"%HB_BASE_PATH%" "%HB_ROOT%\hbp\hb_syslog.hbp" -comp=msvc64
IF ERRORLEVEL 1 (
   ECHO [hb_syslog] hb_syslog.hbp build failed.
   endlocal & exit /b 1
)
endlocal & exit /b 0
