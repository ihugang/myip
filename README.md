# macOS Menu Bar IP Display

This macOS application displays the current IP address of your computer in the menu bar. It alternates between displaying the WAN and LAN IP addresses every 3 seconds. Additionally, you can view both IP addresses in the menu and copy them to the clipboard by clicking on them. The app also includes options to launch at startup and quit the application.

## Features

- Displays the current IP address in the macOS menu bar.
- Alternates between WAN and LAN IP addresses every 3 seconds.
- Shows both WAN and LAN IP addresses in the menu.
- Allows copying the IP addresses to the clipboard by clicking on the menu items.
- Option to launch the app at startup.
- Option to quit the application.

## Requirements

- macOS 10.15 or later
- Xcode 12 or later

## Installation

1. Clone the repository:

    ```bash
    git clone https://github.com/ihugang/myip.git
    cd myip
    ```

2. Open the project in Xcode:

    ```bash
    open myip.xcodeproj
    ```

3. Build and run the project in Xcode.

## Usage

Once the application is running, you will see an icon in the macOS menu bar displaying your current IP address. The IP address will alternate between WAN and LAN every 3 seconds. 

Right-click on the icon to see the menu with the following options:

- **WAN IP**: Displays the WAN IP address. Click to copy the IP address to the clipboard.
- **LAN IP**: Displays the LAN IP address. Click to copy the IP address to the clipboard.
- **Launch at Startup**: Toggle the option to launch the application at startup.
- **Quit**: Quit the application.

## Code Overview

### AppDelegate.swift

The main logic of the application is implemented in the `AppDelegate.swift` file. Key functionalities include:

- `applicationDidFinishLaunching`: Sets up the status item and menu, initializes the IP addresses, and starts the timer.
- `toggleIPAddress`: Alternates between displaying WAN and LAN IP addresses.
- `checkAndUpdateIP`: Checks for IP address changes and updates the display if necessary.
- `getExternalIPAddress`: Fetches the external IP address using the `https://api.ipify.org` service.
- `getLocalIPAddress`: Fetches the local IP address (IPv4 only).
- `setupMenu`: Sets up the menu items.
- `updateMenu`: Updates the menu with the current IP addresses.
- `copyWanIP` and `copyLanIP`: Copies the respective IP addresses to the clipboard.
- `toggleLaunchAtStartup`: Toggles the option to launch the app at startup.
- `quitApp`: Quits the application.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Author

- [Hu Gang](https://github.com/ihugang)
