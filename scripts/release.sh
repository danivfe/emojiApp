#!/bin/bash
# Publica una versió nova d'Emojis.
#
# Ús: scripts/release.sh 1.2 "Què hi ha de nou"
#
# Crea l'etiqueta v1.2 amb les novetats i la puja a GitHub. Allà, un Mac de GitHub
# compila l'app i publica la release (.github/workflows/release.yml). Les apps
# instal·lades la detecten i s'actualitzen soles.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:?Indica la versió, p. ex. scripts/release.sh 1.2 \"Novetats\"}"
NOTES="${2:-Versió $VERSION}"
TAG="v$VERSION"

if ! [[ "$VERSION" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
    echo "La versió ha de ser números separats per punts, p. ex. 1.2"; exit 1
fi
if [ -n "$(git status --porcelain)" ]; then
    echo "Hi ha canvis sense desar a git. Fes-ne commit abans de publicar."; exit 1
fi
if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo "L'etiqueta $TAG ja existeix."; exit 1
fi

git push origin HEAD
git tag -a "$TAG" -m "$NOTES"
git push origin "$TAG"
echo "Etiqueta $TAG pujada. En uns minuts la release serà a:"
echo "https://github.com/danivfe/emojiApp/releases/tag/$TAG"
