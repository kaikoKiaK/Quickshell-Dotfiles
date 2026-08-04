#!/bin/sh
ddcutil detect --brief 2>/dev/null | awk '
/I2C bus:/ { bus = $3; sub(".*i2c-", "", bus) }
/Monitor:/ {
  line = $0
  sub("^[ \t]*Monitor:[ \t]*", "", line)
  gsub("[ \t]*$", "", line)
  if (bus != "") print bus "|" line
  bus = ""
}
' | while IFS='|' read -r bus name; do
  [ -z "$bus" ] && continue
  echo "$bus|$name"
  ddcutil --bus="$bus" capabilities 2>/dev/null | awk -v b="$bus" '
    /Feature: 60/ { inInput = 1; next }
    inInput && /^[[:space:]]*Feature:/ { exit }
    inInput && /Values:/ { inValues = 1; next }
    inValues && /^[[:space:]]+[0-9a-fA-F]{2}:/ {
      line = $0
      sub(/^[[:space:]]+/, "", line)
      hex = substr(line, 1, 2)
      sub(/^[0-9a-fA-F]{2}:[[:space:]]*/, "", line)
      sub(/[[:space:]]+$/, "", line)
      print "input|" b "|" hex "|" line
      next
    }
  '
done
