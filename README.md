# naldodj-hb_syslog
A simple Syslog server implemented in Harbour for capturing and processing HAProxy logs. The server uses UDP sockets, supports multithreading, and includes log rotation for efficient log management.

## Build

The repository follows the same build layout used by `C:\GitHub\hbnum`:

- `hbp\hb_syslog.hbp`: hbmk2 project file for the executable target.
- `hbm\hb_syslog.hbm`: common build flags.
- `hbc\hb_syslog.hbc`: package/default dependency flags.
- `env\hb_syslog_env.ps1` and `env\hb_syslog_env.bat`: local environment presets.
- `mk\go64_build.bat`: MSVC64 build.
- `mk\go64_gate.bat`: MSVC64 build plus a `--help` smoke test and commit check.
- `mk\go64_zig_build.bat`: optional experimental Zig build.

Build with MSVC64:

```bat
env\hb_syslog_env.bat local
mk\go64_build.bat
```

Run the validation gate:

```bat
env\hb_syslog_env.bat gate
mk\go64_gate.bat
```

The default output is:

```text
exe\win\msvc64\hb_syslog.exe
```

Optional Zig build:

```bat
env\hb_syslog_env.bat local
mk\go64_zig_build.bat
```

The Zig output is:

```text
exe\win\zig\hb_syslog.exe
```
