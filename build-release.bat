@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM Set NO_PAUSE=1 to skip the "press any key" prompts (useful for automation).
if not defined NO_PAUSE set "NO_PAUSE=0"

REM ============================================================
REM  CKEditor 4 Release Builder (lean build)
REM  Double-click this .bat to build a release zip package.
REM
REM  Version: read dynamically from package.json (raw "version" field,
REM    e.g. 4.22.1-1). Zip is named release\ckeditor-<version>.zip.
REM
REM  Excluded plugins: about, elementspath, preview, print, save,
REM    pastefromword, pastetext, iframe, codesnippetgeshi, iframedialog,
REM    pastefromgdocs, embedbase, embed, embedsemantic
REM    (print depends on preview, so both removed; embed/embedsemantic
REM     depend on embedbase, so all three removed).
REM  Hidden buttons: Maximize, NewPage, Paste (plugins kept, buttons hidden
REM    via removeButtons injected into release config.js).
REM
REM  Output:
REM    release\ckeditor\                       (expanded build folder)
REM    release\ckeditor-<version>.zip          (ready-to-deploy package)
REM
REM  Requirements: JDK (any version) + git on PATH.
REM  ckbuilder.jar is auto-downloaded on first run.
REM ============================================================

cd /d "%~dp0"

REM Read version from package.json (raw value, e.g. 4.22.1-1).
REM Uses node if available, else falls back to PowerShell.
where node >nul 2>&1
if not errorlevel 1 (
    for /f "delims=" %%V in ('node -p "require('./package.json').version"') do set "CKEDITOR_VERSION=%%V"
) else (
    for /f "delims=" %%V in ('powershell -NoProfile -Command "(Get-Content package.json | ConvertFrom-Json).version"') do set "CKEDITOR_VERSION=%%V"
)
if not defined CKEDITOR_VERSION (
    echo [ERROR] Could not read version from package.json.
    if not "%NO_PAUSE%"=="1" pause
    exit /b 1
)

echo.
echo ============================================================
echo   CKEditor %CKEDITOR_VERSION% Release Builder
echo ============================================================
echo.

REM --- 1. Check Java ---
echo [1/6] Checking Java...
java -version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Java not found. Install JDK and add it to PATH.
    echo         Recommended: JDK 15 or lower. JDK 17+ works with module exports.
    if not "%NO_PAUSE%"=="1" pause
    exit /b 1
)
java -version 2>&1 | findstr /i "version" >nul
echo OK
echo.

REM --- 2. Check / download CKBuilder ---
echo [2/6] Checking CKBuilder...
set "CKBUILDER_JAR=dev\builder\ckbuilder\2.4.3\ckbuilder.jar"
if not exist "%CKBUILDER_JAR%" (
    echo Downloading ckbuilder.jar 2.4.3...
    if not exist "dev\builder\ckbuilder\2.4.3" mkdir "dev\builder\ckbuilder\2.4.3"
    powershell -NoProfile -Command "try { Invoke-WebRequest -Uri 'https://download.cksource.com/CKBuilder/2.4.3/ckbuilder.jar' -OutFile '%CKBUILDER_JAR%' -UseBasicParsing } catch { exit 1 }"
    if errorlevel 1 (
        echo [ERROR] Failed to download ckbuilder.jar.
        echo         Check network or manually download from:
        echo         https://download.cksource.com/CKBuilder/2.4.3/ckbuilder.jar
        if not "%NO_PAUSE%"=="1" pause
        exit /b 1
    )
    echo Downloaded.
) else (
    echo OK ^(already exists^)
)
echo.

REM --- 3. Get git revision ---
echo [3/6] Getting git revision...
set "REVISION=unknown"
for /f "delims=" %%v in ('git rev-parse --verify --short HEAD 2^>nul') do set "REVISION=%%v"
echo Revision: %REVISION%
echo.

REM --- 4. Check build config ---
echo [4/6] Checking build config...
if not exist "dev\builder\build-config-release.js" (
    echo [ERROR] dev\builder\build-config-release.js not found.
    if not "%NO_PAUSE%"=="1" pause
    exit /b 1
)
echo OK
echo.

REM --- 5. Clean old release and build ---
echo [5/6] Building with CKBuilder...
echo Cleaning old release...
if exist "release" rmdir /s /q "release"

echo Starting CKBuilder ^(this takes a few minutes, please wait^)...
echo.

REM JDK module exports needed for JDK 9+ (CKBuilder accesses sun.java2d).
REM Harmless on JDK 8 which ignores unknown --add-exports? Actually JDK 8
REM does not recognize these flags and will ERROR. Detect JDK major version.
set "JAVA_OPTS="
for /f "tokens=3" %%a in ('java -version 2^>^&1 ^| findstr /i "version"') do set "JVLINE=%%a"
set "JVLINE=%JVLINE:"=%"
REM JVLINE like 21.0.8 or 1.8.0_422
for /f "tokens=1 delims=." %%m in ("%JVLINE%") do set "JVMAJOR=%%m"
if "%JVMAJOR%"=="1" (
    REM Java 8 reports 1.8.x
    set "JAVA_OPTS="
) else if %JVMAJOR% geq 9 (
    set "JAVA_OPTS=--add-exports java.desktop/sun.java2d=ALL-UNNAMED --add-exports java.desktop/sun.awt=ALL-UNNAMED --add-exports java.desktop/sun.awt.image=ALL-UNNAMED --add-opens java.desktop/sun.java2d=ALL-UNNAMED --add-opens java.desktop/sun.awt=ALL-UNNAMED --add-opens java.desktop/sun.awt.image=ALL-UNNAMED"
) else (
    set "JAVA_OPTS="
)
echo Detected Java major: %JVMAJOR%
if defined JAVA_OPTS (echo Using module exports.) else (echo No module exports needed.)
echo.

java %JAVA_OPTS% -jar "%CKBUILDER_JAR%" --build . release --build-config "dev\builder\build-config-release.js" --version="4.22.1" --revision="%REVISION%" --overwrite --no-zip --no-tar
if errorlevel 1 (
    echo.
    echo [ERROR] CKBuilder build failed. See messages above.
    if not "%NO_PAUSE%"=="1" pause
    exit /b 1
)
echo.

REM --- 5b. Post-build cleanup: remove excluded plugin folders ---
REM These plugins are not in the build-config plugins list (so not merged into
REM ckeditor.js), but CKBuilder still copies their folders. Remove them here.
echo [5b/6] Cleaning up excluded plugin folders...
for %%P in (about codesnippetgeshi elementspath exportpdf preview print save pastefromgdocs pastefromword pastetext iframe iframedialog embedbase embed embedsemantic) do (
    if exist "release\ckeditor\plugins\%%P" (
        rmdir /s /q "release\ckeditor\plugins\%%P"
        echo   - removed plugins\%%P
    )
)
echo Done.
echo.

REM --- 5c. Inject hardening options into release config.js ---
REM   - config.removeButtons = 'Maximize,NewPage,Paste'  (hide UI buttons)
REM   - config.versionCheck = false  (disable cke4.ckeditor.com requests,
REM     closing the domain-takeover XSS vector)
echo [5c/6] Injecting hardening options into config.js...
powershell -NoProfile -ExecutionPolicy Bypass -File "dev\builder\inject-removebuttons.ps1"
echo Done.
echo.

REM --- 6. Create zip ---
echo [6/6] Creating zip package...
set "ZIP_NAME=ckeditor-%CKEDITOR_VERSION%.zip"
if exist "release\%ZIP_NAME%" del "release\%ZIP_NAME%"
powershell -NoProfile -Command "Compress-Archive -Path 'release\ckeditor\*' -DestinationPath 'release\%ZIP_NAME%' -CompressionLevel Optimal"
if errorlevel 1 (
    echo [ERROR] Failed to create zip.
    if not "%NO_PAUSE%"=="1" pause
    exit /b 1
)

echo.
echo ============================================================
echo   Build complete!
echo ============================================================
echo.
echo   Package : release\%ZIP_NAME%
echo   Folder  : release\ckeditor\
echo.
for %%F in ("release\%ZIP_NAME%") do echo   Size    : %%~zF bytes
echo.
if not "%NO_PAUSE%"=="1" pause
