# SiSa-Scan Auswerte-Software
---
## Installation
### Binaries
Die Binary-Versionen sollten immer einigermaßen stabil sein, enthalten aber im 
Allgemeinen nicht die neusten Features und Bugfixes.

- Ist die MATLAB Compiler Runtime v8.4 (R2014b) nicht installiert,
dann bitte den Installer von [hier](https://git.daten.tk/sebastian.pfitzner/sisa-scan-auswertung/raw/master/Deployment/SiSaScanAuswertung/for_redistribution/SiSaScanAuswertung_WebInstaller.exe)
herunterladen und ausführen.

- Andernfalls reicht es, den Inhalt [dieses](https://git.daten.tk/sebastian.pfitzner/sisa-scan-auswertung/tree/master/Deployment/SiSaScanAuswertung/for_redistribution_files_only)
Ordners abzuspeichern und die `SiSaScanAuswertung.exe` auszuführen.

### m-Files
Zum Installieren

- `git clone` in ein Verzeichnis
- oben rechts auf `Download zip` drücken und irgendwo entpacken

---
### Wichtig!
Matlab wurde mit Version R2014b auf ein neues Plot-Backend umgestellt. 
Bei Matlab R2014a lässt sich das neue Backend auch verwenden, indem Matlab mit 
`-hgVersion 2` ausgeführt wird.

Nach commit f32776dd wird nur noch mit dem neuen Backend entwickelt, also wird
die Software ohne diese Einstellung und/oder in alten Matlab-Versionen vermtl.
schrecklich aussehen. Die Funktionsfähigkeit sollte aber erhalten bleiben.

Die Binaries sind ab f79c56c3 mit R2014b kompiliert.

In [diesem](https://git.daten.tk/sebastian.pfitzner/sisa-scan-auswertung/tree/R2014a-kompatibel) 
Branch sind noch die alten hg1-kompatiblen Files und Binaries enthalten.