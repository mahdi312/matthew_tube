#!/usr/bin/env bash
# matthew_tube.sh — Interactive YouTube downloader with cookies.txt support
# Requirements: yt-dlp, ffmpeg (recommended), jq (optional but nice)

clear

echo "======================================"
echo "   Matthew_tube Downloader (yt-dlp)   "
echo "======================================"
echo

command -v yt-dlp >/dev/null 2>&1 || { echo "Error: yt-dlp not found. Please install it first."; exit 1; }

# ────────────────────────────────────────────────
# 1. Ask for URL
# ────────────────────────────────────────────────
read -r -p "Paste YouTube link (video or playlist): " URL
echo

if [[ -z "$URL" ]]; then
    echo "No URL provided. Exiting."
    exit 1
fi

# ────────────────────────────────────────────────
# Cookies.txt support (manual export – most reliable)
# ────────────────────────────────────────────────
echo
echo "For age-restricted, members-only or 'not a bot' videos you usually need cookies."
echo "How to get cookies.txt:"
echo "  1. Install 'Get cookies.txt LOCALLY' extension in Chrome/Edge"
echo "  2. Go to youtube.com (logged in)"
echo "  3. Export → save as cookies.txt"
echo

COOKIES_FILE=""
read -r -p "Full path to cookies.txt (press Enter to skip): " COOKIES_INPUT

if [[ -n "$COOKIES_INPUT" ]]; then
    if [[ -f "$COOKIES_INPUT" ]]; then
        COOKIES_FILE="$COOKIES_INPUT"
        echo "→ Using cookies: $COOKIES_FILE"
    else
        echo "Warning: File not found → continuing without cookies"
    fi
else
    echo "→ No cookies file → public access only"
fi
echo

# ────────────────────────────────────────────────
# 2. Check if playlist or single video
# ────────────────────────────────────────────────
echo "Analyzing link... (may take a few seconds)"

PLAYLIST_TITLE=$(yt-dlp --flat-playlist --print "%(playlist_title)s" "$URL" 2>/dev/null | head -n 1)

if [[ -n "$PLAYLIST_TITLE" && "$PLAYLIST_TITLE" != "NA" ]]; then
    MODE="playlist"
    echo "Detected: Playlist → $PLAYLIST_TITLE"
else
    MODE="single"
    TITLE=$(yt-dlp --get-title "$URL" 2>/dev/null || echo "(title unavailable)")
    echo "Detected: Single video → $TITLE"
fi
echo

# ────────────────────────────────────────────────
# SINGLE VIDEO FLOW
# ────────────────────────────────────────────────
if [[ "$MODE" == "single" ]]; then
    echo "Available qualities (best → worst):"
    yt-dlp -F "$URL" | grep -E '^[0-9]+.*video only.*|^[0-9]+.*audio only.*' | head -n 15
    echo

    read -r -p "Enter format code (137, 22, 18, bestaudio ...) or Enter for best: " FORMAT

    if [[ -z "$FORMAT" ]]; then
        FORMAT="bestvideo+bestaudio/best"
    elif [[ "$FORMAT" =~ ^[0-9]+$ ]]; then
        FORMAT="$FORMAT+ba/best"
    fi

    echo
    echo "Downloading..."
    echo

    DL_CMD=(yt-dlp -f "$FORMAT" --embed-subs --sub-langs all,-live_chat --embed-metadata --no-playlist)
    [[ -n "$COOKIES_FILE" ]] && DL_CMD+=(--cookies "$COOKIES_FILE")
    DL_CMD+=(--socket-timeout 90 --retries 20 --fragment-retries 10 --sleep-interval 3 --max-sleep-interval 15)
    DL_CMD+=("$URL")

    "${DL_CMD[@]}"

    echo
    echo "Download finished."
    exit 0
fi

# ────────────────────────────────────────────────
# PLAYLIST FLOW
# ────────────────────────────────────────────────

echo "This is a playlist with $(yt-dlp --flat-playlist --get-id "$URL" | wc -l) videos."
echo

PS3="Do you want to download: "
options=("The whole playlist" "Select specific videos")
select opt in "${options[@]}"; do
    case $opt in
        "The whole playlist") SELECTION_MODE="all"; break ;;
        "Select specific videos") SELECTION_MODE="select"; break ;;
        *) echo "Invalid choice $REPLY" ;;
    esac
done
echo

# Show numbered list
if [[ "$SELECTION_MODE" == "select" ]]; then
    echo "Videos in playlist:"
    echo "────────────────────────────────────────"

    yt-dlp --flat-playlist --print "%(playlist_index)s→%(title)s" "$URL" | \
        sed 's/^/  /' | nl -w2 -s'  ' | sed 's/^[ ]*//'

    echo "────────────────────────────────────────"
    echo
    echo "Enter numbers like:  1 3 7 12-15 42"
    read -r -p "Which videos? (space or comma separated): " INPUT

    mapfile -t SELECTED < <(
        echo "$INPUT" | tr ',' ' ' | tr -s ' ' '\n' | \
        while read -r token; do
            if [[ "$token" =~ ^[0-9]+$ ]]; then
                echo "$token"
            elif [[ "$token" =~ ^([0-9]+)-([0-9]+)$ ]]; then
                seq "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
            fi
        done | sort -nu
    )

    if [[ ${#SELECTED[@]} -eq 0 ]]; then
        echo "No valid numbers selected. Exiting."
        exit 1
    fi

    echo "Selected: ${SELECTED[*]}"
    echo
fi

# ────────────────────────────────────────────────
# Quality selection
# ────────────────────────────────────────────────
echo "Common format presets:"
echo "  1080 → best video ≤1080p + best audio"
echo "  720  → best video ≤720p + best audio"
echo "  480  → best video ≤480p + best audio"
echo "  360  → best video ≤360p + best audio"
echo "  best → highest quality available"
echo "  audio → best audio only"
echo

read -r -p "Desired quality (1080/720/480/360/best/audio) : " Q

case "$Q" in
    1080) FORMAT="bestvideo[height<=1080]+bestaudio/best[height<=1080]" ;;
    720)  FORMAT="bestvideo[height<=?720]+bestaudio/best[height<=?720]" ;;
    480)  FORMAT="bestvideo[height<=?480]+bestaudio/best[height<=?480]" ;;
    360)  FORMAT="bestvideo[height<=?360]+bestaudio/best[height<=?360]" ;;
    best) FORMAT="bestvideo+bestaudio/best" ;;
    audio) FORMAT="bestaudio" ;;
    *)    FORMAT="bestvideo[height<=?720]+bestaudio/best[height<=?720]" ;;
esac

echo "Using format: $FORMAT"
echo

# ────────────────────────────────────────────────
# Build & run download command
# ────────────────────────────────────────────────
DL_CMD=(yt-dlp -f "$FORMAT" --embed-subs --sub-langs all,-live_chat --embed-metadata --progress)

[[ -n "$COOKIES_FILE" ]] && DL_CMD+=(--cookies "$COOKIES_FILE")

# Reliability flags for proxy / timeout issues
DL_CMD+=(--socket-timeout 90 --retries 20 --fragment-retries 10 --sleep-interval 3 --max-sleep-interval 15)

if [[ "$SELECTION_MODE" == "select" ]]; then
    ITEMS=$(IFS=, ; echo "${SELECTED[*]}")
    DL_CMD+=(--playlist-items "$ITEMS")
fi

DL_CMD+=("$URL")

echo "Starting download..."
echo "────────────────────────────────────────"
"${DL_CMD[@]}"
echo "────────────────────────────────────────"
echo
echo "Download session finished."
echo
exit 0
