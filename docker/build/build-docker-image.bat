@echo off
setlocal enabledelayedexpansion

set "BUILD_OPTION="
set "IMAGE_REPO=xiaoheifs-backend"
set "VERSION=local"

if "%~1" neq "" set "BUILD_OPTION=%~1"
if "%~1"=="" (
    echo Select build option:
    echo   1^) latest ^(debian^)
    echo   2^) alpine
    echo   0^) all
    set /p CHOICE=Enter choice [1/2/0]: 
    if "%CHOICE%"=="1" (
        set "BUILD_OPTION=latest"
    ) else if "%CHOICE%"=="2" (
        set "BUILD_OPTION=alpine"
    ) else if "%CHOICE%"=="0" (
        set "BUILD_OPTION=all"
    ) else (
        echo Invalid choice: %CHOICE%
        exit /b 1
    )
)
if /I "%BUILD_OPTION%"=="latest" (
    if "%~2" neq "" set "IMAGE_REPO=%~2"
) else if /I "%BUILD_OPTION%"=="alpine" (
    if "%~2" neq "" set "IMAGE_REPO=%~2"
) else if /I "%BUILD_OPTION%"=="all" (
    if "%~2" neq "" set "IMAGE_REPO=%~2"
) else (
    :: backward compatible: first arg as image name
    set "IMAGE_REPO=%~1"
    set "BUILD_OPTION=latest"
)

for /f "tokens=1 delims=:" %%A in ("%IMAGE_REPO%") do set "IMAGE_REPO=%%A"

:: change directory to repo root (two levels up from this script)
pushd "%~dp0\..\.." >nul 2>&1 || (
    echo Failed to navigate to repository root
    exit /b 1
)

for /f "delims=" %%V in ('git describe --tags --dirty --always 2^>nul') do set "VERSION=%%V"
if not defined VERSION set "VERSION=local"

if /I "%BUILD_OPTION%"=="latest" (
    call :build docker\build\Dockerfile latest || goto :failed
) else if /I "%BUILD_OPTION%"=="alpine" (
    call :build docker\build\Dockerfile.alpine alpine || goto :failed
) else if /I "%BUILD_OPTION%"=="all" (
    call :build docker\build\Dockerfile latest || goto :failed
    call :build docker\build\Dockerfile.alpine alpine || goto :failed
) else (
    echo Invalid build option: %BUILD_OPTION%
    popd
    exit /b 1
)

popd
endlocal
exit /b 0

:build
set "DOCKERFILE=%~1"
set "TAG=%~2"
set "IMAGE_NAME=%IMAGE_REPO%:%TAG%"
docker build -f "%DOCKERFILE%" --build-arg VERSION="%VERSION%" -t "%IMAGE_NAME%" .
if errorlevel 1 exit /b 1
echo Image built: %IMAGE_NAME% (version %VERSION%)
exit /b 0

:failed
echo Docker build failed
if not "%CD%"=="" (
    popd
)
endlocal
exit /b 1
