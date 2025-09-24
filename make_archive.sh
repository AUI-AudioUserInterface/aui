#!/usr/bin/env bash
set -euo pipefail

OUT_NAME="aui.tar.gz"  # Ziel im Elternverzeichnis

# --- Checks ---
command -v git >/dev/null || { echo "git nicht gefunden"; exit 1; }
command -v tar >/dev/null || { echo "tar nicht gefunden"; exit 1; }
command -v gzip >/dev/null || { echo "gzip nicht gefunden"; exit 1; }

TOPDIR="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "${TOPDIR}" ]] || { echo "Bitte im Git-Repo ausführen."; exit 1; }

PARENT_DIR="$(dirname "${TOPDIR}")"
OUT_PATH="${PARENT_DIR}/${OUT_NAME}"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "${TMPDIR}"' EXIT

BASE_TAR="${TMPDIR}/base.tar"

echo "[1/3] Haupt-Repository archivieren..."
( cd "${TOPDIR}" && git archive --format=tar HEAD ) > "${BASE_TAR}"

echo "[2/3] Submodule sammeln..."
if [[ ! -f "${TOPDIR}/.gitmodules" ]]; then
  echo "Keine .gitmodules gefunden – nur Hauptrepo wird gepackt."
else
  # Keys in Form: submodule.aui-common.path
  while IFS= read -r key; do
    # Name extrahieren: aui-common
    name="${key#submodule.}"; name="${name%.path}"
    # Pfad laut .gitmodules (z.B. aui-common)
    path="$(git -C "${TOPDIR}" config -f .gitmodules "${key}" || true)"
    if [[ -z "${path}" ]]; then
      echo "  [WARN] Kein Pfad für ${key} – überspringe."
      continue
    fi
    # URL laut .gitmodules
    url="$(git -C "${TOPDIR}" config -f .gitmodules "submodule.${name}.url" || true)"
    if [[ -z "${url}" ]]; then
      echo "  [WARN] Keine URL für submodule.${name}.url (${path}) – überspringe."
      continue
    fi

    # Referenzierter Commit des Submodules im Superprojekt-HEAD
    lsline="$(git -C "${TOPDIR}" ls-tree -z HEAD -- "${path}" || true)"
    if [[ -z "${lsline}" ]]; then
      echo "  [WARN] Kein gitlink für ${path} in HEAD – überspringe."
      continue
    fi
    # Format: <mode> <type> <sha>\t<path>
    sha="$(printf "%s" "${lsline}" | tr '\0' '\n' | awk '{print $3}')"
    if [[ -z "${sha}" ]]; then
      echo "  [WARN] Keine SHA für ${path} – überspringe."
      continue
    fi

    echo "  -> ${path} (${name}) @ ${sha}"

    # Bare-Repo temporär, nur genau diesen Commit holen
    bare="${TMPDIR}/sm-${name}.git"
    git init --bare "${bare}" >/dev/null
    git -C "${bare}" remote add origin "${url}" >/dev/null
    if ! git -C "${bare}" fetch --depth 1 --no-tags origin "${sha}" >/dev/null 2>&1; then
      echo "    [WARN] Fetch ${sha} aus ${url} fehlgeschlagen – überspringe."
      continue
    fi

    # Archiv mit korrekt gesetztem Prefix (Submodule-Pfad)
    sm_tar="${TMPDIR}/sm-${name}.tar"
    git -C "${bare}" archive --format=tar --prefix="${path}/" "${sha}" > "${sm_tar}"
    tar --concatenate --file="${BASE_TAR}" "${sm_tar}"
    rm -f "${sm_tar}"
  done < <(git -C "${TOPDIR}" config -f .gitmodules --name-only --get-regexp '^submodule\..*\.path$' || true)
fi

echo "[3/3] Komprimieren -> ${OUT_PATH}"
gzip -c "${BASE_TAR}" > "${OUT_PATH}"

echo "Fertig: ${OUT_PATH}"
