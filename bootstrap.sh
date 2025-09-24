#!/usr/bin/env bash
set -euo pipefail

# AUI bootstrap (root)
# Flags:
#   --coqui   installiert aui-tts-coqui
#   --piper   installiert aui-tts-piper (GPL)
#   --pc      installiert aui-adapter-pc
#   --ari     installiert aui-adapter-ari-simple
#   --all     coqui + piper + pc + ari
#   --no-dev  requirements.txt NICHT installieren
#   PYTHON=/pfad/zu/python  (optional), default python3.11

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

# ---- Flags parsen -----------------------------------------------------------
INSTALL_COQUI=0
INSTALL_PIPER=0
INSTALL_PC=0
INSTALL_ARI=0
INSTALL_DEV=1

for arg in "$@"; do
  case "$arg" in
    --coqui) INSTALL_COQUI=1 ;;
    --piper) INSTALL_PIPER=1 ;;
    --pc)    INSTALL_PC=1 ;;
    --ari)   INSTALL_ARI=1 ;;
    --all)   INSTALL_COQUI=1; INSTALL_PIPER=1; INSTALL_PC=1; INSTALL_ARI=1 ;;
    --no-dev) INSTALL_DEV=0 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

# ---- Git Submodule ----------------------------------------------------------
git submodule update --init --recursive

# ---- venv mit Python 3.11 ---------------------------------------------------
PY="${PYTHON:-python3.11}"
if ! command -v "$PY" >/dev/null 2>&1; then
  echo "ERROR: $PY nicht gefunden. Bitte Python 3.11 installieren oder PYTHON=... setzen." >&2
  exit 1
fi

if [ ! -d ".venv" ]; then
  "$PY" -m venv .venv
fi

# shellcheck disable=SC1091
source .venv/bin/activate

# ---- Pip-Kommando strikt aus der venv wählen --------------------------------
VENV_BIN="$(cd .venv/bin && pwd)"
VENV_PY="$VENV_BIN/python"

PIP_CMD=()
if [ -x "$VENV_BIN/pip" ]; then
  # Verwende exakt das pip aus der venv (kein PATH-Lookup)
  PIP_CMD=("$VENV_BIN/pip")
elif "$VENV_PY" -m pip --version >/dev/null 2>&1; then
  PIP_CMD=("$VENV_PY" -m pip)
elif command -v uv >/dev/null 2>&1; then
  # uv pip in aktive venv installieren lassen
  PIP_CMD=(uv pip)
else
  echo "ERROR: Kein pip in der venv, und weder 'python -m pip' noch 'uv' verfügbar." >&2
  echo "Installiere 'python3-pip' oder 'uv'." >&2
  exit 1
fi

pip_install() { "${PIP_CMD[@]}" "$@"; }

# ---- Basis-Tools upgraden ---------------------------------------------------
pip_install install -q --upgrade setuptools wheel

# ---- Dev-Requirements (optional) -------------------------------------------
if [ "$INSTALL_DEV" -eq 1 ] && [ -f "requirements.txt" ]; then
  pip_install install -r requirements.txt
fi

# ---- Helper: editable install ----------------------------------------------
install_editable() {
  local d="$1"
  if [ -d "$d" ] && [ -f "$d/pyproject.toml" ]; then
    echo ">> ${PIP_CMD[*]} install -e $d"
    pip_install install -e "$d"
  fi
}

# ---- Basis-Pakete -----------------------------------------------------------
install_editable aui-common
install_editable aui-core
install_editable aui-tk

# ---- Adapter (optional) -----------------------------------------------------
if [ "$INSTALL_PC" -eq 1 ];  then install_editable aui-adapter-pc; fi
if [ "$INSTALL_ARI" -eq 1 ]; then install_editable aui-adapter-ari-simple; fi

# ---- TTS-Plugins (optional) -------------------------------------------------
if [ "$INSTALL_COQUI" -eq 1 ]; then install_editable aui-tts-coqui; fi
if [ "$INSTALL_PIPER" -eq 1 ]; then install_editable aui-tts-piper; fi

echo
echo "== AUI bootstrap abgeschlossen =="
echo "Aktive venv: $("$VENV_PY" --version)"
echo "PIP_CMD: ${PIP_CMD[*]}"
echo "Zum Reaktivieren:  source .venv/bin/activate"
