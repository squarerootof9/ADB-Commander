# ADB-Commander (adbc.bat)

ADB Commander (`adbc.bat`) is a versatile batch script designed to simplify and streamline Android device management via the Android Debug Bridge (ADB). It supports multiple devices, APK management, system configuration, and more.

## Features

### Device Management
- Detect and list connected Android devices with their serial numbers and model names.
- Switch between multiple connected devices seamlessly.

### APK Management
- Install APKs from a local directory.
- Gather APKs from the connected device into organized directories.
- Uninstall apps by selecting from a numbered list.
- Clear app data for individual apps or all apps on the device.

### Device Configuration
- Enable Wi-Fi ADB and connect devices wirelessly.
- Configure system settings via customizable text files.

### Utilities
- Capture screenshots and save them in organized directories by device.
- Record screen activity and pull the recordings from the device.
- Backup and restore device data to/from organized directories.
- Collect system logs for debugging purposes.
- Sync device time with the local machine.

### Additional Features
- Execute custom ADB shell commands.
- Check battery health and network information.
- Reboot options for connected devices.

---

## Requirements

1. A computer with Windows OS and ADB installed.
2. A properly configured `adb` in your system's PATH.
3. Android devices with USB debugging enabled.

---

## Usage

1. Place `adbc.bat` in a directory of your choice.
2. Open a Command Prompt window and navigate to the directory containing `adbc.bat`.
3. Run the script by typing:
   ```batch
   adbc.bat
   ```
4. Follow the on-screen menu to manage connected devices.

---

## Menu Overview

### Main Menu Options
1. **App Management**: Manage installed apps and APK files.
2. **Configure Device Settings**: Apply system configurations from text files.
3. **Execute Custom Command**: Run any ADB command directly.
4. **Dump Device Settings to File**: Export system settings to a file.
5. **Collect Device Logs**: Save logcat output for debugging.
6. **Capture Screenshot**: Take a screenshot and save it locally.
7. **Record Screen**: Record the screen and transfer the video to your computer.
8. **Check Battery Health**: Display battery status and health.
9. **Check Network Info**: Display network connection details.
10. **Sync Device Time**: Sync the device clock with your computer.
11. **Device Information**: Show detailed information about the device.
12. **File Transfer**: Transfer files between the device and your computer.
13. **Backup Data**: Create a backup of device data.
14. **Restore Data**: Restore device data from a backup.
15. **Reboot Options**: Reboot the device in different modes.
16. **Enable Wi-Fi ADB**: Connect to devices wirelessly over Wi-Fi.
17. **Switch Device**: Change the target device for the script.
18. **Exit**: Close the script.

---

## Directory Structure

The script organizes data into directories under the `devices` folder:
- `devices\<serial_number>\apk\`: APK files gathered or installed.
- `devices\<serial_number>\logs\`: Collected logs.
- `devices\<serial_number>\screenshots\`: Captured screenshots.
- `devices\<serial_number>\recordings\`: Screen recordings.
- `devices\<serial_number>\settings\`: Dumped system settings.
- `devices\<serial_number>\`: Backup and restore files.

---

## Customization

### System Configuration Files
You can customize device settings by creating text files in the `settings_*.txt` format. Each file should contain ADB shell commands, one per line. For example:

```plaintext
shell settings put system screen_brightness 50
shell settings put global adb_wifi_enabled 1
```

Lines starting with `#` are treated as comments.

---

## Troubleshooting

1. **ADB Daemon Not Running**: Ensure ADB is installed and running. The script attempts to start the daemon automatically.
2. **No Devices Found**: Verify that USB debugging is enabled on the device and it is properly connected.
3. **Permission Issues**: Run the script as Administrator if directory creation fails.
