@echo off
setlocal enabledelayedexpansion

REM Check if ADB daemon is running
echo Checking if ADB daemon is running...
adb get-state 1>nul 2>nul
if %errorlevel% neq 0 (
    echo ADB daemon not running. Starting ADB daemon in the background...
    start adb start-server  REM Start ADB as a separate process
    timeout /t 3 >nul  REM Wait briefly for ADB to start
)

echo ADB daemon is running.

REM Main Menu Loop
:main_menu
cls
echo == ADB APK Manager and Device Setup ==
echo.
echo Detecting connected devices...

REM List connected devices and capture their serial numbers and names
set device_count=0
for /f "tokens=1" %%i in ('adb devices ^| findstr "device$"') do (
    set /a device_count+=1
    set device_serial_!device_count!=%%i

    REM Get the device name
    for /f "delims=" %%j in ('adb -s %%i shell getprop ro.product.model') do (
        set device_name_!device_count!=%%j
    )
)

REM Check if any devices are connected
if "%device_count%"=="0" (
    echo No connected devices found.
    pause
    exit /b 1
)

REM Display detected devices with names
echo.
echo Connected Devices:
for /L %%i in (1,1,%device_count%) do (
    set serial=!device_serial_%%i!
    set name=!device_name_%%i!
    echo [%%i] Device Serial: !serial! - Device Name: !name!
)

REM Prompt user to select a device
echo.
set /p choice=Select a device by number (1-%device_count%) or press X to exit: 
if /i "%choice%"=="X" exit /b 0
if %choice% lss 1 if %choice% gtr %device_count% (
    echo Invalid selection.
    pause
    goto main_menu
)

set selected_serial=!device_serial_%choice%!
set selected_name=!device_name_%choice%!
echo You selected device with Serial: %selected_serial% - Device Name: %selected_name%

REM Create a directory for the selected device's APKs if it doesn't exist
set apk_dir=devices\%selected_serial%\apk
if not exist "%apk_dir%" (
    mkdir "%apk_dir%"
)

REM Main Device Menu
:device_menu

cls
echo == Device Menu for %selected_serial% (%selected_name%) ==
echo.
echo 1) App Management
echo 2) Configure Device Settings
echo 3) Execute Custom Command
echo 4) Dump Device Settings to File
echo 5) Collect Device Logs
echo 6) Capture Screenshot
echo 7) Record Screen
echo 8) Check Battery Health
echo 9) Check Network Info
echo 10) Sync Device Time with Computer
echo 11) Device Information
echo 12) File Transfer
echo 13) Backup Data
echo 14) Restore Data
echo 15) Reboot Options
echo 16) Enable Wi-Fi ADB
echo 17) Switch Device
echo 18) Exit
set /p action=Select an action (1-18): 

if "%action%"=="1" goto app_management
if "%action%"=="2" goto configure_device
if "%action%"=="3" goto custom_command
if "%action%"=="4" goto dump_settings
if "%action%"=="5" goto collect_logs
if "%action%"=="6" goto capture_screenshot
if "%action%"=="7" goto record_screen
if "%action%"=="8" goto check_battery
if "%action%"=="9" goto check_network
if "%action%"=="10" goto sync_time
if "%action%"=="11" goto device_info
if "%action%"=="12" goto file_transfer
if "%action%"=="13" goto backup_data
if "%action%"=="14" goto restore_data
if "%action%"=="15" goto reboot_options
if "%action%"=="16" goto enable_wifi_adb
if "%action%"=="17" goto main_menu
if "%action%"=="18" exit /b 0

echo Invalid selection.
pause

goto device_menu

REM Backup Data
:backup_data
cls
echo == Backup Data for %selected_serial% (%selected_name%) ==

REM Define backup path
set "device_dir=devices\%selected_serial%"
set "backup_file=%device_dir%\backup.ab"

REM Ensure the device directory exists
if not exist "%device_dir%" (
    echo Creating directory %device_dir%...
    mkdir "%device_dir%"
)

echo Creating backup file %backup_file%...
adb -s %selected_serial% backup -apk -shared -all -f "%backup_file%"
echo Backup completed and saved to %backup_file%.
pause
goto device_menu


:restore_data
cls
echo == Restore Data for %selected_serial% (%selected_name%) ==

REM Define backup path
set "device_dir=devices\%selected_serial%"
set "backup_file=%device_dir%\backup.ab"

REM Check if the backup file exists
if not exist "%backup_file%" (
    echo No backup file found at %backup_file%.
    pause
    goto device_menu
)

echo Restoring data from %backup_file%...
adb -s %selected_serial% restore "%backup_file%"
echo Restore completed from %backup_file%.
pause
goto device_menu


:app_management
cls
echo == App Management for %selected_serial% (%selected_name%) ==
echo.
echo 1) List Installed Apps
echo 2) Install APKs from Directory
echo 3) Gather APKs from Device
echo 4) Uninstall Apps
echo 5) Clear App Data
echo 6) Return to Device Menu
set /p app_choice=Select an option (1-6): 

if "%app_choice%"=="1" goto list_installed_apps
if "%app_choice%"=="2" goto install_apks
if "%app_choice%"=="3" goto gather_apks
if "%app_choice%"=="4" goto uninstall_apps
if "%app_choice%"=="5" goto clear_app_data
if "%app_choice%"=="6" goto device_menu

echo Invalid selection.
pause
goto app_management

:list_installed_apps
cls
echo == List of Installed Apps for %selected_serial% (%selected_name%) ==
adb -s %selected_serial% shell pm list packages
pause
goto app_management

:uninstall_apps
cls
echo == Uninstall Apps for %selected_serial% (%selected_name%) ==
set app_count=0

REM List installed apps with numbers
for /f "tokens=2 delims=:" %%i in ('adb -s %selected_serial% shell pm list packages') do (
    set /a app_count+=1
    set app_pkg_!app_count!=%%i
    echo [!app_count!] %%i
)

if "%app_count%"=="0" (
    echo No apps found to uninstall.
    pause
    goto app_management
)

REM Prompt user for app selection
set /p uninstall_selection=Enter the number of the app to uninstall (or type 'exit' to return): 

if /i "%uninstall_selection%"=="exit" goto app_management
if "%uninstall_selection%" lss 1 if "%uninstall_selection%" gtr %app_count% (
    echo Invalid selection.
    pause
    goto uninstall_apps
)

set app_pkg_name=!app_pkg_%uninstall_selection%!
echo Uninstalling !app_pkg_name! from device %selected_serial%...
adb -s %selected_serial% uninstall !app_pkg_name!
pause
goto uninstall_apps

:clear_app_data
cls
echo == Clear App Data for %selected_serial% (%selected_name%) ==
set app_count=0

REM List installed apps with numbers
for /f "tokens=2 delims=:" %%i in ('adb -s %selected_serial% shell pm list packages') do (
    set /a app_count+=1
    set app_pkg_!app_count!=%%i
    echo [!app_count!] %%i
)

if "%app_count%"=="0" (
    echo No apps found to clear data.
    pause
    goto app_management
)

REM Prompt user for app selection
set /p clear_selection=Enter the number of the app to clear data (or type 'all' for all apps, or 'exit' to return): 

if /i "%clear_selection%"=="exit" goto app_management
if /i "%clear_selection%"=="all" (
    echo Clearing data for all apps...
    for /L %%i in (1,1,%app_count%) do (
        set app_pkg_name=!app_pkg_%%i!
        echo Clearing data for !app_pkg_name!...
        adb -s %selected_serial% shell pm clear !app_pkg_name!
    )
    pause
    goto app_management
)

if "%clear_selection%" lss 1 if "%clear_selection%" gtr %app_count% (
    echo Invalid selection.
    pause
    goto clear_app_data
)

set app_pkg_name=!app_pkg_%clear_selection%!
echo Clearing data for !app_pkg_name!...
adb -s %selected_serial% shell pm clear !app_pkg_name!
pause
goto clear_app_data

:record_screen
cls
echo == Record Screen for %selected_serial% (%selected_name%) ==

REM Define paths
set "device_dir=devices\%selected_serial%"
set "recording_dir=%device_dir%\recordings"
set "timestamp=%date:~-4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "record_file=%recording_dir%\screenrecord_%timestamp%.mp4"

REM Ensure the recordings directory exists
if not exist "%recording_dir%" (
    echo Creating directory %recording_dir%...
    mkdir "%recording_dir%"
)

REM Record the screen on the device in the foreground
echo Recording screen on the device. Press Ctrl+C and select N to stop recording and copy video.
adb -s %selected_serial% shell screenrecord /sdcard/screenrecord.mp4

REM Check if the recording file exists on the device before pulling
adb -s %selected_serial% shell "if [ -f /sdcard/screenrecord.mp4 ]; then echo exists; fi" > temp.txt
set /p recording_status=<temp.txt
del temp.txt

if "%recording_status%"=="exists" (
    echo Pulling the screen recording from the device...
    adb -s %selected_serial% pull /sdcard/screenrecord.mp4 "%record_file%"
    echo Deleting the recording from the device...
    adb -s %selected_serial% shell rm /sdcard/screenrecord.mp4
    echo Screen recording saved as %record_file%.
) else (
    echo No recording file found on the device. Recording may have been interrupted.
)

pause
goto device_menu


:capture_screenshot
cls
echo == Capture Screenshot for %selected_serial% (%selected_name%) ==

REM Define paths
set "device_dir=devices\%selected_serial%"
set "screenshot_dir=%device_dir%\screenshots"
set "timestamp=%date:~-4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "screenshot_file=%screenshot_dir%\screenshot_%timestamp%.png"

REM Ensure the screenshot directory exists
if not exist "%screenshot_dir%" (
    echo Creating directory %screenshot_dir%...
    mkdir "%screenshot_dir%"
)

REM Capture the screenshot on the device
adb -s %selected_serial% shell screencap -p /sdcard/screenshot.png

REM Pull the screenshot to the local screenshot directory with a timestamped filename
adb -s %selected_serial% pull /sdcard/screenshot.png "%screenshot_file%"

REM Delete the screenshot from the device
adb -s %selected_serial% shell rm /sdcard/screenshot.png

echo Screenshot saved as %screenshot_file%.
pause
goto device_menu



:check_battery
cls
echo == Check Battery Health for %selected_serial% (%selected_name%) ==
echo.
adb -s %selected_serial% shell dumpsys battery
echo.
echo Battery health information displayed above.
pause
goto device_menu

:check_network
cls
echo == Check Network Info for %selected_serial% (%selected_name%) ==
echo.
echo Wi-Fi Status:
adb -s %selected_serial% shell dumpsys wifi | findstr "Wi-Fi"
echo.
echo IP Address:
adb -s %selected_serial% shell ip address show wlan0 | findstr /i "inet"
echo.
echo Data Connection Status:
adb -s %selected_serial% shell dumpsys connectivity | findstr "ActiveNetwork"
echo.
echo Network information displayed above.
pause
goto device_menu

:collect_logs
cls
echo == Collect Device Logs for %selected_serial% (%selected_name%) ==

REM Define paths
set "device_dir=devices\%selected_serial%"
set "log_dir=%device_dir%\logs"
set "timestamp=%date:~-4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "log_file=%log_dir%\logcat_%timestamp%.txt"

REM Ensure the log directory exists
if not exist "%log_dir%" (
    echo Creating directory %log_dir%...
    mkdir "%log_dir%"
)

REM Collect the logcat and save it to the log file
adb -s %selected_serial% logcat -d > "%log_file%"

echo Logcat saved to %log_file%.
pause
goto device_menu

:custom_command
cls
echo == Execute Custom Command on %selected_serial% (%selected_name%) ==
echo.
set /p custom_cmd=Enter the ADB shell command to execute (or type 'exit' to return): 

if /i "%custom_cmd%"=="exit" goto device_menu

echo Executing: adb -s %selected_serial% shell %custom_cmd%
adb -s %selected_serial% shell %custom_cmd%
pause
goto custom_command

:enable_wifi_adb
cls
echo == Enable Wi-Fi ADB for %selected_serial% (%selected_name%) ==

REM Enable Wi-Fi ADB in device settings
echo Enabling Wi-Fi ADB on the device. Please confirm the action on the device if prompted.
adb -s %selected_serial% shell settings put global adb_wifi_enabled 1
timeout /t 5 >nul

REM Get the device IP address using a reliable method
for /f "tokens=2 delims= " %%i in ('adb -s %selected_serial% shell ip addr show wlan0 ^| findstr /i "inet " ^| findstr /v "inet6"') do (
    set device_ip=%%i
)

REM Extract just the IP address part (remove subnet mask)
for /f "tokens=1 delims=/" %%i in ("%device_ip%") do set device_ip=%%i

if "%device_ip%"=="" (
    echo Could not determine the device IP. Please ensure Wi-Fi is connected.
    pause
    goto device_menu
)

echo Device IP: %device_ip%
adb -s %selected_serial% tcpip 5555
timeout /t 2 >nul
adb connect %device_ip%
echo Connected to %device_ip% over Wi-Fi.
pause
goto device_menu


REM File Transfer Option
:file_transfer
cls
echo == File Transfer Menu for %selected_serial% (%selected_name%) ==
echo.
echo 1) Transfer from Device to Local Machine
echo 2) Transfer from Local Machine to Device
echo 3) Return to Device Menu
set /p transfer_choice=Select an option (1-3): 

if "%transfer_choice%"=="1" goto transfer_from_device
if "%transfer_choice%"=="2" goto transfer_to_device
if "%transfer_choice%"=="3" goto device_menu

echo Invalid selection.
pause
goto file_transfer

REM Transfer Files from Device to Local Machine
:transfer_from_device
cls
echo == Transfer Files from Device to Local Machine ==

REM Define paths
set "local_transfer_dir=%~dp0ADB_TRANSFER"
set "device_transfer_dir=/storage/emulated/0/Downloads/ADB_TRANSFER"

REM Check if the directory exists on the device
adb -s %selected_serial% shell "[ -d '%device_transfer_dir%' ] && echo exists" >nul
if %errorlevel% neq 0 (
    echo The ADB_TRANSFER directory does not exist on the device at %device_transfer_dir%.
    echo Please create the directory and add files to transfer, then try again.
    pause
    goto file_transfer
)

REM Check if the local directory exists, create if needed
if not exist "%local_transfer_dir%" (
    echo Creating local directory %local_transfer_dir%...
    mkdir "%local_transfer_dir%"
)

REM Pull files from device to local without recreating directory structure
echo Transferring files from device to local machine...
adb -s %selected_serial% pull "%device_transfer_dir%/." "%local_transfer_dir%"

echo Files transferred from device to local machine successfully.
pause
goto file_transfer

REM Transfer Files from Local Machine to Device
:transfer_to_device
cls
echo == Transfer Files from Local Machine to Device ==

REM Define paths
set "local_transfer_dir=%~dp0ADB_TRANSFER"
set "device_transfer_dir=/storage/emulated/0/ADB_TRANSFER"

REM Check if the local directory exists
if not exist "%local_transfer_dir%" (
    echo The ADB_TRANSFER directory does not exist on the local machine at %local_transfer_dir%.
    echo Please create the directory and add files to transfer, then try again.
    pause
    goto file_transfer
)

REM Check if the directory exists on the device, create if needed
adb -s %selected_serial% shell "if [ ! -d '%device_transfer_dir%' ]; then mkdir '%device_transfer_dir%'; fi"

REM Push files from local to device recursively
echo Transferring files from local machine to device...
adb -s %selected_serial% push "%local_transfer_dir%/." "%device_transfer_dir%"

echo Files transferred from local machine to device successfully.
pause
goto file_transfer

REM Sync Device Time with Computer
:sync_time
cls
echo == Syncing Device Time with Computer for %selected_serial% (%selected_name%) ==
echo.

REM Get the current date and time in the format MMDDhhmmYYYY.ss using PowerShell
for /f %%i in ('powershell -command "(Get-Date).ToString('MMddHHmmyyyy.ss')"') do set datetime=%%i

echo Syncing time to: %datetime%

REM Sync date and time on the device
adb -s %selected_serial% shell "date %datetime%"

if %errorlevel%==0 (
    echo Time successfully synced to device.
) else (
    echo Failed to sync time to device.
)

pause
goto device_menu

REM Display Device Information
:device_info
cls
echo == Device Information for %selected_serial% (%selected_name%) ==
echo.

REM Retrieve various device information
echo Model:               %selected_name%
for /f "tokens=*" %%i in ('adb -s %selected_serial% shell getprop ro.product.manufacturer') do echo Manufacturer:        %%i
for /f "tokens=*" %%i in ('adb -s %selected_serial% shell getprop ro.build.version.release') do echo Android Version:     %%i
for /f "tokens=*" %%i in ('adb -s %selected_serial% shell getprop ro.build.version.sdk') do echo SDK Version:         %%i
for /f "tokens=*" %%i in ('adb -s %selected_serial% shell wm size') do echo Screen Resolution:   %%i
for /f "tokens=*" %%i in ('adb -s %selected_serial% shell wm density') do echo Screen Density:      %%i
for /f "tokens=2 delims=: " %%i in ('adb -s %selected_serial% shell dumpsys battery ^| find "level"') do echo Battery Level:       %%i
for /f "tokens=2 delims=: " %%i in ('adb -s %selected_serial% shell dumpsys battery ^| find "status"') do echo Battery Status:      %%i
for /f "tokens=*" %%i in ('adb -s %selected_serial% shell df /data ^| findstr /i "data"') do echo Storage:             %%i
for /f "tokens=*" %%i in ('adb -s %selected_serial% shell getprop ro.serialno') do echo Serial Number:       %%i
for /f "tokens=*" %%i in ('adb -s %selected_serial% shell getprop ro.hardware') do echo Hardware:            %%i
for /f "tokens=*" %%i in ('adb -s %selected_serial% shell getprop ro.product.cpu.abi') do echo CPU Architecture:    %%i
for /f "tokens=*" %%i in ('adb -s %selected_serial% shell getprop net.hostname') do echo Device Hostname:      %%i

pause
goto device_menu

REM Device Configuration Menu - Load settings from files
:configure_device
cls
echo == Load Device Configuration for %selected_serial% (%selected_name%) ==
echo.

REM List available settings files
set config_count=0
for %%f in (settings_*.txt) do (
    set /a config_count+=1
    set config_file_!config_count!=%%f
    echo [!config_count!] %%f
)

if "%config_count%"=="0" (
    echo No settings files found in the current directory.
    pause
    goto device_menu
)

REM Prompt user to select a configuration file
echo.
set /p config_choice=Select a configuration file by number (1-%config_count%) or press X to return to device menu: 

if /i "%config_choice%"=="X" goto device_menu
if %config_choice% lss 1 if %config_choice% gtr %config_count% (
    echo Invalid selection.
    pause
    goto configure_device
)

set selected_config=!config_file_%config_choice%!
echo Applying settings from %selected_config%...

REM Read and execute each line in the selected configuration file
for /f "usebackq tokens=*" %%l in ("%selected_config%") do (
    REM Skip comment lines starting with #
    set "line=%%l"
    if not "!line!"=="" if "!line:~0,1!" neq "#" (
        echo Executing: adb -s %selected_serial% %%l
        adb -s %selected_serial% %%l
    )
)

echo Configuration from %selected_config% applied successfully.
pause
goto device_menu

REM Dump Device Settings to File
:dump_settings
cls
echo == Dump Device Settings for %selected_serial% (%selected_name%) ==

REM Define paths
set "device_dir=devices\%selected_serial%"
set "settings_dir=%device_dir%\settings"
set "timestamp=%date:~-4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "settings_file=%settings_dir%\settings_%timestamp%.txt"

REM Ensure the settings directory exists
if not exist "%settings_dir%" (
    echo Creating directory %settings_dir%...
    mkdir "%settings_dir%"
)

echo Dumping device settings to %settings_file%...

REM Dump System Settings
echo ============================== >> "%settings_file%"
echo System Settings: >> "%settings_file%"
echo ============================== >> "%settings_file%"
adb -s %selected_serial% shell settings list system >> "%settings_file%"

REM Dump Secure Settings
echo ============================== >> "%settings_file%"
echo Secure Settings: >> "%settings_file%"
echo ============================== >> "%settings_file%"
adb -s %selected_serial% shell settings list secure >> "%settings_file%"

REM Dump Global Settings
echo ============================== >> "%settings_file%"
echo Global Settings: >> "%settings_file%"
echo ============================== >> "%settings_file%"
adb -s %selected_serial% shell settings list global >> "%settings_file%"

echo Device settings dumped to %settings_file%.
pause
goto device_menu


REM Install APKs from Directory
:install_apks
cls
echo == Install APKs on %selected_serial% (%selected_name%) ==
echo.

REM List package directories in the device-specific directory
set apk_count=0
for /d %%d in ("%apk_dir%\*") do (
    set /a apk_count+=1
    set apk_pkg_!apk_count!=%%~nxd
    echo [!apk_count!] %%~nxd
)

if "%apk_count%"=="0" (
    echo No APKs available for installation in "%apk_dir%". Place APK files in this directory and try again.
    pause
    goto device_menu
)

REM Prompt for selection of APK package to install
:install_apk_selection
set /p install_selection=Enter the number of the APK package to install, 'all' to install all, or 'exit' to return to the main menu: 

if /i "%install_selection%"=="exit" goto device_menu
if /i "%install_selection%"=="all" (
    echo Installing all APK packages in the directory...

    REM Loop through all package directories and install each with all APKs inside
    for /L %%i in (1,1,%apk_count%) do (
        set apk_pkg_name=!apk_pkg_%%i!
        set "package_dir=%apk_dir%\!apk_pkg_name!"
        echo Installing !apk_pkg_name! on device %selected_serial%...

        REM Gather all APK files in the package directory
        set "apk_files="
        for %%a in ("!package_dir!\*.apk") do (
            set "apk_files=!apk_files! "%%a""
        )

        REM Install using install-multiple if there are multiple APK files, otherwise use install
        if defined apk_files (
            adb -s %selected_serial% install-multiple !apk_files!
        ) else (
            adb -s %selected_serial% install !apk_files!
        )
        
        if %errorlevel%==0 (
            echo Successfully installed !apk_pkg_name! on device %selected_serial%.
        ) else (
            echo Failed to install !apk_pkg_name! on device %selected_serial%.
        )
    )
    pause
    goto device_menu
)

REM Install a selected APK package with all splits
if "%install_selection%" lss 1 if "%install_selection%" gtr %apk_count% (
    echo Invalid selection.
    pause
    goto install_apk_selection
)

set apk_pkg_name=!apk_pkg_%install_selection%!
set "package_dir=%apk_dir%\!apk_pkg_name!"
echo Installing !apk_pkg_name! on device %selected_serial%...

REM Gather all APK files in the package directory
set "apk_files="
for %%a in ("!package_dir!\*.apk") do (
    set "apk_files=!apk_files! "%%a""
)

REM Install using install-multiple if there are multiple APK files, otherwise install single APK
if defined apk_files (
    adb -s %selected_serial% install-multiple !apk_files!
) else (
    adb -s %selected_serial% install !apk_files!
)

if %errorlevel%==0 (
    echo Successfully installed !apk_pkg_name! on device %selected_serial%.
) else (
    echo Failed to install !apk_pkg_name! on device %selected_serial%.
)

pause
goto install_apks

:gather_apks
cls
echo == Gather APKs from %selected_serial% (%selected_name%) ==
echo.

REM List installed packages on the device
set pkg_count=0
for /f "tokens=2 delims=:" %%i in ('adb -s %selected_serial% shell pm list packages') do (
    set /a pkg_count+=1
    set pkg_!pkg_count!=%%i
    echo [!pkg_count!] %%i
)

if "%pkg_count%"=="0" (
    echo No installed packages found.
    pause
    goto device_menu
)

REM Prompt for selection of APK to gather
:select_apk
echo.
set /p pkg_num=Enter the number of the APK to gather (or type 'exit' to return to the main menu): 

if /i "%pkg_num%"=="exit" goto device_menu
if "%pkg_num%" lss 1 if "%pkg_num%" gtr %pkg_count% (
    echo Invalid selection: %pkg_num%.
    pause
    goto select_apk
)

REM Get the package name for the selected APK number
set "pkg_name=!pkg_%pkg_num%!"
echo Gathering APKs for package !pkg_name! from device %selected_serial%...

REM Create a directory for the package inside the device-specific directory
set "package_dir=%apk_dir%\!pkg_name!"
if not exist "!package_dir!" mkdir "!package_dir!"

REM Get all APK paths (base and splits) for the package and save them in the package directory
for /f "tokens=2 delims=:" %%p in ('adb -s %selected_serial% shell pm path !pkg_name!') do (
    set "apk_path=%%p"
    
    REM Remove the "package:" prefix
    set "apk_path=!apk_path:package:=!"
    
    REM Extract the file name from apk_path
    for %%f in ("!apk_path!") do set "file_name=%%~nxf"
    
    REM Pull the APK and save it with the correct filename
    adb -s %selected_serial% pull "!apk_path!" "!package_dir!\!file_name!"
)

echo All APKs for !pkg_name! gathered and saved to %package_dir%.
pause
goto select_apk


:reboot_options
cls
echo == Reboot Options ==
echo 1) Normal Reboot
echo 2) Reboot to Recovery
echo 3) Reboot to Bootloader
echo 4) Return to Device Menu
set /p reboot_choice=Select an option (1-4): 

if "%reboot_choice%"=="1" adb -s %selected_serial% reboot & goto device_menu
if "%reboot_choice%"=="2" adb -s %selected_serial% reboot recovery & goto device_menu
if "%reboot_choice%"=="3" adb -s %selected_serial% reboot bootloader & goto device_menu
if "%reboot_choice%"=="4" goto device_menu

echo Invalid selection.
pause
goto reboot_options

