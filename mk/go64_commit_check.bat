@setlocal
@REM hb_syslog: Released to Public Domain.

@REM Prefer Git for Windows over Cygwin Git to avoid hook/check issues on Windows.
@SET "PATH=C:\Program Files\Git\cmd;%PATH%"
@IF NOT DEFINED HB_RUN_PATH SET "HB_RUN_PATH=F:\harbour_msvc\bin\win\msvc64\hbrun.exe"

@IF NOT EXIST "%HB_RUN_PATH%" (
   @FOR /F "delims=" %%H IN ('where hbrun.exe 2^>NUL') DO (
      @SET "HB_RUN_PATH=%%H"
      @GOTO :FoundHBRUN
   )
)
:FoundHBRUN
@IF NOT EXIST "%HB_RUN_PATH%" (
   @ECHO [hb_syslog] Missing hbrun.exe. Set HB_RUN_PATH or add hbrun.exe to PATH.
   @endlocal & exit /b 1
)

@"%HB_RUN_PATH%" "%~dp0..\bin\commit.hb" --check-only
@IF ERRORLEVEL 1 (
   @ECHO [hb_syslog] Harbour commit check failed.
   @endlocal & exit /b 1
)

@ECHO [hb_syslog] Harbour commit check passed.
@endlocal & exit /b 0
