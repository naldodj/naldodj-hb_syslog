@setlocal EnableExtensions DisableDelayedExpansion
@ECHO OFF
@REM hb_syslog: Released to Public Domain.

@IF "%~4"=="" (
   @ECHO [hb_syslog/Zig] Usage: go64_zig_build.bat MK_DIR HBP_FILE OUTPUT_FILE LABEL
   @endlocal & exit /b 2
)

@IF /I NOT "%HBSYSLOG_ZIG_ENABLE%"=="1" (
   @ECHO [hb_syslog/Zig] Experimental Zig build skipped. Set HBSYSLOG_ZIG_ENABLE=1 to run it.
   @endlocal & exit /b 0
)

@where zig.exe >NUL 2>NUL
@IF ERRORLEVEL 1 (
   @ECHO [hb_syslog/Zig] zig.exe was not found in PATH.
   @ECHO [hb_syslog/Zig] Confirm with: zig version
   @endlocal & exit /b 1
)

@IF NOT DEFINED HB_ZIG_ROOT SET "HB_ZIG_ROOT=C:\GitHub\naldodj-harbour-core"
@IF NOT DEFINED HB_ZIG_TARGET SET "HB_ZIG_TARGET=x86_64-windows-gnu"
@IF NOT DEFINED HB_ZIG_LIBDIR SET "HB_ZIG_LIBDIR=%HB_ZIG_ROOT%\lib\win\mingw64"

@SET "HB_ZIG_HBRUN=%HB_ZIG_ROOT%\bin\win\mingw64\hbrun.exe"
@SET "HB_ZIG_HBMK2_PRG=%HB_ZIG_ROOT%\utils\hbmk2\hbmk2.prg"

@IF NOT EXIST "%HB_ZIG_HBRUN%" (
   @ECHO [hb_syslog/Zig] Missing hbrun.exe: %HB_ZIG_HBRUN%
   @ECHO [hb_syslog/Zig] Set HB_ZIG_ROOT to a Harbour checkout with bin\win\mingw64\hbrun.exe.
   @endlocal & exit /b 1
)

@IF NOT EXIST "%HB_ZIG_HBMK2_PRG%" (
   @ECHO [hb_syslog/Zig] Missing hbmk2.prg: %HB_ZIG_HBMK2_PRG%
   @ECHO [hb_syslog/Zig] Set HB_ZIG_ROOT to a Harbour checkout whose hbmk2.prg supports -comp=zig.
   @endlocal & exit /b 1
)

@IF NOT EXIST "%HB_ZIG_LIBDIR%" (
   @ECHO [hb_syslog/Zig] Missing Zig-compatible Harbour lib directory: %HB_ZIG_LIBDIR%
   @ECHO [hb_syslog/Zig] Set HB_ZIG_LIBDIR to a Harbour lib\win\mingw64-style directory.
   @endlocal & exit /b 1
)

@pushd "%~1" || (
   @ECHO [hb_syslog/Zig] Could not enter mk directory.
   @endlocal & exit /b 1
)

@IF EXIST "%~3" DEL /Q "%~3"
@IF ERRORLEVEL 1 (
   @ECHO [hb_syslog/Zig] Could not delete %~3.
   @popd
   @endlocal & exit /b 1
)
@IF EXIST "%~3" (
   @ECHO [hb_syslog/Zig] Could not delete %~3.
   @popd
   @endlocal & exit /b 1
)

@FOR /F "delims=" %%V IN ('zig version') DO @SET "ZIG_VERSION=%%V"
@ECHO [hb_syslog/Zig] Zig version: %ZIG_VERSION%
@ECHO [hb_syslog/Zig] HB_ZIG_ROOT: %HB_ZIG_ROOT%
@ECHO [hb_syslog/Zig] HB_ZIG_TARGET: %HB_ZIG_TARGET%
@ECHO [hb_syslog/Zig] HB_ZIG_LIBDIR: %HB_ZIG_LIBDIR%
@ECHO [hb_syslog/Zig] Building %~4 from %~2

@SET "HB_INSTALL_LIB=%HB_ZIG_LIBDIR%"
@"%HB_ZIG_HBRUN%" "%HB_ZIG_HBMK2_PRG%" "%~2" -comp=zig
@IF ERRORLEVEL 1 (
   @ECHO [hb_syslog/Zig] Experimental Zig build failed for %~4.
   @popd
   @endlocal & exit /b 1
)

@IF NOT EXIST "%~3" (
   @ECHO [hb_syslog/Zig] Build finished but expected output is missing: %~3
   @popd
   @endlocal & exit /b 1
)

@ECHO [hb_syslog/Zig] Experimental Zig build completed for %~4.
@popd
@endlocal & exit /b 0
