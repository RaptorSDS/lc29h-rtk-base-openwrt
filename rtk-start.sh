#!/bin/sh
# LC29H RTK-Basisstation unter OpenWrt: RTCM vom Modul per str2str an einen NTRIP-Caster senden.
# Werte unten anpassen.

TTY="ttyUSB0"                 # serielles Gerät des LC29H
BAUD="115200"
NTRIP_USER="DEINE_EMAIL"      # rtk2go: E-Mail-Adresse
NTRIP_PASS="DEIN_PASSWORT"
CASTER="rtk2go.com:2101"
MOUNTPOINT="MEIN_MOUNTPOINT"
CMDFILE="/lc29h.cmd"          # Befehle, die beim Start an das Modul gehen
TCP_PORT="9000"               # lokaler TCP-Server (optional)
LOG="/var/log/str2str.log"

# Warten, bis USB-TTY verfügbar ist (optional)
sleep 5

# RTK starten
str2str -in "serial://${TTY}:${BAUD}#rtcm3" \
  -out "ntrips://${NTRIP_USER}:${NTRIP_PASS}@${CASTER}/${MOUNTPOINT}" \
  -c "${CMDFILE}" \
  -out "tcpsvr://:${TCP_PORT}/${MOUNTPOINT}" \
  >> "${LOG}" 2>&1 &
