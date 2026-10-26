#!/bin/sh
# NMEA-Prüfsumme berechnen (läuft mit BusyBox ash auf OpenWrt).
# Aufruf ohne $ und ohne *:
#   ./nmea-checksum.sh "PQTMCFGSVIN,W,2,0,0,3800000.1234,700000.1234,5000000.1234"
# Ausgabe: fertige Zeile für lc29h.cmd

s="$1"
[ -z "$s" ] && { echo "Aufruf: $0 \"PQTMCFGSVIN,W,2,0,0,X,Y,Z\""; exit 1; }
c=0
i=0
while [ $i -lt ${#s} ]; do
  ch=$(printf '%s' "$s" | cut -c$((i+1)))
  c=$(( c ^ $(printf '%d' "'$ch") ))
  i=$((i+1))
done
printf '$%s*%02X\n' "$s" "$c"
