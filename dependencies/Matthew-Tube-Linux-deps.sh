#!/usr/bin/env bash
# install-Matthew-Tube-Linux-deps.sh

set -e

echo "======================================================"
echo " Installing dependencies for Matthew_Tube downloader  "
echo "======================================================"
echo

TOOLS_DIR="$HOME/.local/matthew_tube_downloader"
mkdir -p "$TOOLS_DIR"
cd "$TOOLS_DIR" || exit 1

echo "→ Tools will be installed in: $TOOLS_DIR"

# ───────────────────────────────────────
# yt-dlp
# ───────────────────────────────────────
echo -e "\n→ Installing yt-dlp..."
curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o yt-dlp
chmod +x yt-dlp

# Move to ~/bin or /usr/local/bin if possible
if [[ -d "$HOME/.local/bin" ]]; then
    mv yt-dlp "$HOME/.local/bin/"
else
    sudo mv yt-dlp /usr/local/bin/ 2>/dev/null || mv yt-dlp "$TOOLS_DIR/"
fi

# ───────────────────────────────────────
# ffmpeg + jq via package manager
# ───────────────────────────────────────
echo -e "\n→ Installing ffmpeg & jq..."

if command -v apt >/dev/null 2>&1; then
    # Debian/Ubuntu/WSL
    sudo apt update -qq
    sudo apt install -y ffmpeg jq
elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y ffmpeg jq
elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy --noconfirm ffmpeg jq
else
    echo "→ No supported package manager detected. Please install ffmpeg & jq manually."
fi

echo -e "\n→ Checking installed tools...\n"

yt-dlp  --version 2>/dev/null || echo "yt-dlp not found in PATH"
ffmpeg -version 2>/dev/null | head -n1 || echo "ffmpeg not found"
jq     --version 2>/dev/null || echo "jq not found"

echo -e "\nDone."
echo "Recommended: export fresh cookies.txt using browser extension 'Get cookies.txt LOCALLY'"
echo "You can now run ./Matthew_Tube.sh"