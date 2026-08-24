# TOIT-MQTT-BLE-Ruuvi App

Below is a description of an application written in __Toit__ allows to receive information from the __Ruuvi Tag__ sensor and transmit it to any other application or group of applications using the __MQTT__.

<img width="1204" height="1600" alt="ruuvi" src="https://github.com/user-attachments/assets/6f41619c-1e7b-45a1-83ef-a527a54c5549" />

## General Prerequisites

Actually, I had three main reasons for creating this application:
1) The heatwave caused by Greta Thunberg's categorical refusal to promote the theory of global warming (GWT).
2) I simply wanted to see a true picture of the actual temperature, pressure, and humidity levels in and around my home. The meteorological service provides average information for the local area, but I value nuances.
3) My experience with __BLE__ gadgets is limited to healthcare devices, and I wanted to broaden my horizons.

## Technical Background

After some research, I settled on a temperature sensor from __Ruuvi__ (www.ruuvi.com). Bluetooth sensors like the __Ruuvi Tag__ are designed for monitoring temperature, humidity, and pressure in real time. More importantly, the company provides comprehensive information on the __Ruuvi Tag__ __BLE__ protocols: https://docs.ruuvi.com/communication/bluetooth-advertisements. This allows for the implementation of device identification and data access procedures for any platform. I'm interested the solving of the problem on __Toit language__ on the __ESP32-S3__ microcontroller. Maybe I'll was finally able to satisfy my curiosity.

## Main Protocols (Broadcast Advertisement Formats)

__Ruuvi Tags__ primarily use __BLE Advertising__ (beacon mode, one-to-many, connectionless). Data is transmitted in __Manufacturer Specific Data__ with __Manufacturer ID 0x0499__ (Ruuvi Innovations, in the packet as 0x9904). The format is determined by the first byte of the payload. __Data Format 5__ (RAWv2) includes: __temperature__, __humidity__, __pressure__, __accelerometer__ (X/Y/Z), __battery voltage__, __TX Power__, __motion counter__, sequence number, and __MAC address__: https://docs.ruuvi.com/communication/bluetooth-advertisements/data-format-5-rawv2. __RuuviTag__ doesn't require a connection to receive basic data. All four basic parameters plus battery are included in the __BLE Advertisement__.

## Main Application Modules

* __ruuvi_ble.toit__ - test application. Simply retrieves data from the sensor. Simulates the start and end of a scan, and stops the application.
* __mqtt_ruuvi_ble.toit__ - main application. Retrieves data from the sensor and transmits it further via the __MQTT__ layer. In this case, the data is displayed by the __GUI application__ on the mobile device.

## Utilities
* __ruuvi_data.toit__ - the __RuuviData__ class contains sensor parameters extracted from __Manufacturer Specific Data__. Note the parsing procedure: __update__.
* __ble_utils.toit__ - contains two functions:
      __time__ - represents __time__ __Toit__ class as a __string__
      __conv-to-mac-address__ - converts a __MAC address as a ByteArray__ to a text __string__.

## Additional Packages

The following packages must be installed for proper operation and launch of applications:
```
jag pkg install github.com/toitlang/pkg-ntp@v1
jag pkg install github.com/toitware/mqtt@v2
jag pkg install github.com/toitware/toit-cert-roots@v1
```

## One-time application launch

* ruuvi_ble:
```
micrcx@micrcx-desktop:~/toit/ruuvi_ble$ jag run -d midi ruuvi_ble.toit
Scanning for device with name: 'midi'
Running 'ruuvi_ble.toit' on 'midi' ...
ruuvi_ble.toit:32:35: warning: Deprecated 'AdvertisementData.manufacturer-data'. Use 'Advertisement.manufacturer-specific' instead
      md/ByteArray := device.data.manufacturer-data
                                  ^~~~~~~~~~~~~~~~~
Success: Sent 78KB code to 'midi' in 2.13s
micrcx@micrcx-desktop:~/toit/ruuvi_ble$
```
* mqtt_ruuvi_ble:
```
micrcx@micrcx-desktop:~/toit/ruuvi_ble$ jag run -d midi mqtt_ruuvi_ble.toit
Scanning for device with name: 'midi'
Running 'mqtt_ruuvi_ble.toit' on 'midi' ...
Success: Sent 111KB code to 'midi' in 3.13s
micrcx@micrcx-desktop:~/toit/ruuvi_ble$
```

If necessary, you can launch the monitor to visually evaluate the application's operation, for example, in the case of __ruuvi_ble__:
```
micrcx@micrcx-desktop:~/toit/ruuvi_ble$ jag monitor -p /dev/ttyACM1
Starting serial monitor of port '/dev/ttyACM1' ...
ESP-ROM:esp32s3-20210327
Build:Mar 27 2021
rst:0x15 (USB_UART_CHIP_RESET),boot:0x8 (SPI_FAST_FLASH_BOOT)
Saved PC:0x40387056
SPIWP:0xee
mode:DIO, clock div:1
load:0x3fce2810,len:0xe0
load:0x403c8700,len:0x4
load:0x403c8704,len:0xa40
load:0x403cb700,len:0x2658
entry 0x403c8860
[toit] INFO: starting <v2.0.0-alpha.196>
[toit] DEBUG: clearing RTC memory: powered on by hardware source
[toit] INFO: running on ESP32S3 - revision 0.2
[toit] INFO: using SPIRAM for heap metadata and heap
[wifi] DEBUG: connecting
E (3876) wifi:Association refused too many times, max allowed 1
[wifi] DEBUG: connected
[wifi] INFO: network address dynamically assigned through dhcp {ip: 192.168.1.153}
[wifi] INFO: dns server address dynamically assigned through dhcp {ip: [213.57.2.5, 213.57.22.5]}
[jaguar.http] INFO: running Jaguar device 'midi' (id: '64e5d4e2-ea47-45a2-9461-a40eb653f34e') on 'http://192.168.1.153:9000'
[jaguar] INFO: program 9406709d-98ba-ebe5-7b92-88e5f7d9e09a started
Set time to 2026-08-24T05:57:28.335557Z by adjusting 496541h4m0.158796658s
======= is scanning false =======
======= is scanning true =======
BLE device 'Ruuvi 4D1B' monitoring has started
{temperature: 27.19, humidity: 55.7, pressure: 983.52, accel-x: -0.02, accel-y: -0.016, accel-z: 0.988, battery-voltage: 3.069, tx-power: 4, movement-counter: 128, sequence: 16620, ble_mac: E4:64:E3:37:4D:1B, time: 2026/08/24 08:57:28.580, sensor: Ruuvi 4D1B}
{temperature: 27.195, humidity: 55.685, pressure: 983.54, accel-x: -0.02, accel-y: -0.008, accel-z: 0.98, battery-voltage: 3.069, tx-power: 4, movement-counter: 128, sequence: 16621, ble_mac: E4:64:E3:37:4D:1B, time: 2026/08/24 08:57:31.146, sensor: Ruuvi 4D1B}
{temperature: 27.205000000000002, humidity: 55.682500000000005, pressure: 983.53, accel-x: -0.016, accel-y: -0.02, accel-z: 0.984, battery-voltage: 3.069, tx-power: 4, movement-counter: 128, sequence: 16622, ble_mac: E4:64:E3:37:4D:1B, time: 2026/08/24 08:57:33.717, sensor: Ruuvi 4D1B}
{temperature: 27.205000000000002, humidity: 55.71, pressure: 983.5, accel-x: -0.02, accel-y: -0.02, accel-z: 0.984, battery-voltage: 3.069, tx-power: 4, movement-counter: 128, sequence: 16623, ble_mac: E4:64:E3:37:4D:1B, time: 2026/08/24 08:57:36.288, sensor: Ruuvi 4D1B}
{temperature: 27.21, humidity: 55.6975, pressure: 983.53, accel-x: -0.02, accel-y: -0.024, accel-z: 0.988, battery-voltage: 3.069, tx-power: 4, movement-counter: 128, sequence: 16624, ble_mac: E4:64:E3:37:4D:1B, time: 2026/08/24 08:57:38.857, sensor: Ruuvi 4D1B}
{temperature: 27.205000000000002, humidity: 55.6875, pressure: 983.55, accel-x: -0.012, accel-y: -0.016, accel-z: 0.988, battery-voltage: 3.069, tx-power: 4, movement-counter: 128, sequence: 16625, ble_mac: E4:64:E3:37:4D:1B, time: 2026/08/24 08:57:42.710, sensor: Ruuvi 4D1B}
{temperature: 27.195, humidity: 55.7025, pressure: 983.54, accel-x: -0.016, accel-y: -0.012, accel-z: 0.988, battery-voltage: 3.069, tx-power: 4, movement-counter: 128, sequence: 16626, ble_mac: E4:64:E3:37:4D:1B, time: 2026/08/24 08:57:45.286, sensor: Ruuvi 4D1B}
{temperature: 27.205000000000002, humidity: 55.6775, pressure: 983.56, accel-x: -0.016, accel-y: -0.02, accel-z: 0.98, battery-voltage: 3.069, tx-power: 4, movement-counter: 128, sequence: 16631, ble_mac: E4:64:E3:37:4D:1B, time: 2026/08/24 08:57:56.843, sensor: Ruuvi 4D1B}
BLE device 'Ruuvi 4D1B' monitoring has finished
======= is scanning false =======
======= is scanning false =======
======= is scanning true =======
BLE device 'Ruuvi 4D1B' monitoring has started
{temperature: 27.205000000000002, humidity: 55.7, pressure: 983.54, accel-x: -0.02, accel-y: -0.028, accel-z: 0.988, battery-voltage: 3.069, tx-power: 4, movement-counter: 128, sequence: 16634, ble_mac: E4:64:E3:37:4D:1B, time: 2026/08/24 08:58:04.561, sensor: Ruuvi 4D1B}
{temperature: 27.240000000000002, humidity: 55.7125, pressure: 983.54, accel-x: -0.02, accel-y: -0.004, accel-z: 0.98, battery-voltage: 3.069, tx-power: 4, movement-counter: 128, sequence: 16635, ble_mac: E4:64:E3:37:4D:1B, time: 2026/08/24 08:58:08.417, sensor: Ruuvi 4D1B}
{temperature: 27.205000000000002, humidity: 55.7075, pressure: 983.54, accel-x: -0.02, accel-y: -0.016, accel-z: 0.988, battery-voltage: 3.069, tx-power: 4, movement-counter: 128, sequence: 16636, ble_mac: E4:64:E3:37:4D:1B, time: 2026/08/24 08:58:10.983, sensor: Ruuvi 4D1B}
{temperature: 27.23, humidity: 55.7275, pressure: 983.57, accel-x: -0.016, accel-y: -0.024, accel-z: 0.976, battery-voltage: 3.069, tx-power: 4, movement-counter: 128, sequence: 16637, ble_mac: E4:64:E3:37:4D:1B, time: 2026/08/24 08:58:13.554, sensor: Ruuvi 4D1B}
{temperature: 27.23, humidity: 55.72, pressure: 983.53, accel-x: -0.016, accel-y: -0.016, accel-z: 0.988, battery-voltage: 3.069, tx-power: 4, movement-counter: 128, sequence: 16638, ble_mac: E4:64:E3:37:4D:1B, time: 2026/08/24 08:58:16.116, sensor: Ruuvi 4D1B}
{temperature: 27.215, humidity: 55.7025, pressure: 983.54, accel-x: -0.016, accel-y: -0.024, accel-z: 0.988, battery-voltage: 3.069, tx-power: 4, movement-counter: 128, sequence: 16639, ble_mac: E4:64:E3:37:4D:1B, time: 2026/08/24 08:58:18.687, sensor: Ruuvi 4D1B}
{temperature: 27.23, humidity: 55.71, pressure: 983.56, accel-x: -0.016, accel-y: -0.02, accel-z: 0.988, battery-voltage: 3.069, tx-power: 4, movement-counter: 128, sequence: 16642, ble_mac: E4:64:E3:37:4D:1B, time: 2026/08/24 08:58:25.115, sensor: Ruuvi 4D1B}
{temperature: 27.240000000000002, humidity: 55.715, pressure: 983.56, accel-x: -0.016, accel-y: -0.016, accel-z: 0.98, battery-voltage: 3.069, tx-power: 4, movement-counter: 128, sequence: 16643, ble_mac: E4:64:E3:37:4D:1B, time: 2026/08/24 08:58:27.684, sensor: Ruuvi 4D1B}
{temperature: 27.22, humidity: 55.725, pressure: 983.55, accel-x: -0.024, accel-y: -0.02, accel-z: 0.984, battery-voltage: 3.069, tx-power: 4, movement-counter: 128, sequence: 16644, ble_mac: E4:64:E3:37:4D:1B, time: 2026/08/24 08:58:30.258, sensor: Ruuvi 4D1B}
BLE device 'Ruuvi 4D1B' monitoring has finished
======= is scanning false =======
[jaguar] INFO: program 9406709d-98ba-ebe5-7b92-88e5f7d9e09a stopped

```
## Using containers

Toit allows to install an application on the ESP32-S3 so that it will automatically launch every time the ESP32 boots (including power-up, charging, or power-on reset). Below is an example of preparing the chip for operation and installing the application as a container:
```
micrcx@micrcx-desktop:~/toit/ruuvi_ble$ jag flash -c esp32s3 --name ruuvi -p /dev/ttyACM1 --wifi-ssid <wifi-ident> --
wifi-password <wifi-password>
Flashing device over serial on port '/dev/ttyACM1' ...
esptool v5.1.0
Connected to ESP32-S3 on /dev/ttyACM1:
Chip type:          ESP32-S3 (QFN56) (revision v0.2)
Features:           Wi-Fi, BT 5 (LE), Dual Core + LP Core, 240MHz, Embedded Flash 4MB (XMC), Embedded PSRAM 2MB (AP_3v3)
Crystal frequency:  40MHz
USB mode:           USB-Serial/JTAG
MAC:                10:20:ba:31:2d:c4

Stub flasher running.
Changing baud rate to 921600...
Changed.

Configuring flash size...
Flash will be erased from 0x00000000 to 0x00003fff...
Flash will be erased from 0x00008000 to 0x00008fff...
Flash will be erased from 0x0000d000 to 0x0000efff...
Flash will be erased from 0x00010000 to 0x00191fff...
SHA digest in image updated.
Wrote 12768 bytes (8970 compressed) at 0x00000000 in 0.3 seconds (387.5 kbit/s).
Hash of data verified.
Wrote 4096 bytes (171 compressed) at 0x00008000 in 0.0 seconds (688.2 kbit/s).
Hash of data verified.
Wrote 8192 bytes (31 compressed) at 0x0000d000 in 0.1 seconds (756.8 kbit/s).
Hash of data verified.
Wrote 1579488 bytes (998473 compressed) at 0x00010000 in 15.5 seconds (812.7 kbit/s).
Hash of data verified.

Hard resetting via RTS pin...
micrcx@micrcx-desktop:~/toit/ruuvi_ble$ jag container -d ruuvi install sensor mqtt_ruuvi_ble.toit
Scanning for device with name: 'ruuvi'
Installing container 'sensor' from 'mqtt_ruuvi_ble.toit' on 'ruuvi' ...
Success: Sent 111KB code to 'ruuvi' in 2.91s
micrcx@micrcx-desktop:~/toit/ruuvi_ble$ 
```
## Three-party app

Hereinafter, a short video demonstrating the __GUI__ app's operation, displaying sensor information:

https://github.com/user-attachments/assets/4cddfbdd-0ed0-47fd-97c1-e88869990d88







