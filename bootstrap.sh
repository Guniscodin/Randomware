#!/bin/bash
set -e

KEYRING="/usr/share/keyrings/randomware-archive-keyring.gpg"
REPO_URL="https://guniscodin.github.io/Randomware/"

echo "[randomware] Importing signing key..."
curl -fsSL "${REPO_URL}randomware-archive-keyring.gpg" | gpg --dearmor -o "$KEYRING"

echo "[randomware] Adding apt source..."
echo "deb [signed-by=$KEYRING] $REPO_URL ./" > /etc/apt/sources.list.d/randomware.list

echo "[randomware] Updating apt..."
apt update

echo "[randomware] Done. Now run: sudo apt install randomware"
