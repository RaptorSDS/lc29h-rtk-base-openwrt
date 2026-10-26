# LC29H RTK-Basisstation unter OpenWrt

Eine Quectel **LC29H (BS)** als RTK-Basisstation an einem OpenWrt-Router betreiben und die
Korrekturdaten mit RTKLIB `str2str` an einen NTRIP-Caster (z. B. [rtk2go.com](http://rtk2go.com)) senden.
Diese Konfiguration läuft im Dauerbetrieb seit Monaten stabil.

## Was man braucht
- LC29H (BS) per USB-Seriell am Router (hier `/dev/ttyUSB0`, 115200 Baud)
- OpenWrt mit `str2str` (RTKLIB)
- Geodätische / gute L1/L5-Antenne mit freier Sicht
- Bekannte Antennenposition in ECEF (X/Y/Z in Metern)

## Dateien
| Datei | Ziel auf dem Router | Zweck |
|---|---|---|
| `rtk-start.sh` | z. B. aus `/etc/rc.local` aufrufen | startet str2str |
| `lc29h.cmd` | `/lc29h.cmd` | Befehle, die str2str beim Start an das Modul sendet |
| `nmea-checksum.sh` | beliebig | berechnet die `*XX`-Prüfsumme für eigene Befehle |

## Einrichtung
1. In `rtk-start.sh` Zugangsdaten, Caster und Mountpoint eintragen.
2. In `lc29h.cmd` die Zeile `PQTMCFGSVIN` mit der eigenen ECEF-Position füllen und die Prüfsumme neu berechnen:
   ```sh
   ./nmea-checksum.sh "PQTMCFGSVIN,W,2,0,0,3800000.1234,700000.1234,5000000.1234"
   ```
   Die Ausgabe ersetzt die Platzhalterzeile.
3. Dateien auf den Router kopieren, `rtk-start.sh` ausführbar machen und in `/etc/rc.local` vor `exit 0` eintragen:
   ```sh
   /root/rtk-start.sh
   ```

## Was die Befehle machen
| Befehl | Wirkung |
|---|---|
| `PQTMCFGRCVRMODE,W,2` | Base-Modus |
| `PQTMCFGSVIN,W,2,0,0,X,Y,Z` | feste Basisposition (ECEF) |
| `PAIR432,1` | RTCM MSM7 (`PAIR432,0` = MSM4) |
| `PAIR434,1` | 1005 Antennenposition |
| `PAIR436,1` | Ephemeriden 1019/1020/1042/1046 |
| `PAIR062,0,1` / `PAIR062,1..8,0` | nur GGA an, übrige NMEA aus |
| `PQTMSAVEPAR` | Parameter speichern |
| `PQTMHOT` | Hotstart |

Ergebnis im Caster (Beispiel):
```
RTCM 3.3; 1005(1), 1019(1), 1020(1), 1042(1), 1046(1), 1077(1), 1087(1), 1097(1), 1117(1), 1127(1)
GPS+GLO+GAL+QZSS+BeiDou
```

## Einschränkungen des LC29H (BS)
- Alle RTCM-Nachrichten kommen fest mit 1 Hz, die Rate pro Nachricht ist nicht einstellbar.
- Kein 1006, 1033, 1230 und keine Legacy-Nachrichten (1004/1012).
- Sendet nur L1/L5 – Rover, die L2 erwarten (z. B. u-blox F9P), profitieren weniger.
- Werkseinstellungen: `$PQTMRESTOREPAR*13`, danach alles neu setzen und speichern.

## Lizenz
MIT

## Variante: eigene Intervalle wie bei einer F9P-Base (`rtk-start-msg.sh`)
Der LC29H selbst kann die Raten nicht ändern, aber `str2str` kann den Stream dekodieren und neu
kodieren. Dafür bekommt die NTRIP-Ausgabe das Suffix `#rtcm3`, die Liste davor steht in `-msg`:

```
1005(10),1033(10),1077(1),1087(1),1097(1),1117(1),1127(1),1019(2),1020(2),1042(2),1046(2)
```

- Beobachtungen/Station (1005, 1033, MSM): Zahl in Klammern = Intervall in Sekunden.
- Ephemeriden (1019/1020/1042/1046): **ein Satellit pro Intervall**, reihum. `1019(2)` = alle 2 s ein GPS-Satellit.
  Ohne Klammer werden sie einfach weitergereicht, sobald das Modul sie sendet.
- Der TCP-Server ohne `#rtcm3` liefert weiter den unveränderten Original-Stream – praktisch zum Vergleichen.

Wichtig:
- **`-sta` muss gesetzt und ungleich 0 sein.** Sonst übernimmt str2str die Stationsdaten aus der
  1005 des Moduls und verwirft `-px`, `-a` und `-i` – im Test kam dann 1005 mit Position 0/0/0 heraus.
- `-px` = dieselbe ECEF-Position wie in `PQTMCFGSVIN`.
- `-a "IGS-NAME RADOME,Seriennummer,0"` – Antennenname möglichst nach IGS-Liste (z. B. `ADVNULLANTENNA NONE` für unbekannt).
- 1230 (GLONASS-Biases) bewusst weggelassen: der LC29H liefert keine Biaswerte, str2str würde Nullen senden.
- Vor dem Test die laufende Instanz beenden (`killall str2str`), die serielle Schnittstelle kann nur einmal geöffnet werden.
- Getestet mit **RTKLIB 2.4.3 b34** (das ist die Version im OpenWrt-Paket `str2str`) und demo5 EX 2.5.1 –
  gleiches Ergebnis. `-msg` vor die `-out`-Angaben setzen.
- Alle LC29H-Signale (L1 + L5/E5a/B2a) bleiben beim Neukodieren erhalten, solange str2str mit
  mindestens 3 Frequenzen gebaut ist (Standard).
- Firmware-Angabe: `LC29HBSNR11A01S` (2023/02/13) ist die einzige öffentlich dokumentierte BS-Version,
  eigene Version mit `$PQTMVERNO*58` prüfen.

## Autostart über `/etc/rc.local`
`rc.local` enthält den kompletten str2str-Aufruf (Variante mit eigenen Intervallen) zum direkten Einfügen in
`/etc/rc.local` auf OpenWrt (LuCI: System → Startup → Local Startup). `/lc29h.cmd` muss trotzdem vorhanden sein.
Der Aufruf läuft in `( sleep 5; ... ) &`, damit der Bootvorgang nicht wartet.
