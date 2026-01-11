echo Disable password requirement on wake (console lock)
powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_NONE CONSOLELOCK 0 >nul 2>&1
powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_NONE CONSOLELOCK 0 >nul 2>&1
powercfg /SETACTIVE SCHEME_CURRENT >nul 2>&1
