@echo off

set curargname=
set curargvalue=
set arch=
set vcvars=
set tag=

:next-arg
if "%1"=="" goto args-done
if /i "%1"=="--arch"        set curargname=%1&set curargvalue=%2&goto set-arch
if /i "%1"=="--tag"     set curargname=%1&set curargvalue=%2&goto set-tag

:set-arch
if /i "%curargvalue:~0,2%"=="--" echo Invalid argument of %curargname%: %curargvalue% 1>&2&exit /b 1
set arch=%curargvalue%
echo arch: %curargvalue%
if /i "%arch%"=="x86"           set vcvars=vcvars32.bat&goto arg-ok-2
if /i "%arch%"=="x64"           set vcvars=vcvars64.bat&goto arg-ok-2

:set-tag
if /i "%curargvalue:~0,2%"=="--" echo Invalid argument of %curargname%: %curargvalue% 1>&2&exit /b 1
echo tag: %curargvalue%
set tag=%curargvalue%&goto arg-ok-2

:arg-ok-2
shift
:arg-ok
shift
goto next-arg

:args-done
set curargname=
set curargvalue=
if "%arch%" == "" set arch=x64& set vcvars=vcvars64.bat

if exist "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\%vcvars%" (
  call "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\%vcvars%"
) else (
  call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\%vcvars%"
)
if %errorlevel% neq 0 exit /b %errorlevel%

set Path=%Path%;C:\msys64\usr\bin

set name=make-%tag%
set zipname=%name%.zip

if not exist %zipname% powershell.exe -nologo -noprofile -command "& { (new-object System.Net.WebClient).DownloadFile('https://github.com/mirror/make/archive/refs/tags/%tag%.zip', '%zipname%'); exit !$?; }"
if exist %name% rd /s /q %name%
powershell.exe -nologo -noprofile -command "& { param([String]$sourceArchiveFileName, [String]$destinationDirectoryName); Add-Type -A 'System.IO.Compression.FileSystem'; Add-Type -A 'System.Text.Encoding'; [IO.Compression.ZipFile]::ExtractToDirectory($sourceArchiveFileName, $destinationDirectoryName, [System.Text.Encoding]::UTF8); exit !$?; }" -sourceArchiveFileName "%zipname%" -destinationDirectoryName "."

cd "%name%"

call bootstrap.bat
call build_w32.bat
cd ..
if not exist .\dist mkdir .\dist
copy /Y "%name%\WinRel\gnumake.exe" "dist\gnumake-msvc-%arch%.exe"
