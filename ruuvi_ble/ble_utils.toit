time -> string :
  time := Time.now + (Duration --h=3)
  ms := time.local.ns / Duration.NANOSECONDS_PER_MILLISECOND
  precise_ms := "$(%04d time.local.year)/$(%02d time.local.month)/$(%02d time.local.day) $(%02d time.local.h):$(%02d time.local.m):$(%02d time.local.s).$(%03d ms)"
  return precise_ms

conv-to-mac-address data/ByteArray -> string :
  result/string := "$(%02x data[0]):$(%02x data[1]):$(%02x data[2]):$(%02x data[3]):$(%02x data[4]):$(%02x data[5])".to-ascii-upper
  return result