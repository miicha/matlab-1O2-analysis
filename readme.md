# Copy from private Gitlab instance
for latest/original/development version [see here](https://www.git.daten.tk/sebastian.pfitzner/sisa-scan-auswertung)
- submodules need to be fixed on github

## SiSa-Scan Auswerte-Software
---
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;  ![screen](side/screen.png)

Mit dieser Software lassen sich die an den Scanning-Messplätzen gewonnen Datensätze
und auch generische `*.diff`s leicht auswerten und in ansprechendem Format visualisieren.

### Installation
#### Binaries

- Achtung: Binaries aus Repo entfernt, sollten eher bei den Versionen extra hochgeladen werden (hoffentlich alle exe reste entfernt)

Die Binary-Versionen sollten immer einigermaßen stabil sein, enthalten aber im 
Allgemeinen nicht die neusten Features und Bugfixes.

- Ist die MATLAB Compiler Runtime v9.3 (R2017b) nicht installiert,
dann bitte den [64-bit Installer R2017b (9.3)](http://de.mathworks.com/products/compiler/mcr/index.html)
herunterladen und ausführen. Dann mit dem nächsten Schritt weiter machen.

- Andernfalls reicht es, den Inhalt [diese exe](https://www.git.daten.tk/sebastian.pfitzner/sisa-scan-auswertung/raw/master/Deployment/SiSaScanAuswertung.exe)
herunterzuladen und auszuführen.

#### m-Files
Zum Installieren
entweder:
- `git clone` in ein Verzeichnis
- danach `git submodule update`

oder:
- oben rechts auf `Download zip` drücken und irgendwo entpacken
- und außerdem noch die submodule einzeln laden und in den entpsrechenden Ordner entpacken

und dann `startUI` (im Verzeichnis 'src') ausführen.

### Hinweise

- Der state des gerade laufenden Programms lässt sich mit `Datei`->`State speichern`
speichern und über `Datei`->`Datei öffnen...` wieder laden. Dabei wird allerdings
die gerade laufende Version der Software mitgespeichert, sodass beim Upgrade auf 
eine neue Version und anschließendem Laden des states einer alten Version auch die
alte Version mit allen Bugs (ähh, Features) wiederhergestellt wird.
- Die Binaries haben eine Versionskontrolle eingebaut, die beim Start auf neue
Binary-Versionen checkt. Dazu ist natürlich eine Internetverbindung erforderlich.

#### Maus-Shortcuts

Im SiSa-Mode gibt es ein paar nützliche Shortcuts:

- Linksklick: Öffnet Datensatz.
- Rechtsklick: Schaltet Overlay für aktuellen Punkt um.
- Shift-Rechtsklick: Schaltet Overlay für alle Punkte zwischen jetzigem Punkt und nächstem mit Rechtsklick ausgewählten Punkt um.
- Shift-Linksklick: Erzeugt neuen Slice zwischen jetzigem Punkt und dem nächsten mit Linksklick ausgewählten Punkt.
	- Linksklick aus Slice-Endpunkt: Erlaubt Verschieben des Punktes.
	- Rechtsklick auf Slice-Endpunkt: Plottet aktuellen Parameter über den Slice.
	- Doppelklick auf Slice-Endpunkt: Löscht den Slice.

---
#### Wichtig!
Matlab wurde mit Version R2014b auf ein neues Plot-Backend umgestellt. 
Bei Matlab R2014a lässt sich das neue Backend auch verwenden, indem Matlab mit 
`-hgVersion 2` ausgeführt wird.

Nach commit f32776dd wird nur noch mit dem neuen Backend entwickelt, also wird
die Software ohne diese Einstellung und/oder in alten Matlab-Versionen vermtl.
schrecklich aussehen. Die Funktionsfähigkeit sollte aber erhalten bleiben.

- Die Binaries sind ab f79c56c3 mit R2014b kompiliert.
- Die Binaries sind ab 0.4.3 mit R2015b kompiliert.

In [diesem](https://www.git.daten.tk/sebastian.pfitzner/sisa-scan-auswertung/tree/R2014a-kompatibel) 
Branch sind noch die alten hg1-kompatiblen Files und Binaries enthalten.
