@echo off

set arch=
set vcvars=

:next-arg
if "%1"=="" goto args-done
if /i "%1"=="x86"           set arch=x86&set vcvars=vcvars32.bat&goto arg-ok
if /i "%1"=="x64"           set arch=x64&set vcvars=vcvars64.bat&goto arg-ok

:arg-ok
shift
goto next-arg

:args-done
if "%arch%" == "" set arch=x64& set vcvars=vcvars64.bat

if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Auxiliary\Build\%vcvars%" (
  call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Auxiliary\Build\%vcvars%"
) else (
  call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\%vcvars%"
)

set Path=%Path%;C:\msys64\usr\bin

set tag=4.3
set name=make-%tag%
set zipname=%name%.zip

echo tag: %tag%

if not exist %zipname% powershell.exe -nologo -noprofile -command "& { (new-object System.Net.WebClient).DownloadFile('https://github.com/mirror/make/archive/refs/tags/%tag%.zip', '%zipname%'); exit !$?; }"
if exist %name% rd /s /q %name%
powershell.exe -nologo -noprofile -command "& { param([String]$sourceArchiveFileName, [String]$destinationDirectoryName); Add-Type -A 'System.IO.Compression.FileSystem'; Add-Type -A 'System.Text.Encoding'; [IO.Compression.ZipFile]::ExtractToDirectory($sourceArchiveFileName, $destinationDirectoryName, [System.Text.Encoding]::UTF8); exit !$?; }" -sourceArchiveFileName "%zipname%" -destinationDirectoryName "."

cd "%name%"

call bootstrap.bat
call build_w32.bat
cd ..
if not exist .\dist mkdir .\dist
copy /Y "%name%\WinRel\gnumake.exe" "dist\gnumake-msvc-%arch%.exe"
