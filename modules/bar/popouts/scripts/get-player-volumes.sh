#!/bin/sh
for p in $(playerctl -l 2>/dev/null); do
  case "$p" in
  brave*)
    idx=$(pactl list sink-inputs | awk '
        /^Sink Input #/ { gsub("#","",$3); idx=$3 }
        /application\.name = "Brave"/ { print idx; exit }
      ')
    if [ -n "$idx" ]; then
      pct=$(pactl list sink-inputs | awk -v target="$idx" '
          /^Sink Input #/ { gsub("#","",$3); cur=$3 }
          cur == target && /Volume:/ { print; exit }
        ' | grep -oP '\d+(?=%)' | head -1)
      v=$(awk "BEGIN{printf \"%.4f\", ${pct:-100}/100}")
    else
      v=1
    fi
    ;;
  *)
    v=$(playerctl --player="$p" volume 2>/dev/null || echo 0)
    ;;
  esac
  echo "$p:$v"
done
