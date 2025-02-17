@echo off
setlocal

set "WD=%__CD__%"
if NOT EXIST "%WD%msys-2.0.dll" set "WD=%~dp0usr\bin\"
set "LOGINSHELL=bash"

rem To activate windows native symlinks uncomment next line
rem set MSYS=winsymlinks:nativestrict

rem Set debugging program for errors
rem set MSYS=error_start:%WD%../../mingw64/bin/qtcreator.exe^|-debug^|^<process-id^>

rem To export full current PATH from environment into MSYS2 use '-use-full-path' parameter
rem or uncomment next line
rem set MSYS2_PATH_TYPE=inherit


SET PATH=%WD%;%PATH%
rem /tmp is required for bash to work
mkdir %WD%..\..\tmp 2> nul
del %WD%..\..\etc\passwd 2> nul
del %WD%..\..\etc\group 2> nul
%WD%touch /etc/passwd
%WD%touch /etc/group
%WD%bash /user_setup.sh

:checkparams
rem Help option
if "x%~1" == "x-help" (
  call :printhelp "%~nx0"
  exit /b %ERRORLEVEL%
)
if "x%~1" == "x--help" (
  call :printhelp "%~nx0"
  exit /b %ERRORLEVEL%
)
if "x%~1" == "x-?" (
  call :printhelp "%~nx0"
  exit /b %ERRORLEVEL%
)
if "x%~1" == "x/?" (
  call :printhelp "%~nx0"
  exit /b %ERRORLEVEL%
)
rem Shell types
if "x%~1" == "x-msys" shift& set MSYSTEM=MSYS& goto :checkparams
if "x%~1" == "x-msys2" shift& set MSYSTEM=MSYS& goto :checkparams
if "x%~1" == "x-mingw32" shift& set MSYSTEM=MINGW32& goto :checkparams
if "x%~1" == "x-mingw64" shift& set MSYSTEM=MINGW64& goto :checkparams
if "x%~1" == "x-mingw" shift& (if exist "%WD%..\..\mingw64" (set MSYSTEM=MINGW64) else (set MSYSTEM=MINGW32))& goto :checkparams
rem Console types
if "x%~1" == "x-mintty" shift& set MSYSCON=mintty.exe& goto :checkparams
if "x%~1" == "x-conemu" shift& set MSYSCON=conemu& goto :checkparams
if "x%~1" == "x-defterm" shift& set MSYSCON=defterm& goto :checkparams
rem Other parameters
if "x%~1" == "x-full-path" shift& set MSYS2_PATH_TYPE=inherit& goto :checkparams
if "x%~1" == "x-use-full-path" shift& set MSYS2_PATH_TYPE=inherit& goto :checkparams
if "x%~1" == "x-here" shift& set CHERE_INVOKING=enabled_from_arguments& goto :checkparams
if "x%~1" == "x-where" (
  if "x%~2" == "x" (
    echo Working directory is not specified for -where parameter. 1>&2
    exit /b 2
  )
  cd /d "%~2" || (
    echo Cannot set specified working diretory "%~2". 1>&2
    exit /b 2
  )
  set CHERE_INVOKING=enabled_from_arguments
)& shift& shift& goto :checkparams
if "x%~1" == "x-no-start" shift& set MSYS2_NOSTART=yes& goto :checkparams
if "x%~1" == "x-shell" (
  if "x%~2" == "x" (
    echo Shell not specified for -shell parameter. 1>&2
    exit /b 2
  )
  set LOGINSHELL="%~2"
)& shift& shift& goto :checkparams

rem Setup proper title
if "%MSYSTEM%" == "MINGW32" (
  set "CONTITLE=MinGW x32"
) else if "%MSYSTEM%" == "MINGW64" (
  set "CONTITLE=MinGW x64"
) else (
  set "CONTITLE=MSYS2 MSYS"
)

if "x%MSYSCON%" == "xmintty.exe" goto startmintty
if "x%MSYSCON%" == "xconemu" goto startconemu
if "x%MSYSCON%" == "xdefterm" goto startsh

if NOT EXIST "%WD%mintty.exe" goto startsh
set MSYSCON=mintty.exe
:startmintty
if not defined MSYS2_NOSTART (
  start "%CONTITLE%" "%WD%mintty" -i /msys2.ico -t "%CONTITLE%" "/usr/bin/%LOGINSHELL%" --login %1 %2 %3 %4 %5 %6 %7 %8 %9
) else (
  "%WD%mintty" -i /msys2.ico -t "%CONTITLE%" "/usr/bin/%LOGINSHELL%" --login %1 %2 %3 %4 %5 %6 %7 %8 %9
)
exit /b %ERRORLEVEL%

:startconemu
call :conemudetect || (
  echo ConEmu not found. Exiting. 1>&2
  exit /b 1
)
if not defined MSYS2_NOSTART (
  start "%CONTITLE%" "%ComEmuCommand%" /Here /Icon "%WD%..\..\msys2.ico" /cmd "%WD%\%LOGINSHELL%" --login %1 %2 %3 %4 %5 %6 %7 %8 %9
) else (
  "%ComEmuCommand%" /Here /Icon "%WD%..\..\msys2.ico" /cmd "%WD%\%LOGINSHELL%" --login %1 %2 %3 %4 %5 %6 %7 %8 %9
)
exit /b %ERRORLEVEL%

:startsh
set MSYSCON=
if not defined MSYS2_NOSTART (
  start "%CONTITLE%" "%WD%\%LOGINSHELL%" --login %1 %2 %3 %4 %5 %6 %7 %8 %9
) else (
  "%WD%\%LOGINSHELL%" --login %1 %2 %3 %4 %5 %6 %7 %8 %9
)
exit /b %ERRORLEVEL%

:EOF
exit /b 0

:conemudetect
set ComEmuCommand=
if defined ConEmuDir (
  if exist "%ConEmuDir%\ConEmu64.exe" (
    set "ComEmuCommand=%ConEmuDir%\ConEmu64.exe"
    set MSYSCON=conemu64.exe
  ) else if exist "%ConEmuDir%\ConEmu.exe" (
    set "ComEmuCommand=%ConEmuDir%\ConEmu.exe"
    set MSYSCON=conemu.exe
  )
)
if not defined ComEmuCommand (
  ConEmu64.exe /Exit 2>nul && (
    set ComEmuCommand=ConEmu64.exe
    set MSYSCON=conemu64.exe
  ) || (
    ConEmu.exe /Exit 2>nul && (
      set ComEmuCommand=ConEmu.exe
      set MSYSCON=conemu.exe
    )
  )
)
if not defined ComEmuCommand (
  FOR /F "tokens=*" %%A IN ('reg.exe QUERY "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\ConEmu64.exe" /ve 2^>nul ^| find "REG_SZ"') DO (
    set "ComEmuCommand=%%A"
  )
  if defined ComEmuCommand (
    call set "ComEmuCommand=%%ComEmuCommand:*REG_SZ    =%%"
    set MSYSCON=conemu64.exe
  ) else (
    FOR /F "tokens=*" %%A IN ('reg.exe QUERY "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\ConEmu.exe" /ve 2^>nul ^| find "REG_SZ"') DO (
      set "ComEmuCommand=%%A"
    )
    if defined ComEmuCommand (
      call set "ComEmuCommand=%%ComEmuCommand:*REG_SZ    =%%"
      set MSYSCON=conemu.exe
    )
  )
)
if not defined ComEmuCommand exit /b 2
exit /b 0

:printhelp
echo Usage:
echo     %~1 [options] [login shell parameters]
echo.
echo Options:
echo     -mingw32 ^| -mingw64 ^| -msys[2]   Set shell type
echo     -defterm ^| -mintty ^| -conemu     Set terminal type
echo     -here                            Use current directory as working
echo                                      directory
echo     -where DIRECTORY                 Use specified DIRECTORY as working
echo                                      directory
echo     -[use-]full-path                 Use full current PATH variable
echo                                      instead of trimming to minimal
echo     -no-start                        Do not use "start" command and
echo                                      return login shell resulting 
echo                                      errorcode as this batch file 
echo                                      resulting errorcode
echo     -shell SHELL                     Set login shell
echo     -help ^| --help ^| -? ^| /?         Display this help and exit
echo.
echo Any parameter that cannot be treated as valid option and all
echo following parameters are passed as login shell command parameters.
echo.
exit /b 0
