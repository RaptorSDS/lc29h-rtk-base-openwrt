#!/bin/sh
# TESTVARIANTE: str2str baut den RTCM-Stream neu auf, mit eigenen Intervallen pro Nachricht
# und 1033 (Antenne/Empfänger) – ähnlich einer u-blox-F9P-Base.
# Vor dem Start die alte Instanz beenden:  killall str2str
#
# NTRIP-Ausgabe (#rtcm3)  -> umkodiert nach -msg
# TCP-Server              -> unverändert der Original-Stream vom LC29H (zum Vergleichen)

TTY="ttyUSB0"
BAUD="115200"
NTRIP_USER="DEINE_EMAIL"
NTRIP_PASS="DEIN_PASSWORT"
CASTER="rtk2go.com:2101"
MOUNTPOINT="MEIN_MOUNTPOINT"
CMDFILE="/lc29h.cmd"
TCP_PORT="9000"
LOG="/var/log/str2str.log"

STA_ID="1"                          # 1..4095, muss != 0 sein (siehe README)
POS_ECEF="X.XXXX Y.YYYY Z.ZZZZ"     # gleiche Werte wie in PQTMCFGSVIN
ANT="ANTENNENTYP,,0"                # IGS-Antennenname, Seriennummer, Setup-ID
RCV="Quectel LC29H(BS),FIRMWARE,"   # Empfängertyp, Firmware ($PQTMVERNO), Seriennummer
MSGS="1005(10),1033(10),1077(1),1087(1),1097(1),1117(1),1127(1),1019(2),1020(2),1042(2),1046(2)"

# Warten, bis USB-TTY verfügbar ist (optional)
sleep 5

# shellcheck disable=SC2086
str2str -in "serial://${TTY}:${BAUD}#rtcm3" \
  -c "${CMDFILE}" \
  -sta "${STA_ID}" \
  -px ${POS_ECEF} \
  -a "${ANT}" -i "${RCV}" \
  -msg "${MSGS}" \
  -out "ntrips://${NTRIP_USER}:${NTRIP_PASS}@${CASTER}/${MOUNTPOINT}#rtcm3" \
  -out "tcpsvr://:${TCP_PORT}/${MOUNTPOINT}" \
  >> "${LOG}" 2>&1 &
