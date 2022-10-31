# Cradlepoint WAN Emulator

This script will configure a Raspberry Pi as a WAN emulator, running a Cradlepoint themed web interface for configuration.

This script assumes the following:
1. You have two wired Ethernet interfaces for the WAN Emulator. You will need a USB Ethernet Adapter compatible with the Raspberry Pi
2. You will be using WLAN0 for access to the web interface, and WLAN0 is already configured.
3. The Raspberry Pi has apt installed

This script will:
* Install iproute2, which contains **tc** for adding delay, loss, jitter.
* Install lighttpd as the web server, and enable access logging
* Grab the latest files from GitHub and extract them to /var/www/html
* Configure a network bridge between the two Ethernet interfaces
* (Optionally) set cron jobs to alternate between clean and degraded performance on the network bridge

To install, simply run this command:

```
wget https://raw.githubusercontent.com/nathanwiens/cp-wanemulator/main/install.sh && chmod a+x install.sh && sudo ./install.sh
```

You can either cycle the WAN Emulation automatically (via cron job), or set it manually via the web interface.
Thresholds for the cron job can be modified by editing the scripts in /var/www/html/cron after installation.

Here's what the interface looks like:
![alt text](https://github.com/nathanwiens/cp-wanemulator/blob/1ee24d80c8ef6e750b76a6c8b4b14b6830c64d13/wanemulator.png)
