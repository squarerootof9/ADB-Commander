 
#!/bin/bash

# Initialize variables
devices_dir="devices"
selected_serial=""
selected_name=""
adb_cmd="adb"

# Check if ADB is installed
if ! command -v $adb_cmd &>/dev/null; then
    echo "Error: adb is not installed. Please install it and try again."
    exit 1
fi

# Helper function to list connected devices
list_devices() {
    echo "Detecting connected devices..."
    mapfile -t devices < <($adb_cmd devices | grep -v "List" | grep "device" | awk '{print $1}')
    if [ ${#devices[@]} -eq 0 ]; then
        echo "No devices detected. Please connect a device and try again."
        exit 1
    fi
    echo "Connected Devices:"
    for i in "${!devices[@]}"; do
        device_name=$($adb_cmd -s "${devices[$i]}" shell getprop ro.product.model | tr -d '\r')
        echo "$((i + 1))) ${devices[$i]} - $device_name"
    done
    echo "Select a device by number:"
    read -r selection
    if [[ $selection -lt 1 || $selection -gt ${#devices[@]} ]]; then
        echo "Invalid selection."
        exit 1
    fi
    selected_serial="${devices[$((selection - 1))]}"
    selected_name=$($adb_cmd -s "$selected_serial" shell getprop ro.product.model | tr -d '\r')
}

# Main menu function
main_menu() {
    clear
    echo "== Device Menu for $selected_serial ($selected_name) =="
    echo "1) App Management"
    echo "2) Configure Device Settings"
    echo "3) Execute Custom Command"
    echo "4) Dump Device Settings to File"
    echo "5) Collect Device Logs"
    echo "6) Capture Screenshot"
    echo "7) Record Screen"
    echo "8) Check Battery Health"
    echo "9) Check Network Info"
    echo "10) Sync Device Time with Computer"
    echo "11) Device Information"
    echo "12) File Transfer"
    echo "13) Backup Data"
    echo "14) Restore Data"
    echo "15) Reboot Options"
    echo "16) Enable Wi-Fi ADB"
    echo "17) Switch Device"
    echo "18) Exit"
    echo "Select an option:"
    read -r action
    case $action in
    1) app_management ;;
    2) configure_device ;;
    3) execute_custom_command ;;
    4) dump_device_settings ;;
    5) collect_device_logs ;;
    6) capture_screenshot ;;
    7) record_screen ;;
    8) check_battery ;;
    9) check_network ;;
    10) sync_device_time ;;
    11) device_information ;;
    12) file_transfer ;;
    13) backup_data ;;
    14) restore_data ;;
    15) reboot_options ;;
    16) enable_wifi_adb ;;
    17) list_devices; main_menu ;;
    18) exit 0 ;;
    *) echo "Invalid option."; main_menu ;;
    esac
}

# Function for App Management
app_management() {
    clear
    echo "== App Management for $selected_serial ($selected_name) =="
    echo "1) List Installed Apps"
    echo "2) Install APKs from Directory"
    echo "3) Gather APKs from Device"
    echo "4) Uninstall Apps"
    echo "5) Clear App Data"
    echo "6) Return to Main Menu"
    echo "Select an option:"
    read -r app_choice
    case $app_choice in
    1) list_installed_apps ;;
    2) install_apks ;;
    3) gather_apks ;;
    4) uninstall_apps ;;
    5) clear_app_data ;;
    6) main_menu ;;
    *) echo "Invalid option."; app_management ;;
    esac
}

# Function to list installed apps
list_installed_apps() {
    echo "Listing installed apps..."
    $adb_cmd -s "$selected_serial" shell pm list packages
    echo "Press Enter to return."
    read -r
    app_management
}

# Function to install APKs
install_apks() {
    apk_dir="$devices_dir/$selected_serial/apk"
    mkdir -p "$apk_dir"
    echo "Looking for APK directories in $apk_dir..."

    # List subdirectories in the APK directory
    mapfile -t apk_dirs < <(find "$apk_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
    
    if [ ${#apk_dirs[@]} -eq 0 ]; then
        echo "No APK directories found in $apk_dir."
        echo "Press Enter to return."
        read -r
        app_management
        return
    fi

    echo "Found the following APK directories:"
    for i in "${!apk_dirs[@]}"; do
        echo "$((i + 1))) ${apk_dirs[$i]}"
    done

    echo "Enter the number of the APK package to install (or type 'all' to install all, or 'exit' to return):"
    read -r selection

    if [[ $selection == "exit" ]]; then
        app_management
        return
    elif [[ $selection == "all" ]]; then
        echo "Installing all APKs..."
        for dir in "${apk_dirs[@]}"; do
            apk="$dir/base.apk"
            if [ -f "$apk" ]; then
                echo "Installing $apk..."
                $adb_cmd -s "$selected_serial" install "$apk"
                if [ $? -eq 0 ]; then
                    echo "Successfully installed $apk."
                else
                    echo "Failed to install $apk."
                fi
            else
                echo "No base.apk found in $dir. Skipping."
            fi
        done
    elif [[ $selection -ge 1 && $selection -le ${#apk_dirs[@]} ]]; then
        selected_dir="${apk_dirs[$((selection - 1))]}"
        apk="$selected_dir/base.apk"
        if [ -f "$apk" ]; then
            echo "Installing $apk..."
            $adb_cmd -s "$selected_serial" install "$apk"
            if [ $? -eq 0 ]; then
                echo "Successfully installed $apk."
            else
                echo "Failed to install $apk."
            fi
        else
            echo "No base.apk found in $selected_dir."
        fi
    else
        echo "Invalid selection."
    fi

    echo "Installation complete. Press Enter to return."
    read -r
    app_management
}


# Function to gather APKs
gather_apks() {
    apk_dir="$devices_dir/$selected_serial/apk"
    mkdir -p "$apk_dir"
    echo "Gathering APKs from device..."
    mapfile -t packages < <($adb_cmd -s "$selected_serial" shell pm list packages | awk -F: '{print $2}')
    if [ ${#packages[@]} -eq 0 ]; then
        echo "No packages found."
        app_management
    fi
    for i in "${!packages[@]}"; do
        echo "$((i + 1))) ${packages[$i]}"
    done
    echo "Select a package by number to gather APKs (or type 'exit' to return):"
    read -r selection
    if [[ $selection == "exit" ]]; then
        app_management
    fi
    pkg_name="${packages[$((selection - 1))]}"
    pkg_dir="$apk_dir/$pkg_name"
    mkdir -p "$pkg_dir"
    echo "Gathering APKs for $pkg_name..."
    mapfile -t apk_paths < <($adb_cmd -s "$selected_serial" shell pm path "$pkg_name" | awk -F: '{print $2}' | tr -d '\r')
    for apk_path in "${apk_paths[@]}"; do
        apk_name=$(basename "$apk_path")
        echo "Pulling $apk_path..."
        $adb_cmd -s "$selected_serial" pull "$apk_path" "$pkg_dir/$apk_name"
    done
    echo "APKs gathered and saved to $pkg_dir. Press Enter to return."
    read -r
    app_management
}


# Function to uninstall apps
uninstall_apps() {
    mapfile -t packages < <($adb_cmd -s "$selected_serial" shell pm list packages | awk -F: '{print $2}')
    for i in "${!packages[@]}"; do
        echo "$((i + 1))) ${packages[$i]}"
    done
    echo "Select a package by number to uninstall (or type 'exit' to return):"
    read -r selection
    if [[ $selection == "exit" ]]; then
        app_management
    fi
    pkg_name="${packages[$((selection - 1))]}"
    echo "Uninstalling $pkg_name..."
    $adb_cmd -s "$selected_serial" uninstall "$pkg_name"
    echo "Uninstallation complete. Press Enter to return."
    read -r
    app_management
}

# Function to execute custom commands
execute_custom_command() {
    clear
    echo "== Execute Custom Command for $selected_serial ($selected_name) =="
    echo "Enter the ADB command to execute (or type 'exit' to return):"
    read -r custom_cmd
    if [[ $custom_cmd == "exit" ]]; then
        main_menu
    fi
    $adb_cmd -s "$selected_serial" $custom_cmd
    echo "Command executed. Press Enter to return."
    read -r
    main_menu
}

# Function to dump device settings to file
dump_device_settings() {
    settings_dir="$devices_dir/$selected_serial/settings"
    mkdir -p "$settings_dir"
    output_file="$settings_dir/device_settings_$(date '+%Y%m%d_%H%M%S').txt"
    echo "Dumping device settings to $output_file..."
    {
        echo "System Settings:"
        $adb_cmd -s "$selected_serial" shell settings list system
        echo
        echo "Secure Settings:"
        $adb_cmd -s "$selected_serial" shell settings list secure
        echo
        echo "Global Settings:"
        $adb_cmd -s "$selected_serial" shell settings list global
    } >"$output_file"
    echo "Settings dumped successfully. Press Enter to return."
    read -r
    main_menu
}

# Function to collect device logs
collect_device_logs() {
    logs_dir="$devices_dir/$selected_serial/logs"
    mkdir -p "$logs_dir"
    output_file="$logs_dir/device_logs_$(date '+%Y%m%d_%H%M%S').txt"
    echo "Collecting device logs to $output_file..."
    $adb_cmd -s "$selected_serial" logcat -d >"$output_file"
    echo "Logs collected successfully. Press Enter to return."
    read -r
    main_menu
}

# Function to capture a screenshot
capture_screenshot() {
    screenshots_dir="$devices_dir/$selected_serial/screenshots"
    mkdir -p "$screenshots_dir"
    screenshot_file="$screenshots_dir/screenshot_$(date '+%Y%m%d_%H%M%S').png"
    echo "Capturing screenshot to $screenshot_file..."
    $adb_cmd -s "$selected_serial" exec-out screencap -p >"$screenshot_file"
    echo "Screenshot captured successfully. Press Enter to return."
    read -r
    main_menu
}

# Function to record screen
record_screen() {
    recordings_dir="$devices_dir/$selected_serial/recordings"
    mkdir -p "$recordings_dir"
    echo "Recording screen on the device. Press Ctrl+C to stop recording."
    $adb_cmd -s "$selected_serial" shell screenrecord /sdcard/screenrecord.mp4
    output_file="$recordings_dir/screenrecord_$(date '+%Y%m%d_%H%M%S').mp4"
    echo "Pulling recording to $output_file..."
    $adb_cmd -s "$selected_serial" pull /sdcard/screenrecord.mp4 "$output_file"
    echo "Deleting temporary recording from device..."
    $adb_cmd -s "$selected_serial" shell rm /sdcard/screenrecord.mp4
    echo "Recording saved successfully. Press Enter to return."
    read -r
    main_menu
}

# Function to check battery health
check_battery() {
    echo "== Battery Health for $selected_serial ($selected_name) =="
    $adb_cmd -s "$selected_serial" shell dumpsys battery | grep -E 'level|status|health'
    echo "Press Enter to return."
    read -r
    main_menu
}

# Function to check network info
check_network() {
    echo "== Network Info for $selected_serial ($selected_name) =="
    $adb_cmd -s "$selected_serial" shell ip addr show
    echo "Press Enter to return."
    read -r
    main_menu
}

# Function to sync device time with computer
sync_device_time() {
    echo "== Syncing Device Time for $selected_serial ($selected_name) =="
    local_time=$(date '+%Y%m%d.%H%M%S')
    echo "Setting device time to $local_time..."
    $adb_cmd -s "$selected_serial" shell date -s "$local_time"
    echo "Time synced successfully. Press Enter to return."
    read -r
    main_menu
}

# Function to display device information
device_information() {
    echo "== Device Information for $selected_serial ($selected_name) =="
    echo "Model: $selected_name"
    echo "Serial Number: $selected_serial"
    $adb_cmd -s "$selected_serial" shell getprop | grep -E '(ro.product.model|ro.product.manufacturer|ro.build.version.release|ro.hardware|ro.product.cpu.abi|ro.serialno)'
    echo "Press Enter to return."
    read -r
    main_menu
}

# Function for file transfer
file_transfer() {
    echo "== File Transfer for $selected_serial ($selected_name) =="
    echo "1) Transfer from Device to Local Machine"
    echo "2) Transfer from Local Machine to Device"
    echo "3) Return to Main Menu"
    read -r transfer_choice
    case $transfer_choice in
    1) transfer_from_device ;;
    2) transfer_to_device ;;
    3) main_menu ;;
    *) echo "Invalid option."; file_transfer ;;
    esac
}

transfer_from_device() {
    local_dir="$devices_dir/$selected_serial/transfer"
    remote_dir="/sdcard/ADB_TRANSFER"
    mkdir -p "$local_dir"
    echo "Transferring files from $remote_dir to $local_dir..."
    $adb_cmd -s "$selected_serial" pull "$remote_dir" "$local_dir"
    echo "Transfer complete. Press Enter to return."
    read -r
    file_transfer
}

transfer_to_device() {
    local_dir="$devices_dir/$selected_serial/transfer"
    remote_dir="/sdcard/ADB_TRANSFER"
    echo "Transferring files from $local_dir to $remote_dir..."
    $adb_cmd -s "$selected_serial" push "$local_dir" "$remote_dir"
    echo "Transfer complete. Press Enter to return."
    read -r
    file_transfer
}

configure_device() {
    clear
    echo "== Configure Device Settings for $selected_serial ($selected_name) =="

    script_dir="$(dirname "$(realpath "$0")")"
    settings_dir="$script_dir"

    echo "Looking for settings files in $settings_dir..."
    mapfile -t settings_files < <(find "$settings_dir" -maxdepth 1 -type f -name "settings_*.txt")

    if [ ${#settings_files[@]} -eq 0 ]; then
        echo "No settings files found in $settings_dir."
        echo "Press Enter to return."
        read -r
        main_menu
        return
    fi

    echo "Available Settings Files:"
    for i in "${!settings_files[@]}"; do
        echo "$((i + 1))) $(basename "${settings_files[$i]}")"
    done

    echo "Enter the number of the settings file to apply (or type 'exit' to return):"
    read -r selection

    if [[ $selection == "exit" ]]; then
        main_menu
        return
    elif [[ $selection -ge 1 && $selection -le ${#settings_files[@]} ]]; then
        selected_file="${settings_files[$((selection - 1))]}"
        echo "Applying settings from $(basename "$selected_file")..."

        # Use a while loop to process all lines
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Debugging each line
            echo "DEBUG: Processing line: '$line'"

            # Skip comments and empty lines
            [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue

            # Execute the ADB command
            echo "Executing: $adb_cmd -s $selected_serial $line"
            $adb_cmd -s "$selected_serial" $line
            adb_exit_code=$?
            if [ $adb_exit_code -ne 0 ]; then
                echo "Error applying: $line (ADB exited with $adb_exit_code)"
            fi
        done < "$selected_file" # Ensure the entire file is read sequentially

        echo "All settings applied successfully. Press Enter to return."
        read -r
    else
        echo "Invalid selection."
    fi

    main_menu
}

reboot_options() {
    clear
    echo "== Reboot Options for $selected_serial ($selected_name) =="
    echo "1) Reboot to System"
    echo "2) Reboot to Recovery"
    echo "3) Reboot to Bootloader"
    echo "4) Reboot to Fastboot"
    echo "5) Return to Main Menu"
    echo "Select an option:"
    read -r reboot_choice
    case $reboot_choice in
    1)
        echo "Rebooting to system..."
        $adb_cmd -s "$selected_serial" reboot
        ;;
    2)
        echo "Rebooting to recovery..."
        $adb_cmd -s "$selected_serial" reboot recovery
        ;;
    3)
        echo "Rebooting to bootloader..."
        $adb_cmd -s "$selected_serial" reboot bootloader
        ;;
    4)
        echo "Rebooting to fastboot..."
        $adb_cmd -s "$selected_serial" reboot fastboot
        ;;
    5)
        main_menu
        ;;
    *)
        echo "Invalid option. Returning to reboot menu."
        reboot_options
        ;;
    esac
    echo "Reboot command executed. Press Enter to return to the main menu."
    read -r
    main_menu
}

backup_data() {
    clear
    echo "== Backup Data for $selected_serial ($selected_name) =="

    # Determine the backup directory for the selected device
    backup_dir="$devices_dir/$selected_serial"
    mkdir -p "$backup_dir"

    echo "Backing up data to $backup_dir..."

    # Perform the backup using adb
    $adb_cmd -s "$selected_serial" backup -apk -shared -all -f "$backup_dir/backup.ab"
    if [ $? -eq 0 ]; then
        echo "Backup completed successfully. File saved to $backup_dir/backup.ab."
    else
        echo "Error: Backup failed. Ensure the device is unlocked and connected."
    fi

    echo "Press Enter to return to the main menu."
    read -r
    main_menu
}

restore_data() {
    clear
    echo "== Restore Data for $selected_serial ($selected_name) =="

    # Determine the backup directory for the selected device
    backup_dir="$devices_dir/$selected_serial"

    # Check if a backup file exists
    if [ ! -d "$backup_dir" ] || [ -z "$(ls -A "$backup_dir" 2>/dev/null)" ]; then
        echo "No backup files found in $backup_dir."
        echo "Ensure you have a valid backup file in this directory."
        echo "Press Enter to return to the main menu."
        read -r
        main_menu
        return
    fi

    echo "Available Backup Files:"
    mapfile -t backup_files < <(find "$backup_dir" -type f -name "*.ab" 2>/dev/null)
    for i in "${!backup_files[@]}"; do
        echo "$((i + 1))) $(basename "${backup_files[$i]}")"
    done

    echo "Enter the number of the backup file to restore (or type 'exit' to return):"
    read -r selection

    if [[ $selection == "exit" ]]; then
        main_menu
        return
    elif [[ $selection -ge 1 && $selection -le ${#backup_files[@]} ]]; then
        selected_file="${backup_files[$((selection - 1))]}"
        echo "Restoring data from $(basename "$selected_file")..."
        
        # Perform the restore using adb
        $adb_cmd -s "$selected_serial" restore "$selected_file"
        if [ $? -eq 0 ]; then
            echo "Restore completed successfully. Please check your device for confirmation."
        else
            echo "Error: Restore failed. Ensure the device is unlocked and connected."
        fi
    else
        echo "Invalid selection."
    fi

    echo "Press Enter to return to the main menu."
    read -r
    main_menu
}

enable_wifi_adb() {
    clear
    echo "== Enable Wi-Fi ADB for $selected_serial ($selected_name) =="

    # Get the device's IP address
    device_ip=$($adb_cmd -s "$selected_serial" shell ip -f inet addr show wlan0 | awk '/inet / {print $2}' | cut -d/ -f1)

    if [ -z "$device_ip" ]; then
        echo "Unable to retrieve the device's IP address. Ensure Wi-Fi is enabled and the device is connected to a network."
        echo "Press Enter to return to the main menu."
        read -r
        main_menu
        return
    fi

    echo "Device IP: $device_ip"

    # Enable Wi-Fi ADB settings
    echo "Enabling Wi-Fi ADB on the device..."
    $adb_cmd -s "$selected_serial" shell settings put global adb_wifi_enabled 1
    echo "Please confirm the Wi-Fi ADB prompt on your device, if shown."
    sleep 3

    # Restart ADB in TCP mode
    echo "Restarting ADB in TCP mode..."
    $adb_cmd -s "$selected_serial" tcpip 5555
    if [ $? -ne 0 ]; then
        echo "Error: Failed to restart ADB in TCP mode."
        echo "Press Enter to return to the main menu."
        read -r
        main_menu
        return
    fi

    # Connect to the device over Wi-Fi
    echo "Connecting to the device over Wi-Fi..."
    $adb_cmd connect "$device_ip":5555
    if [ $? -eq 0 ]; then
        echo "Successfully connected to $device_ip over Wi-Fi."
    else
        echo "Error: Failed to connect to the device over Wi-Fi."
    fi

    echo "Press Enter to return to the main menu."
    read -r
    main_menu
}

# Start the script by listing devices
list_devices
main_menu
