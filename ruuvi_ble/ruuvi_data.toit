import io show BIG-ENDIAN
import .ble_utils

class RuuviData :

  temperature       /float? := null // °C
  humidity          /float? := null // %
  pressure          /float? := null // hPa
  accel-x           /float? := null // g
  accel-y           /float? := null
  accel-z           /float? := null
  battery-voltage   /float? := null // V
  tx-power          /int?   := null // dBm
  movement-counter  /int?   := null
  sequence          /int?   := null
  mac               /string := ""

  update data/ByteArray -> bool :
    if not (data.size >= 26) :
      return false
    if not (data[0] == 0x99 and data[1] == 0x04) :
      return false
    if not (data[2] == 0x05) :
      return false

    // Temperature (signed int16, 0.005 °C)
    temp-raw := BIG-ENDIAN.int16 data 3
    if temp-raw != -32768 :
      temperature = temp-raw * 0.005

    // Humidity (uint16, 0.0025 %)
    hum-raw := BIG-ENDIAN.uint16 data 5
    if hum-raw != 0xFFFF :
      humidity = hum-raw * 0.0025

    // Pressure (uint16 + 50000 Pa → hPa)
    press-raw := BIG-ENDIAN.uint16 data 7
    if press-raw != 0xFFFF:
      pressure = (press-raw + 50000) / 100.0

    // Acceleration (mG → G)
    ax := BIG-ENDIAN.int16 data 9
    ay := BIG-ENDIAN.int16 data 11
    az := BIG-ENDIAN.int16 data 13
    if ax != -32768 : 
      accel-x = ax / 1000.0
    if ay != -32768 :
      accel-y = ay / 1000.0
    if az != -32768 :
      accel-z = az / 1000.0
          
    // Power info
    power := BIG-ENDIAN.uint16 data 15
    batt-raw := (power >> 5) & 0x7FF
    if batt-raw != 0x7FF :
      battery-voltage = (batt-raw + 1600) / 1000.0

    tx-raw := power & 0x1F
    if tx-raw != 0x1F :
      tx-power = tx-raw * 2 - 40

    // Movement counter
    mov := data[17]
    if mov != 0xFF :
      movement-counter = mov

    // Sequence number
    seq := BIG-ENDIAN.uint16 data 18
    if seq != 0xFFFF :
      sequence = seq

    // MAC (bytes 20..25)
    mac = "$(%02x data[20]):$(%02x data[21]):$(%02x data[22]):$(%02x data[23]):$(%02x data[24]):$(%02x data[25])".to-ascii-upper

    return true

  map ext/Map -> Map :
    
    result/Map := {:}

    result["temperature"]       = temperature
    result["humidity"]          = humidity
    result["pressure"]          = pressure  
    result["accel-x"]           = accel-x
    result["accel-y"]           = accel-y
    result["accel-z"]           = accel-z
    result["battery-voltage"]   = battery-voltage
    result["tx-power"]          = tx-power
    result["movement-counter"]  = movement-counter
    result["sequence"]          = sequence
    result["ble_mac"]           = mac
    result["time"]              = time
    
    ext.do : | key value |
      result[key] = value

    return result
