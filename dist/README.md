# WiFi Optimizer - Distribution Package

A powerful WiFi network analyzer and optimizer for macOS that can display real WiFi network names and provide channel recommendations.

## What's Included

- **wifiopt-cli**: Command-line tool for continuous WiFi monitoring
- **wifiopt-app**: SwiftUI application with graphical interface

## Features

✅ **Real SSID Names**: Uses system profiler to bypass macOS sandboxing restrictions  
✅ **Complete Network Info**: Signal strength, noise, SNR, channels, bands, security  
✅ **Channel Recommendations**: AI-powered suggestions for optimal WiFi performance  
✅ **Real-time Monitoring**: Live updates every 3 seconds  
✅ **Band Filtering**: Filter by 2.4GHz, 5GHz, or 6GHz bands  

## Usage

### Command Line Tool

```bash
# Show all networks
./wifiopt-cli

# Filter by band
./wifiopt-cli 2.4    # 2.4GHz only
./wifiopt-cli 5      # 5GHz only  
./wifiopt-cli 6      # 6GHz only
```

### GUI Application

```bash
# Launch the SwiftUI app
./wifiopt-app
```

The app will be available at http://localhost:8080

## Sample Output

```
Time                    SSID            BSSID           RSSI    Noise   SNR     Channel Band    Width   Security
2025-10-13T13:40:03Z    haha            haha            -63     -81     18      3       2.4 GHz 20      WPA2 Personal
2025-10-13T13:40:03Z    801             801             -84     -96     12      36      5 GHz   160     WPA2 Personal
2025-10-13T13:40:03Z    张鑫-WiFi5      张鑫-WiFi5      -87     -96     9       44      5 GHz   160     WPA/WPA2 Personal
```

## System Requirements

- macOS 13.0 or later
- No additional permissions required (uses system profiler)

## Technical Details

This tool works by parsing the output of `system_profiler SPAirPortDataType`, which allows it to access WiFi network information without requiring location permissions or dealing with CoreWLAN sandboxing restrictions.

## Installation

Simply copy the binaries to your desired location and run them directly. No installation required.