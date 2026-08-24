import ble
import ntp
import esp32 show adjust-real-time-clock
import .ble_utils
import .ruuvi_data

DEVICE_NAME          ::= "Ruuvi 4D1B" //"COLMI_R12_4503" //"R09_0803"
ruuvi_data/RuuviData  := RuuviData
md_prev/ByteArray     := #[]
adapter/ble.Adapter?  := null
scan-task             := null
scan_running/bool     := false

sync_time :
  now := Time.now
  if now < (Time.parse "2022-01-10T00:00:00Z"):
    result ::= ntp.synchronize
    if result:
      adjust-real-time-clock result.adjustment
      print "Set time to $Time.now by adjusting $result.adjustment"
    else:
      print "ntp: synchronization request failed"
  else:
    print "We already know the time is $now"

start-scan :
  scan_running = true
  scan-task = task:: 
    print "BLE device '$DEVICE_NAME' monitoring has started"
    adapter.central.scan : | device/ble.RemoteScannedDevice |
      md/ByteArray := device.data.manufacturer-data
      parseRuuvi md

final-scan :
  if scan-task :
    scan-task.cancel
    scan-task = null
    scan_running = false
    print "BLE device '$DEVICE_NAME' monitoring has finished"

is-scanning -> bool :
  return scan_running

main:

  sync-time

  adapter = ble.Adapter

  print "======= is scanning $is-scanning ======="

  start_scan

  print "======= is scanning $is-scanning ======="

  sleep (Duration --s=30)

  final_scan

  print "======= is scanning $is-scanning ======="

  sleep (Duration --s=5)


  print "======= is scanning $is-scanning ======="

  start_scan

  print "======= is scanning $is-scanning ======="

  sleep (Duration --s=30)
  final_scan

  print "======= is scanning $is-scanning ======="


parseRuuvi md/ByteArray -> none :
  if md.is-empty :
    return
  if md == md_prev :
    return  
  rc/bool := ruuvi_data.update md
  if not rc :
    return
  md_prev = md

  print "$(ruuvi_data.map {"sensor" : DEVICE_NAME })" 

