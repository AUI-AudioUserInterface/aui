# AUI Monorepo

Dieses Repo ist das **Meta-/Hauptprojekt** `aui`. Es referenziert die einzelnen Teilprojekte als **Git-Submodule**:

```
aui/
├─ aui-adapter-ari-simple/   # GPL – einfacher ARI‑Adapter (Asterisk)
├─ aui-adapter-pc/           # GPL/Commercial – PC/OS‑Audio, Eingabe
├─ aui-common/               # MIT/LGPL – Basistypen & Interfaces (PcmAudio, AppContext, …)
├─ aui-core/                 # GPL/Commercial – Runtime, Service‑Container (ohne direkte TTS/Adapter)
├─ aui-tk/                   # LGPL/Commercial – Widgets (OO), Themes
├─ aui-tts-coqui/            # MPL – Coqui‑TTS‑Plugin (Modelle jeweils prüfen)
└─ aui-tts-piper/            # GPL – Piper‑TTS‑Plugin
```

> Ziel: **klare Trennung** von Interfaces (common) und Implementierungen (Plugins), um **GPL** gezielt zu isolieren und
> **kommerzielle/closed‑source Adapter** zu ermöglichen.

---

## Schnelleinstieg

### 1) Submodule initialisieren
```bash
git submodule update --init --recursive
```

### 2) Python‑Umgebung & Installation
Mit dem Skript `bootstrap.sh` wird eine lokale venv erstellt und alle Pakete als **editable** installiert.
Standardmäßig wird **kein** TTS‑Backend mitinstalliert, damit `aui-core` GPL‑frei bleibt.
```bash
bash bootstrap.sh
# oder mit Coqui:
bash bootstrap.sh --coqui
# oder mit Piper (GPL):
bash bootstrap.sh --piper
# beides:
bash bootstrap.sh --coqui --piper
```

Die Abhängigkeiten für Entwicklung/Tests sind in `requirements.txt` gelistet und werden vom Skript installiert.

### 3) Minimaler Smoke‑Test
```bash
python -c "import importlib.metadata as md; print([ep.name for ep in md.entry_points(group='aui.tts_backends')])"
```

---

## Plugins (Entry Points)

**TTS‑Backends** registrieren sich unter dem Entry‑Point‑Group‑Namen:
```
aui.tts_backends
  ├─ piper  → aui_tts_piper:PiperTTS
  └─ coqui  → aui_tts_coqui:CoquiTTS
```

**Adapter** registrieren sich z. B. als:
```
aui.adapters
  ├─ pc    → aui_adapter_pc:PcAdapter
  └─ ari   → aui_adapter_ari_simple:AriAdapter
```

`aui-core` lädt Backends/Adapter **nur** über Entry Points (kein harter Import).

---

## Lizenz‑Matrix (Kurzfassung)

| Paket                 | Lizenz                 | Notizen                                  |
|-----------------------|------------------------|------------------------------------------|
| aui-common            | MIT oder LGPL          | Basistypen/Interfaces (keine GPL‑Imports)|
| aui-core              | GPLv3 / Commercial     | Lädt Plugins dynamisch                   |
| aui-tk                | LGPLv3 / Commercial    | OO‑Widgets, keine Engine‑Kopplung        |
| aui-tts-piper         | GPLv3                  | Importiert `piper-tts` (GPL)             |
| aui-tts-coqui         | MPL‑2.0                | Modelllizenzen prüfen                    |
| aui-adapter-ari-simple| GPLv3                  | Einfache ARI‑Funktionalität              |
| aui-adapter-pc        | GPLv3 / Commercial     | PC/OS‑Audio, Eingabe                     |

---

## Entwicklungs‑Workflow

- **Editable Installs**: Jede Unterkomponente wird per `pip install -e ./unterprojekt` installiert.
- **Tests**: Empfohlen `pytest`, `pytest-asyncio`.  
- **Lint/Type**: `ruff`, `mypy` (optional in `requirements.txt`).
- **Versionierung**: SemVer pro Paket. Kompat‑Matrix im Root‑README pflegen.
- **CI** (Empfehlung): Matrix‑Build (jede Komponente), plus Integrationsjob.

---

## Hinweise zu TTS‑Modellen

- **Piper**: GPL → nur verwenden, wenn GPL akzeptiert wird.
- **Coqui**: Library MPL, **Modelle separat prüfen** (einige non‑commercial). Für kommerzielle Nutzung kommerziell freigegebene Modelle wählen.

---

## Support‑/Kommerzielle Angebote

- Erweiterte ARI‑/Adapter‑Funktionalität kann als **kommerzielles, closed‑source Plugin** bereitgestellt werden.
- Kontakt/Angebote: (CoPiCo2Co@googlemail.com).
