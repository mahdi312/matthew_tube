# matthew_tube.ps1 — PowerShell version with cookies.txt support

Clear-Host

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "     Matthew_Tube Downloader (yt-dlp)"     -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
    Write-Host "Error: yt-dlp not found. Install via winget install yt-dlp" -ForegroundColor Red
    exit 1
}

$URL = Read-Host "Paste YouTube link (video or playlist)"
if (-not $URL) {
    Write-Host "No URL provided. Exiting." -ForegroundColor Yellow
    exit 1
}

# Cookies.txt prompt
Write-Host ""
Write-Host "For age-restricted / members-only / 'not a bot' videos use cookies.txt" -ForegroundColor Yellow
Write-Host "Export using 'Get cookies.txt LOCALLY' extension → save as cookies.txt" -ForegroundColor Yellow
Write-Host ""

$cookiesPath = Read-Host "Full path to cookies.txt (press Enter to skip)"
$cookieArg = @()
if ($cookiesPath -and (Test-Path $cookiesPath)) {
    $cookieArg = @("--cookies", $cookiesPath)
    Write-Host "→ Using cookies: $cookiesPath" -ForegroundColor Green
} else {
    Write-Host "→ No cookies → public access only" -ForegroundColor Cyan
}
Write-Host ""

# Detect playlist/single
Write-Host "Analyzing..." -ForegroundColor Yellow
$playlistTitle = yt-dlp --flat-playlist --print "%(playlist_title)s" $URL 2>$null | Select-Object -First 1

if ($playlistTitle -and $playlistTitle -ne "NA" -and $playlistTitle.Trim()) {
    $mode = "playlist"
    Write-Host "Detected: Playlist → $($playlistTitle.Trim())" -ForegroundColor Green
} else {
    $mode = "single"
    $title = yt-dlp --get-title $URL 2>$null
$displayTitle = if ($title) { $title } else { '(title unavailable)' }
Write-Host "Detected: Single video → $displayTitle"
}
Write-Host ""

# SINGLE
if ($mode -eq "single") {
    Write-Host "Available qualities:" -ForegroundColor Cyan
    yt-dlp -F $URL | Select-String '^[0-9]+.*video only.*|^[0-9]+.*audio only.*' | Select-Object -First 15

    $formatInput = Read-Host "Format code or Enter for best"
    $format = if (-not $formatInput) { "bestvideo+bestaudio/best" } 
              elseif ($formatInput -match '^\d+$') { "$formatInput+ba/best" } 
              else { $formatInput }

    $dlArgs = @("-f", $format, "--embed-subs", "--sub-langs", "all,-live_chat", "--embed-metadata", "--no-playlist") + $cookieArg
    $dlArgs += "--socket-timeout", "90", "--retries", "20", "--fragment-retries", "10", "--sleep-interval", "3", "--max-sleep-interval", "15"
    $dlArgs += $URL

    Write-Host "Downloading..." -ForegroundColor Yellow
    & yt-dlp @dlArgs
    Write-Host "Finished." -ForegroundColor Green
    exit 0
}

# PLAYLIST
$videoCount = (yt-dlp --flat-playlist --get-id $URL 2>$null | Measure-Object -Line).Lines
Write-Host "Playlist with $videoCount videos." -ForegroundColor Cyan

$choice = Read-Host "1 = whole playlist`n2 = select videos`nChoice"
$selectionMode = if ($choice -eq "1") { "all" } elseif ($choice -eq "2") { "select" } else { exit }

if ($selectionMode -eq "select") {
    Write-Host "Videos:" -ForegroundColor Cyan
    $lines = yt-dlp --flat-playlist --print "%(playlist_index)s→%(title)s" $URL 2>$null
    $i = 1
    foreach ($line in $lines) { Write-Host ("{0,3}  {1}" -f $i, $line); $i++ }

    $inputStr = Read-Host "Numbers (e.g. 1 3-7 12)"
    $selected = @()
    foreach ($token in ($inputStr -split '[ ,]+')) {
        if ($token -match '^(\d+)-(\d+)$') { $selected += [int]$Matches[1]..[int]$Matches[2] }
        elseif ($token -match '^\d+$') { $selected += [int]$token }
    }
    $selected = $selected | Sort-Object -Unique
    if ($selected.Count -eq 0) { Write-Host "No valid selection"; exit 1 }
    Write-Host "Selected: $($selected -join ', ')"
}

# Quality
$q = Read-Host "Quality (1080/720/480/360/best/audio)"
$format = switch ($q) {
    "1080" { "bestvideo[height<=1080]+bestaudio/best[height<=1080]" }
    "720"  { "bestvideo[height<=?720]+bestaudio/best[height<=?720]" }
    "480"  { "bestvideo[height<=?480]+bestaudio/best[height<=?480]" }
    "360"  { "bestvideo[height<=?360]+bestaudio/best[height<=?360]" }
    "best" { "bestvideo+bestaudio/best" }
    "audio"{ "bestaudio" }
    default{ "bestvideo[height<=?720]+bestaudio/best[height<=?720]" }
}

# Download command
$dlArgs = @("-f", $format, "--embed-subs", "--sub-langs", "all,-live_chat", "--embed-metadata", "--progress") + $cookieArg
$dlArgs += "--socket-timeout", "90", "--retries", "20", "--fragment-retries", "10", "--sleep-interval", "3", "--max-sleep-interval", "15"

if ($selectionMode -eq "select") {
    $items = $selected -join ","
    $dlArgs += "--playlist-items", $items
}
$dlArgs += $URL

Write-Host "Starting..." -ForegroundColor Yellow
& yt-dlp @dlArgs
Write-Host "Finished." -ForegroundColor Green
