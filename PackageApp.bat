@echo off
set PAUSE_ERRORS=1
call bat\SetupSDK.bat
call bat\SetupApplication.bat

:menu
echo.
echo Package for target
echo.
echo Android:
echo.
echo  [1] debug           (apk-debug)
echo  [2] captive         (apk-captive-runtime)
echo  [3] captive x86     (apk-captive-runtime -arch x86)
echo.
echo iOS:
echo.
echo  [4] test            (ipa-test)
echo  [5] debug           (ipa-debug)
echo  [6] ad-hoc          (ipa-ad-hoc)
echo  [7] App Store       (ipa-app-store)
echo.
echo Desktop:
echo.
echo  [8] Windows bundle  (bundle)
echo  [9] AIR installer   (air)
echo.

:choice
set /P C=[Choice]: 
echo.

if "%C%"=="1" set PLATFORM=android
if "%C%"=="2" set PLATFORM=android
if "%C%"=="3" set PLATFORM=android
if "%C%"=="4" set PLATFORM=ios
if "%C%"=="5" set PLATFORM=ios
if "%C%"=="6" set PLATFORM=ios-dist
if "%C%"=="7" set PLATFORM=ios-dist
if "%C%"=="8" set PLATFORM=windows
if "%C%"=="9" set PLATFORM=air

if "%C%"=="1" set TARGET=-debug
if "%C%"=="1" set OPTIONS=-connect %DEBUG_IP%
if "%C%"=="2" set TARGET=-captive-runtime
if "%C%"=="3" set OPTIONS=-arch x86
if "%C%"=="3" set TARGET=-captive-runtime
if "%C%"=="3" set NAMEADD=-x86

if "%C%"=="4" set TARGET=-test
if "%C%"=="5" set TARGET=-debug
if "%C%"=="5" set OPTIONS=-connect %DEBUG_IP%
if "%C%"=="6" set TARGET=-ad-hoc
if "%C%"=="7" set TARGET=-app-store

if "%C%"=="8" set TARGET=bundle
if "%C%"=="9" set TARGET=airinstaller

call bat\Packager.bat

if "%PLATFORM%"=="android" goto android-package
if "%PLATFORM%"=="windows" goto desktop-end
if "%PLATFORM%"=="air" goto desktop-end

:ios-package
if "%AUTO_INSTALL_IOS%" == "yes" goto ios-install
echo Now manually install and start application on device
echo.
goto end

:ios-install
echo Installing application for testing on iOS (%DEBUG_IP%)
echo.
call adt -installApp -platform ios -package "%OUTPUT%"
if errorlevel 1 goto installfail

echo Now manually start application on device
echo.
goto end

:desktop-end
echo Packaging complete.
echo.
goto end

:android-package
adb devices
echo.
echo Installing %OUTPUT% on the device...
echo.
adb -d install -r "%OUTPUT%"
if errorlevel 1 goto installfail
goto end

:installfail
echo.
echo Installing the app on the device failed

:end
pause
