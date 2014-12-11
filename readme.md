# SiSa-Scan Auswerte-Software

## Installation
Ist die MATLAB Compiler Runtime v8.4 (R2014b) nicht installiert,
dann bitte den Installer von [hier](https://git.daten.tk/sebastian.pfitzner/sisa-scan-auswertung/raw/master/Deployment/SiSaScanAuswertung/for_redistribution/MyAppInstaller_web.exe)
herunterladen und ausführen.

Andernfalls reicht es, den Inhalt [dieses](https://git.daten.tk/sebastian.pfitzner/sisa-scan-auswertung/tree/master/Deployment/SiSaScanAuswertung/for_redistribution_files_only)
Ordners abzuspeichern und die `SiSaScanAuswertung.exe` auszuführen.

## Kurzanleitung

1. öffne HDF5-File
2. klicke auf Datenpunkte, um die Messdaten angezeigt zu bekommen
3. setze dort den Nullpunkt und die zu fittenden Daten und klicke auf `globalisieren`, um diese Einstellungen überall zu übernehmen
4. fitte die Daten probeweise in der Detailansicht und lege ein passendes Fitmodell fest
5. lege anhand der abgeschätzten Parameter eine Auswahl zum Fitten fest (mit der `Overlay`-Checkbox)
6. passe, falls nötig, obere und untere Grenzen an
7. fitte alle selektierten Daten

Für Fehler und wünsche bitte unbedingt ein Issue öffnen!

### Wichtig!
Matlab wurde mit Version R2014b auf ein neues Plot-Backend umgestellt. Dieses ist
wohl allgemein viel toller und behebt bei dieser Software viele Anzeigefehler.
Bei Matlab R2014a lässt sich das neue Backend auch verwenden, indem Matlab mit 
`-hgVersion 2` ausgeführt wird.

Nach commit f32776dd wird nur noch mit dem neuen Backend entwickelt, also wird
die Software ohne diese Einstellung und/oder in alten Matlab-Versionen vermtl.
schrecklich aussehen. Die Funktionsfähigkeit sollte aber erhalten bleiben.

Die Binaries sind ab Basti f79c56c3 mit R2014b kompiliert.