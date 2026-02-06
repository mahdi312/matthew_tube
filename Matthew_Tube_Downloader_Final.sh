#!/usr/bin/env bash
# Matthew_Tube Downloader – Bash version

clear
echo "======================================"
echo "     Matthew_Tube Downloader"
echo "======================================"
echo

command -v yt-dlp >/dev/null 2>&1 || { echo "yt-dlp not found."; exit 1; }

# 1. URL
read -r -p "Enter YouTube URL: " URL
[[ -z "$URL" ]] && { echo "No URL."; exit 1; }
echo

# 2. Cookies (default current/cookies.txt)
DEFAULT_COOKIES="$(pwd)/cookies.txt"
read -r -p "Cookies file (Enter = $DEFAULT_COOKIES): " COOKIES_PATH
COOKIES_PATH="${COOKIES_PATH:-$DEFAULT_COOKIES}"

if [[ -f "$COOKIES_PATH" ]]; then
    echo "→ Using: $COOKIES_PATH"
    COOKIES_ARG="--cookies $COOKIES_PATH"
else
    echo "→ No cookies"
    COOKIES_ARG=""
fi
echo

# 3. Output dir
CURRENT_DIR="$(pwd)"
read -r -p "Output directory (Enter = $CURRENT_DIR): " OUTPUT_DIR
OUTPUT_DIR="${OUTPUT_DIR:-$CURRENT_DIR}"

[[ ! -d "$OUTPUT_DIR" ]] && {
    echo "Creating folder..."
    mkdir -p "$OUTPUT_DIR" || { echo "Cannot create."; exit 1; }
}
echo "→ $OUTPUT_DIR"
echo

# 4. Type
echo "What to download?"
echo "  1 = Video+Audio+Subs"
echo "  2 = Audio only"
echo "  3 = Subtitles only"
read -r -p "Choose (1/2/3): " DOWNLOAD_TYPE

case "$DOWNLOAD_TYPE" in
    1) MODE="video" ;;
    2) MODE="audio" ;;
    3) MODE="subs"  ;;
    *) echo "Invalid."; exit 1 ;;
esac
echo

# Detect playlist
PLAYLIST_TITLE=$(yt-dlp --flat-playlist --print "%(playlist_title)s" "$URL" 2>/dev/null | head -n 1)
if [[ -n "$PLAYLIST_TITLE" && "$PLAYLIST_TITLE" != "NA" ]]; then
    IS_PLAYLIST=1
    echo "Detected: Playlist → $PLAYLIST_TITLE"
else
    IS_PLAYLIST=0
    TITLE=$(yt-dlp --get-title "$URL" 2>/dev/null || echo "(title unavailable)")
    echo "Detected: Single video → $TITLE"
fi
echo

# 5+7. Selection
PLAYLIST_ARG=""
if [[ $IS_PLAYLIST -eq 1 ]]; then
    read -r -p "1 = All  2 = Select items  : " SEL_CHOICE
    if [[ "$SEL_CHOICE" == "2" ]]; then
        echo "Listing (first 30):"
        yt-dlp --flat-playlist --print "%(playlist_index)s  %(title)s" "$URL" | head -n 30
        read -r -p "Which items? (e.g. 1 3-7 12 or all): " SELECTION
        if [[ "$SELECTION" != "all" && -n "$SELECTION" ]]; then
            ITEMS=$(echo "$SELECTION" | tr -d ' ' | sed 's/,/ /g' | tr ' ' '\n' | \
                    while read -r t; do
                        if [[ "$t" =~ ^[0-9]+$ ]]; then echo "$t"; fi
                        if [[ "$t" =~ ^([0-9]+)-([0-9]+)$ ]]; then seq "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"; fi
                    done | sort -nu | paste -sd, -)
            PLAYLIST_ARG="--playlist-items $ITEMS"
        fi
    fi
fi
echo

# Mode logic
case "$MODE" in
    subs)
        read -r -p "Languages (en,fa,... or all): " SUB_LANGS
        [[ -z "$SUB_LANGS" ]] && SUB_LANGS="en"

        echo "Format: 1=srt 2=vtt"
        read -r -p "Choose (1/2): " SUB_FMT
        SUB_EXT=$([[ "$SUB_FMT" == "2" ]] && echo "vtt" || echo "srt")

        echo "Type: 1=manual+auto 2=manual 3=auto"
        read -r -p "Choose (1/2/3): " SUB_TYPE
        SUB_FLAGS=""
        [[ "$SUB_TYPE" == "2" || "$SUB_TYPE" == "1" ]] && SUB_FLAGS="$SUB_FLAGS --write-subs"
        [[ "$SUB_TYPE" == "3" || "$SUB_TYPE" == "1" ]] && SUB_FLAGS="$SUB_FLAGS --write-auto-subs"

        yt-dlp --skip-download $SUB_FLAGS --sub-langs "$SUB_LANGS" --convert-subs "$SUB_EXT" \
               -o "$OUTPUT_DIR/%(playlist_index)s-%(title)s.%(ext)s" \
               $COOKIES_ARG $PLAYLIST_ARG \
               --js-runtimes "deno" --remote-components "ejs:github" -i \
               --sleep-interval 5 --max-sleep-interval 15 \
               "$URL"
        echo "Subtitles saved."
        exit 0
        ;;

    audio)
        echo "Audio formats:"
        yt-dlp -F "$URL" | grep audio | head -n 20
        read -r -p "Audio format code (Enter = bestaudio): " AUDIO_FMT
        [[ -z "$AUDIO_FMT" ]] && AUDIO_FMT="bestaudio"

        yt-dlp -f "$AUDIO_FMT" --embed-metadata \
               -o "$OUTPUT_DIR/%(playlist_index)s-%(title)s.%(ext)s" \
               $COOKIES_ARG $PLAYLIST_ARG \
               --js-runtimes "deno" --remote-components "ejs:github" -i \
               --sleep-interval 5 --max-sleep-interval 15 \
               "$URL"
        echo "Audio saved."
        exit 0
        ;;

    video)
        echo "Video qualities:"
        yt-dlp -F "$URL" | grep -E '^[0-9]+.*video' | head -n 20

        echo "Presets: best / 1080 / 720 / 480 / 360"
        read -r -p "Choose: " VIDEO_Q
        case "$VIDEO_Q" in
            best)  FORMAT="bestvideo+bestaudio/best" ;;
            1080)  FORMAT="bestvideo[height<=1080]+bestaudio/best[height<=1080]" ;;
            720)   FORMAT="bestvideo[height<=?720]+bestaudio/best[height<=?720]" ;;
            480)   FORMAT="bestvideo[height<=?480]+bestaudio/best[height<=?480]" ;;
            360)   FORMAT="bestvideo[height<=?360]+bestaudio/best[height<=?360]" ;;
            *)     FORMAT="$VIDEO_Q" ;;
        esac

        read -r -p "Subtitles (en,fa,... none all): " SUB_LANGS_VIDEO
        SUB_ARG=""
        [[ -n "$SUB_LANGS_VIDEO" && "$SUB_LANGS_VIDEO" != "none" ]] && \
            SUB_ARG="--write-subs --write-auto-subs --sub-langs $SUB_LANGS_VIDEO --convert-subs srt --embed-subs"

        yt-dlp -f "$FORMAT" $SUB_ARG --embed-metadata \
               -o "$OUTPUT_DIR/%(playlist_index)s-%(title)s.%(ext)s" \
               $COOKIES_ARG $PLAYLIST_ARG \
               --js-runtimes "deno" --remote-components "ejs:github" -i \
               --sleep-interval 5 --max-sleep-interval 15 \
               "$URL"
        echo "Video saved."
        exit 0
        ;;
esac

echo "Finished."