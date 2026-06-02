@setlocal EnableExtensions DisableDelayedExpansion
@ECHO OFF
@REM hb_syslog: Released to Public Domain.

SET "HB_ROOT=%~dp0.."
SET "HB_OUT_DIR=%HB_ROOT%\exe\win\msvc64"
SET "HB_OUT=%HB_OUT_DIR%\hb_syslog.exe"

ECHO [hb_syslog] Validation gate started.

CALL "%~dp0go64_build.bat"
IF ERRORLEVEL 1 (
   ECHO [hb_syslog] Executable build failed.
   endlocal & exit /b 1
)

IF NOT EXIST "%HB_OUT%" (
   ECHO [hb_syslog] Missing executable: %HB_OUT%
   endlocal & exit /b 1
)

ECHO.
ECHO [hb_syslog] Running help smoke test.
"%HB_OUT%" --help
IF ERRORLEVEL 1 (
   ECHO [hb_syslog] Help smoke test failed.
   endlocal & exit /b 1
)

CALL "%~dp0go64_commit_check.bat"
IF ERRORLEVEL 1 (
   ECHO [hb_syslog] Commit check failed.
   endlocal & exit /b 1
)

ECHO.
ECHO [hb_syslog] VALIDATION: PASS
endlocal & exit /b 0
