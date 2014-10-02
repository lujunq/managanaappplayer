@echo off

if "%PLATFORM%"=="android" goto android-config
if "%PLATFORM%"=="ios" goto ios-config
if "%PLATFORM%"=="ios-dist" goto ios-dist-config
if "%PLATFORM%"=="windows" goto windows-config
if "%PLATFORM%"=="air" goto air-config
goto start

:windows-config
set CERT_FILE=%DESK_CERT_FILE%
set SIGNING_OPTIONS=%DESK_SIGNING_OPTIONS%
set ICONS=%DESK_ICONS%
set DIST_EXT=exe
set TYPE=
set DESCRIPTOR=%DESK_XML%
goto start-windows

:air-config
set CERT_FILE=%DESK_CERT_FILE%
set SIGNING_OPTIONS=%DESK_SIGNING_OPTIONS%
set ICONS=%DESK_ICONS%
set DIST_EXT=air
set TYPE=
set DESCRIPTOR=%DESK_XML%
goto start-air

:android-config
set CERT_FILE=%AND_CERT_FILE%
set SIGNING_OPTIONS=%AND_SIGNING_OPTIONS%
set ICONS=%AND_ICONS%
set DIST_EXT=apk
set TYPE=apk
set DESCRIPTOR=%APP_XML%
goto start

:ios-config
set CERT_FILE=%IOS_DEV_CERT_FILE%
set SIGNING_OPTIONS=%IOS_DEV_SIGNING_OPTIONS%
set ICONS=%IOS_ICONS%
set DIST_EXT=ipa
set TYPE=ipa
set DESCRIPTOR=%APP_XML%
goto start

:ios-dist-config
set CERT_FILE=%IOS_DIST_CERT_FILE%
set SIGNING_OPTIONS=%IOS_DIST_SIGNING_OPTIONS%
set ICONS=%IOS_ICONS%
set DIST_EXT=ipa
set TYPE=ipa
set DESCRIPTOR=%APP_XML%
goto start


:start
if not exist "%CERT_FILE%" goto certificate
:: Output file
set FILE_OR_DIR=%FILE_OR_DIR% -C "%ICONS%" .
if not exist "%DIST_PATH%" md "%DIST_PATH%"
set OUTPUT=%DIST_PATH%\%DIST_NAME%%TARGET%%NAMEADD%.%DIST_EXT%
:: Package
echo Packaging: %OUTPUT%
echo using certificate: %CERT_FILE%...
echo.
call adt -package -target %TYPE%%TARGET% %OPTIONS% %SIGNING_OPTIONS% "%OUTPUT%" "%DESCRIPTOR%" %FILE_OR_DIR%
echo.
if errorlevel 1 goto failed
goto end

:start-windows
if not exist "%CERT_FILE%" goto certificate
:: Output file
set FILE_OR_DIR=%FILE_OR_DIR% -C "%ICONS%" .
if not exist "%DIST_PATH%" md "%DIST_PATH%"
set OUTPUT=%DIST_PATH%\%DIST_NAME%%TARGET%%NAMEADD%
:: Package
echo Packaging: %OUTPUT%
echo using certificate: %CERT_FILE%...
echo.
call adt -package %SIGNING_OPTIONS% -target %TYPE%%TARGET% "%OUTPUT%" "%DESCRIPTOR%" %FILE_OR_DIR%
echo.
if errorlevel 1 goto failed
goto end

:start-air
if not exist "%CERT_FILE%" goto certificate
:: Output file
set FILE_OR_DIR=%FILE_OR_DIR% -C "%ICONS%" .
if not exist "%DIST_PATH%" md "%DIST_PATH%"
set OUTPUT=%DIST_PATH%\%DIST_NAME%%TARGET%%NAMEADD%.%DIST_EXT%
:: Package
echo Packaging: %OUTPUT%
echo using certificate: %CERT_FILE%...
echo.
call adt -package %SIGNING_OPTIONS% "%OUTPUT%" "%DESCRIPTOR%" %FILE_OR_DIR%
echo.
if errorlevel 1 goto failed
goto end

:certificate
echo Certificate not found: %CERT_FILE%
echo.
echo Android: 
echo - generate a default certificate using 'bat\CreateCertificate.bat'
echo   or configure a specific certificate in 'bat\SetupApplication.bat'.
echo.
echo Windows / AIR Installer: 
echo - generate a default certificate using 'bat\CreateCertificateDesktop.bat'
echo   or configure a specific certificate in 'bat\SetupApplication.bat'.
echo.
echo iOS: 
echo - configure your developer key and project's Provisioning Profile
echo   in 'bat\SetupApplication.bat'.
echo.
if %PAUSE_ERRORS%==1 pause
exit

:failed
echo APK setup creation FAILED.
echo.
echo Troubleshooting: 
echo - did you build your project in FlashDevelop?
echo - verify AIR SDK target version in %DESCRIPTOR%
echo.
if %PAUSE_ERRORS%==1 pause
exit

:end
