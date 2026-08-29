# Emberveil-Client: einzelne Lua-Dateien einer .toc werden nicht ausgefuehrt

## Beobachtung

Der Client fuehrt beim Laden eines Addons einen Teil der in der `.toc`
gelisteten `.lua`-Dateien **nicht aus**. Es erscheint **keine Fehlermeldung**;
die Dateien werden stillschweigend uebersprungen. Erkennbar nur daran, dass die
darin definierten Funktionen/Tabellen spaeter `nil` sind.

Addon: DPSMate (Portierung von Vanilla 1.12)
Betroffen: **11 von 113** in der `.toc` gelisteten `.lua`-Dateien

## Reproduzierbar

Jede Datei meldet sich in ihrer ersten Zeile selbst (`DPSMateFile("name")`).
Ueber mehrere Logins hinweg fehlen exakt dieselben 11 Dateien:

    DPSMate_Options.lua
    DPSMate_Sync.lua
    modules/DPSMate_HealingAndAbsorbs.lua
    modules/DPSMate_Casts.lua
    modules/DPSMate_FriendlyFireTaken.lua
    modules/DPSMate_Details_HealingAndAbsorbs.lua
    modules/DPSMate_Details_Auras.lua
    modules/DPSMate_Details_AurasTotal.lua
    modules/DPSMate_Details_ProcsTotal.lua
    modules/DPSMate_Details_CastsTotal.lua
    modules/DPSMate_Details_FailsTotal.lua

## Was als Ursache ausgeschlossen wurde

Jeder Punkt wurde direkt gemessen, nicht vermutet:

* **Dateigroesse** - eine 188 KB grosse Datei laedt, eine 14,9 KB grosse nicht.
* **Position in der .toc** - dieselben 11 Dateien scheitern auf Position
  15-25 genauso wie auf 16-173.
* **Anzahl der Eintraege** - Zusammenlegen auf 35 statt 192 Eintraege
  verschlechterte die Quote (8 von 21 statt 12 von 121).
* **Kumulative Datenmenge** vor der Datei - kein Zusammenhang.
* **Inhalt** - kein Bezeichner kommt in allen 11 fehlenden und selten in den
  110 geladenen vor.
* **Struktur** - Verschachtelungstiefe und Locals pro Funktion sind bei den
  geladenen Dateien hoeher (152 vs 76 bzw. 32 vs 26).
* **Lua-Syntax** - alle 125 Dateien compilieren fehlerfrei unter Lua 5.1
  (geprueft mit einem echten 5.1-Interpreter).
* **Dateinamen / Praefix-Kollisionen** - Gegenbeispiele in beide Richtungen.
* **Zeilenenden, Kodierung, Steuerzeichen, BOM** - die betroffenen Dateien
  sind reines ASCII mit LF, keine Steuerzeichen, kein BOM.
* **Nachbardateien** in der .toc - kein Zusammenhang.

Auffaellig: sobald der Inhalt einer *geladenen* Datei veraendert wird (Anhaengen
weiterer Funktionen), faellt sie ebenfalls aus - was gegen eine reine
Namens-/Positionsabhaengigkeit spricht und eher auf einen Fehler im Laden
selbst hindeutet (z.B. Kollision in einer Skript-Registry ohne
Kollisionsbehandlung).

## Erwartetes Verhalten

Alle in der `.toc` gelisteten Dateien werden ausgefuehrt, oder es erscheint
eine Fehlermeldung, wenn eine Datei nicht geladen/compiliert werden kann.
