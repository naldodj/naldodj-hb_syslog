@setlocal EnableExtensions DisableDelayedExpansion
@ECHO OFF
@REM hb_syslog: Released to Public Domain.

@pushd "%~dp0" || (
   @ECHO [hb_syslog] Could not enter mk directory.
   @endlocal & exit /b 1
)

@FOR /F "delims=" %%F IN ('dir /b /a:-d /on "*.bat"') DO (
   @IF /I NOT "%%~nxF"=="%~nx0" (
      @IF /I "%%~nF"=="go64_gate" (
         @ECHO.
         @ECHO [hb_syslog] Skipping %%~nxF because the validation gate runs build and smoke checks itself.
      ) ELSE @IF /I "%%~nF"=="go64_zig_build" (
         @IF /I NOT "%HBSYSLOG_ZIG_ENABLE%"=="1" (
            @ECHO.
            @ECHO [hb_syslog] Skipping %%~nxF because HBSYSLOG_ZIG_ENABLE is not 1.
         ) ELSE (
            @ECHO.
            @ECHO [hb_syslog] Running %%~nxF
            @cmd /d /q /c "%%~fF"
            @IF ERRORLEVEL 1 (
               @ECHO.
               @ECHO [hb_syslog] %%~nxF failed.
               @popd
               @endlocal & exit /b 1
            )
         )
      ) ELSE (
         @ECHO.
         @ECHO [hb_syslog] Running %%~nxF
         @cmd /d /q /c "%%~fF"
         @IF ERRORLEVEL 1 (
            @ECHO.
            @ECHO [hb_syslog] %%~nxF failed.
            @popd
            @endlocal & exit /b 1
         )
      )
   )
)
@ECHO.
@ECHO [hb_syslog] All batch scripts completed.
@popd
@endlocal & exit /b 0
