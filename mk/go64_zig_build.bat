@setlocal EnableExtensions DisableDelayedExpansion
@ECHO OFF
@REM hb_syslog: Released to Public Domain.

@IF NOT DEFINED HBSYSLOG_ZIG_ENABLE SET "HBSYSLOG_ZIG_ENABLE=1"
@SET "HB_ROOT=%~dp0.."
@SET "HB_OUT_DIR=%HB_ROOT%\exe\win\zig"
@IF NOT EXIST "%HB_OUT_DIR%" MKDIR "%HB_OUT_DIR%"

@call "%~dp0tools\go64_zig_build.bat" "%~dp0" "%HB_ROOT%\hbp\hb_syslog.hbp" "%HB_OUT_DIR%\hb_syslog.exe" "hb_syslog.exe"
@endlocal & exit /b %ERRORLEVEL%
