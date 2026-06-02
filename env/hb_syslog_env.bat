@ECHO OFF
REM hb_syslog: Released to Public Domain.
REM
REM Usage:
REM   env\hb_syslog_env.bat local
REM   env\hb_syslog_env.bat gate -DisableZig
REM
REM Run this script directly in an interactive cmd.exe session, or use CALL
REM from another batch file so the environment remains available afterward.

SET "HB_ENV_PS=%~dp0hb_syslog_env.ps1"
SET "HB_ENV_TMP=%TEMP%\hb_syslog_env_%RANDOM%_%RANDOM%.cmd"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%HB_ENV_PS%" -EmitCmd %* > "%HB_ENV_TMP%"
IF ERRORLEVEL 1 (
   IF EXIST "%HB_ENV_TMP%" DEL /Q "%HB_ENV_TMP%" >NUL 2>NUL
   SET "HB_ENV_PS="
   SET "HB_ENV_TMP="
   EXIT /B 1
)

CALL "%HB_ENV_TMP%"
SET "HB_ENV_STATUS=%ERRORLEVEL%"

IF EXIST "%HB_ENV_TMP%" DEL /Q "%HB_ENV_TMP%" >NUL 2>NUL
SET "HB_ENV_PS="
SET "HB_ENV_TMP="

IF "%HB_ENV_STATUS%"=="0" (
   SET "HB_ENV_STATUS="
   EXIT /B 0
)

EXIT /B %HB_ENV_STATUS%
