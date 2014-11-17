# SiSa-Scan Auswerte-Software

## Installation
Ist die MATLAB Compiler Runtime v8.3 (R2014a) oder MATLAB R2014a nicht installiert,
dann bitte den Installer von [hier](https://git.daten.tk/sebastian.pfitzner/sisa-scan-auswertung/blob/master/Deployment/SiSaScanAuswertung/for_redistribution/MyAppInstaller_web.exe)
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