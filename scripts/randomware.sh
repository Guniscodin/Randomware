#!/bin/bash
set -e

BASE="/home/gunornot/toolkit-repo"
REPO_DIR="$BASE/repo"
PKG_DIR="$BASE/randomware"
TOOLS_FILE="$BASE/tools.txt"
GPG_KEY="CD01C33406E0A9FC2316FCB268014A519BCDFC3D"
WORDLIST_DIR="/usr/share/wordlists"

usage() {
    echo "Usage:"
    echo "  randomware -add t <tool-name>          Add an apt-available tool"
    echo "  randomware -add w <name> <url>         Add a wordlist download"
    exit 1
}

rebuild_and_publish() {
    cd "$BASE"

    # Bump version (patch number)
    CURRENT_VER=$(grep "^Version:" "$PKG_DIR/DEBIAN/control" | awk '{print $2}')
    NEW_VER=$(echo "$CURRENT_VER" | awk -F. '{print $1"."$2"."$3+1}')
    sed -i "s/^Version:.*/Version: $NEW_VER/" "$PKG_DIR/DEBIAN/control"
    echo "[randomware] Bumping version $CURRENT_VER -> $NEW_VER"

    # Rebuild .deb
    rm -f "$BASE/randomware.deb"
    dpkg-deb --build --root-owner-group "$PKG_DIR"
    cp "$BASE/randomware.deb" "$REPO_DIR/randomware.deb"

    # Regenerate repo index
    cd "$REPO_DIR"
    dpkg-scanpackages --multiversion . /dev/null > Packages
    gzip -k -f Packages

    cat > Release << EOF
Origin: randomware
Label: randomware
Suite: stable
Codename: stable
Architectures: amd64
Components: main
Description: just some random packages
Date: $(date -Ru)
EOF

    cat >> Release << EOF
MD5Sum:
 $(md5sum Packages | awk '{print $1}') $(stat -c%s Packages) Packages
 $(md5sum Packages.gz | awk '{print $1}') $(stat -c%s Packages.gz) Packages.gz
SHA1:
 $(sha1sum Packages | awk '{print $1}') $(stat -c%s Packages) Packages
 $(sha1sum Packages.gz | awk '{print $1}') $(stat -c%s Packages.gz) Packages.gz
SHA256:
 $(sha256sum Packages | awk '{print $1}') $(stat -c%s Packages) Packages
 $(sha256sum Packages.gz | awk '{print $1}') $(stat -c%s Packages.gz) Packages.gz
EOF

    # Re-sign
    rm -f Release.gpg InRelease
    gpg --default-key "$GPG_KEY" -abs -o Release.gpg Release
    gpg --default-key "$GPG_KEY" --clearsign -o InRelease Release

    # Push
    git add .
    git commit -m "Update: randomware v$NEW_VER"
    git push

    echo "[randomware] Published v$NEW_VER successfully."
}

add_tool() {
    local name="$1"
    echo "[randomware] Checking if '$name' is available via apt..."

    if ! apt-cache show "$name" > /dev/null 2>&1; then
        echo "[randomware] ERROR: '$name' not found in apt. It may need a different repo (e.g. Kali) or a source build."
        exit 1
    fi

    if grep -qx "$name" "$TOOLS_FILE"; then
        echo "[randomware] '$name' is already in tools.txt, nothing to do."
        exit 0
    fi

    echo "$name" >> "$TOOLS_FILE"
    DEPS=$(paste -sd, "$TOOLS_FILE" | sed 's/,/, /g')
    sed -i "s/^Depends:.*/Depends: $DEPS/" "$PKG_DIR/DEBIAN/control"

    echo "[randomware] Added '$name' to tools.txt and control file."
    rebuild_and_publish
}

add_wordlist() {
    local name="$1"
    local url="$2"

    if [ -z "$url" ]; then
        echo "[randomware] ERROR: wordlist requires a URL. Usage: randomware -add w <name> <url>"
        exit 1
    fi

    echo "[randomware] Verifying URL is reachable..."
    if ! curl -fsSL --head --max-time 15 "$url" > /dev/null; then
        echo "[randomware] ERROR: URL not reachable, aborting: $url"
        exit 1
    fi

    local outfile="$WORDLIST_DIR/${name}.txt"
    local postinst="$PKG_DIR/DEBIAN/postinst"

    if grep -q "$outfile" "$postinst"; then
        echo "[randomware] Wordlist '$name' already present in postinst, nothing to do."
        exit 0
    fi

    # Insert new fetch line before the final gunzip/echo block
    sed -i "/^if \[ -f \"\$WORDLIST_DIR\/rockyou.txt.gz\" \]; then/i fetch \"$url\" \\\\\n      \"$outfile\"\n" "$postinst"

    echo "[randomware] Added wordlist '$name' to postinst."
    rebuild_and_publish
}

case "$1" in
    -add)
        case "$2" in
            t) add_tool "$3" ;;
            w) add_wordlist "$3" "$4" ;;
            *) usage ;;
        esac
        ;;
    *)
        usage
        ;;
esac
