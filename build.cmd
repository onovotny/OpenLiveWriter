@ECHO OFF

setlocal enableextensions enabledelayedexpansion

SET CACHED_NUGET=%LocalAppData%\NuGet\NuGet.exe
SET SOLUTION_PATH="%~dp0src\managed\writer.sln"


if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" (
	FOR /F "delims=" %%E in ('"%ProgramFiles(x86)%\Microsoft Visual Studio\installer\vswhere.exe" -latest -property installationPath') DO (
		set "MSBUILD_EXE=%%E\MSBuild\15.0\Bin\MSBuild.exe"
		if exist "!MSBUILD_EXE!" goto :nuget
	)
)

FOR %%E in (Enterprise, Professional, Community) DO (
	set "MSBUILD_EXE=%ProgramFiles(x86)%\Microsoft Visual Studio\2017\%%E\MSBuild\15.0\Bin\MSBuild.exe"
	if exist "!MSBUILD_EXE!" goto :nuget
)

REM Couldn't be located in the standard locations, expand search
FOR /F "delims=" %%E IN ('dir /b /ad "%ProgramFiles(x86)%\Microsoft Visual Studio\"') DO (
	set "MSBUILD_EXE=%ProgramFiles(x86)%\Microsoft Visual Studio\%%E\MSBuild\15.0\Bin\MSBuild.exe"
	if exist "!MSBUILD_EXE!" goto :nuget

	FOR /F "delims=" %%F IN ('dir /b /ad "%ProgramFiles(x86)%\Microsoft Visual Studio\%%E"') DO (
		set "MSBUILD_EXE=%ProgramFiles(x86)%\Microsoft Visual Studio\%%E\%%F\MSBuild\15.0\Bin\MSBuild.exe"
		if exist "!MSBUILD_EXE!" goto :nuget
	)
)


echo In order to run this tool you need either Visual Studio 2017 or
echo Microsoft Build Tools 2017 tools installed.
echo.
echo Visit this page to download either:
echo.
echo http://www.visualstudio.com/
echo.
exit /b 1

:nuget

IF EXIST %CACHED_NUGET% goto restore
echo Downloading latest version of NuGet.exe...
IF NOT EXIST "%LocalAppData%\NuGet" md "%LocalAppData%\NuGet"
@powershell -NoProfile -ExecutionPolicy unrestricted -Command "$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe' -OutFile '%CACHED_NUGET%'"

:restore
IF EXIST "%~dp0src\packages" goto build
"%CACHED_NUGET%" restore %SOLUTION_PATH%

:build

IF "%OLW_CONFIG%" == "" (
  echo %%OLW_CONFIG%% not set, will default to 'Debug'
  set OLW_CONFIG=Debug
)

powershell.exe get-date 

"%MSBUILD_EXE%" "%SOLUTION_PATH%" /nologo /maxcpucount /verbosity:minimal /p:Configuration=%OLW_CONFIG% %*
