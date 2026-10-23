#!/bin/bash
# Crea el certificat propi per signar Emojis (només s'ha de fer un cop).
#
# Amb el mateix certificat a totes les versions, el Mac les reconeix com la mateixa app
# i manté el permís d'Accessibilitat després de cada actualització.
#
# Ho deixa tot a ~/.config/emojis-signing (fora del repositori, que és públic):
#   emojis-signing.p12   certificat i clau privada (FES-NE CÒPIA DE SEGURETAT)
#   password             contrasenya del .p12 i del clauer
#   emojis.keychain-db   clauer propi que fa servir build_app.sh (no toca el clauer de sessió)
#   github-secret-*.txt  el que cal enganxar als secrets de GitHub
set -euo pipefail

DIR="${EMOJIS_SIGNING_DIR:-$HOME/.config/emojis-signing}"
NAME="Emojis Self-Signed"

if [ -f "$DIR/emojis-signing.p12" ]; then
    echo "Ja existeix $DIR/emojis-signing.p12. No el sobreescric: canviar-lo faria perdre el permís d'Accessibilitat."
    exit 1
fi
mkdir -p "$DIR"
chmod 700 "$DIR"
cd "$DIR"

PASSWORD="$(/usr/bin/openssl rand -hex 24)"
printf '%s' "$PASSWORD" > password
chmod 600 password

cat > openssl.cnf <<EOF
[req]
distinguished_name = dn
x509_extensions = ext
prompt = no
[dn]
CN = $NAME
[ext]
basicConstraints = critical, CA:false
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, codeSigning
EOF

# El /usr/bin/openssl del Mac fa .p12 que `security import` accepta sense problemes
/usr/bin/openssl req -x509 -newkey rsa:2048 -nodes -days 7300 -config openssl.cnf \
    -keyout key.pem -out cert.pem 2>/dev/null
/usr/bin/openssl pkcs12 -export -inkey key.pem -in cert.pem -name "$NAME" \
    -out emojis-signing.p12 -passout "pass:$PASSWORD"
rm -f key.pem openssl.cnf
chmod 600 emojis-signing.p12

# Clauer propi per signar en local sense tocar el de la sessió
SEARCH_LIST="$(security list-keychains -d user | tr -d '"')"
security create-keychain -p "$PASSWORD" "$DIR/emojis.keychain-db"
security set-keychain-settings "$DIR/emojis.keychain-db"
security import emojis-signing.p12 -k "$DIR/emojis.keychain-db" -P "$PASSWORD" -T /usr/bin/codesign >/dev/null
security set-key-partition-list -S apple-tool:,apple: -s -k "$PASSWORD" "$DIR/emojis.keychain-db" >/dev/null
# create-keychain l'afegeix a la llista de cerca; la deixem com estava
# shellcheck disable=SC2086
security list-keychains -d user -s $SEARCH_LIST

base64 -i emojis-signing.p12 > github-secret-SIGNING_P12_BASE64.txt
printf '%s' "$PASSWORD" > github-secret-SIGNING_PASSWORD.txt
chmod 600 github-secret-*.txt

echo "Certificat creat a $DIR"
echo "Empremta: $(/usr/bin/openssl x509 -in cert.pem -noout -fingerprint -sha256)"
