import mqtt
import ble
import ntp
import monitor
import encoding.json
import esp32 show mac-address
import esp32 show adjust-real-time-clock
import .ble_utils
import .ruuvi_data

DEVICE_NAME               := "Ruuvi 4D1B" //"COLMI_R12_4503" //"R09_0803"
ruuvi_data/RuuviData      := RuuviData
md_prev/ByteArray         := #[]
adapter/ble.Adapter?      := null
scan-task                 := null
scan_running/bool         := false
latch_/monitor.Latch      := monitor.Latch
esp32_mac_address_/string := ""
data_str/string           := ""
ble_rssi/int              := 0
ble_mac/string            := ""

//  MQTT  ───────────────────────────────────────────────────────────────
CLIENT-ID               ::= "toit-client"
HOST                    ::= "broker.hivemq.com" // "test.mosquitto.org"
INP_TOPIC               ::= "ble_inp/topic"
OUT_TOPIC               ::= "ble_out/topic"
mqtt-client/mqtt.Client? := null
//  MQTT  ───────────────────────────────────────────────────────────────

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
  md/ByteArray? := null
  scan-task = task:: 

   try :
      e := catch --trace=false :    
        print "BLE device '$DEVICE_NAME' monitoring has started"
        adapter.central.scan : | device/ble.RemoteScannedDevice |
          ble_rssi = device.rssi  
          md = device.data.manufacturer-specific: | company-id data | company-id + data 
          parseRuuvi md
      if e :
        exceptionWasDetected "Monitoring Exception" e.stringify
        send_error "Monitoring exception" scan_running DEVICE_NAME
    finally :

final-scan :
  if scan-task :
    scan-task.cancel
    scan-task = null
    scan_running = false
    print "BLE device '$DEVICE_NAME' monitoring has finished"

is-scanning -> bool :
  return scan_running

main:

  esp32_mac_address_ = conv-to-mac-address mac-address
  print "esp32_mac_address-> [$esp32_mac_address_]"

  sync-time

  adapter = ble.Adapter

  mqtt-client = connect_mqtt HOST CLIENT-ID
  if mqtt-client == null :
    print "======= App exit because fatal error ======="
    exit 0
  
  task:: catch_shutdown


parseRuuvi md/ByteArray? -> none :
  if not md :
    return
  if md.is-empty :
    return
  if md == md_prev :
    return  
  rc/bool := ruuvi_data.update md
  if not rc :
    return
  md_prev = md

  s_data/Map := ruuvi_data.map {"ble_name" : DEVICE_NAME, "transmitter_type" : "esp32", "transmitter_mac": esp32_mac_address_, "rssi": ble_rssi}
  //print "s_data->$s_data"
  send_data s_data

send_data data_map/Map :
  data_str = json.stringify data_map
  print "send_data->($data_str)"
  publish mqtt-client data_str

resend_data data_str/string :
  print "resend_data->($data_str)"
  publish mqtt-client data_str

send_error error_message/string scan_state/bool ble_device_name/string :
  command-map/Map     := {"error": error_message, "scan_state": scan_state, "ble_name": ble_device_name}
  command-str/string  := json.stringify command-map
  publish mqtt-client command-str

send_ack esp32uuid/string command/string :  
  command-map/Map     := {"ack": command, "transmitter_mac": esp32uuid, "transmitter_type": "esp32", "scan": scan_running }
  command-str/string  := json.stringify command-map
  publish mqtt-client command-str

publish client/mqtt.Client message :
  task::
    try :
      e := catch --trace=false :    
        client.publish OUT_TOPIC message
      if e :
        exceptionWasDetected "Publish Exception" e.stringify
    finally :

exceptionWasDetected place/string exception/string -> none :

  print "$place: $exception"

connect_mqtt host/string client_id/string -> any :

  error/bool := false
  client_ := null

  try :

    e := catch --trace=false :
//  Create MQTT-client 
      client_ = mqtt.Client --host=host --routes={
        INP_TOPIC: :: | topic payload |
          print "Received: $topic: $payload.to-string-non-throwing"
          processing topic payload
      }

//  Connect to broker
      client_.start --client-id=client_id
        --on-error=:: print "Client error: $it"
    if e :
      error = true
      exceptionWasDetected "Connect Exception" e.stringify

  finally :
    if error :
      print "Connected to MQTT broker $host failed"
    else :
      print "Connected to MQTT broker $host"
    return client_  

processing topic/string payload/ByteArray -> none :

  command/string := ""
  decoded/string := ""

  decoded = payload.to_string
        
  print "Received message on '$topic': $decoded"

  map/Map     := json.parse decoded
  hasCmd/bool := map.contains "command"

  if hasCmd :
    command = map["command"]
    if DEVICE_NAME.is-empty :
      DEVICE_NAME = map["data"]
    processing_commands command


processing_commands command/string -> none :

  error/string := ""

  if command == "sync"   :
    print "> sync"
    send_ack esp32_mac_address_ command
    resend_data data_str

  if command == "start-scan"  :
    if scan_running :
      error = "Already inside-scan"
      send_ack esp32_mac_address_ command
      send_error error scan_running DEVICE_NAME
      return
    print "> start-scan"
    start_scan
    send_ack esp32_mac_address_ command

  if command == "final-scan"  :
    if not scan_running :
      error = "First send start_scan"
      send_error error scan_running DEVICE_NAME
      return
    print "> final-scan"
    send_ack esp32_mac_address_ command
    final_scan
    //send_ack esp32_mac_address_ command

  if command == "final-session" :
    send_ack esp32_mac_address_ command  
    if scan_running :
      print "> final-scan"
      final_scan
    sleep --ms=500  
    print "> final-session"
    //send_ack esp32_mac_address_ command
    sleep --ms=500
    //close-receiver
    latch_.set true

catch_shutdown :
  print "Wait shutdown..."
  latch_.get                          // ← wait signal
  print "Done shutdown"
  error := catch --trace=false :
    final_scan
  if error :
    print "***!*** $error ***!***" 
  if mqtt-client :   
    mqtt-client.close
