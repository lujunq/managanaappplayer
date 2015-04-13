:user_configuration

:: About AIR application packaging
:: http://help.adobe.com/en_US/air/build/WS5b3ccc516d4fbf351e63e3d118666ade46-7fd9.html

:: NOTICE: all paths are relative to project root

:: Android packaging
set AND_CERT_NAME="managanaappplayer"
set AND_CERT_PASS=fd
set AND_CERT_FILE=cert\managanaappplayer.p12
set AND_ICONS=icons/android

set AND_SIGNING_OPTIONS=-storetype pkcs12 -keystore "%AND_CERT_FILE%"

:: iOS packaging
set IOS_DIST_CERT_FILE=
set IOS_DEV_CERT_FILE=
set IOS_DEV_CERT_PASS=
set IOS_PROVISION=cert\managanaappplayer.mobileprovision
set IOS_ICONS=icons/ios

set IOS_DEV_SIGNING_OPTIONS=-storetype pkcs12 -keystore "%IOS_DEV_CERT_FILE%" -provisioning-profile %IOS_PROVISION%
set IOS_DIST_SIGNING_OPTIONS=-storetype pkcs12 -keystore "%IOS_DIST_CERT_FILE%" -provisioning-profile %IOS_PROVISION%

:: Desktop packaging
set DESK_CERT_NAME="managanaappplayerdesktop"
set DESK_CERT_PASS=fd
set DESK_CERT_FILE=cert\managanaappplayerdesktop.p12
set DESK_ICONS=icons/desktop

set DESK_SIGNING_OPTIONS=-storetype pkcs12 -keystore "%DESK_CERT_FILE%"

:: Application descriptor
set APP_XML=application.xml
set DESK_XML=application-desktop.xml

:: Files to package
set APP_DIR=bin
set FILE_OR_DIR=-C %APP_DIR% .

:: Your application ID (must match <id> of Application descriptor)
set APP_ID=art.ciclope.managana

:: Output packages
set DIST_PATH=dist
set DIST_NAME=managanaappplayer

:: Debugging using a custom IP
set DEBUG_IP=



:validation
%SystemRoot%\System32\find /C "<id>%APP_ID%</id>" "%APP_XML%" > NUL
if errorlevel 1 goto badid
goto end

:badid
echo.
echo ERROR: 
echo   Application ID in 'bat\SetupApplication.bat' (APP_ID) 
echo   does NOT match Application descriptor '%APP_XML%' (id)
echo.

:end