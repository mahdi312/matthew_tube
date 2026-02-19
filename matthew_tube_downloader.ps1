# fili.ps1 – FINAL FIXED VERSION (2026-02-08)

Clear-Host
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "      Matthew_Tube Downloader"         -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# ────────────────────────────────────────────────
# Logging setup – reliable & complete
# ────────────────────────────────────────────────
$logDir = Join-Path $PSScriptRoot "logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$logFile = Join-Path $logDir "log-$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"

# Start transcript (captures EVERYTHING: console + file)
Start-Transcript -Path $logFile -Append -Force -IncludeInvocationHeader

# Ctrl+C / exit handler
Register-EngineEvent PowerShell.Exiting -Action {
    Stop-Transcript -ErrorAction SilentlyContinue
    Write-Host "Script terminated (Ctrl+C or exit)" -ForegroundColor Yellow
} | Out-Null

# Simple Log function (writes to console – transcript saves to file)
function Log {
    param([string]$Message, [string]$Color = "White")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "$timestamp  $Message" -ForegroundColor $Color
}

Log "Script started" "Cyan"
Log "======================================" "Cyan"


# ────────────────────────────────────────────────
# Ask to check & install/update ALL dependencies
# ────────────────────────────────────────────────
Write-Host "This script needs several tools to work perfectly:" -ForegroundColor Cyan
Write-Host "  - yt-dlp (main downloader)"
Write-Host "  - ffmpeg (merge video/audio, embed subs)"
Write-Host "  - jq (better playlist handling)"
Write-Host "  - Deno + yt-dlp-ejs (solve YouTube signature challenges)"
Write-Host "  - curl-cffi (browser impersonation to bypass bot detection)"
Write-Host ""
Write-Host "Do you want to check and install/update them now?" -ForegroundColor Yellow
Write-Host "Recommended for first run or if you see errors (bot detection, missing formats, etc.)"
$checkDeps = Read-Host "Yes/No [default = No]"

if ($checkDeps -match '^[yY]') {
    Write-Host "Starting dependency check & installation..." -ForegroundColor Yellow
    Write-Host ""

    # Helper function to run winget safely
    function Install-WithWinget($id, $name) {
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Host "Installing $name via winget..."
            winget install $id --accept-source-agreements --accept-package-agreements --silent
        } else {
            Write-Host "winget not found. Please install $name manually:" -ForegroundColor Yellow
        }
    }

    # 1. yt-dlp
    if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
        Install-WithWinget "yt-dlp.yt-dlp" "yt-dlp"
    } else {
        Write-Host "Updating yt-dlp..."
        yt-dlp -U
    }

    # 2. ffmpeg
    if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
        Install-WithWinget "Gyan.FFmpeg" "ffmpeg"
        if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
            Write-Host "Manual install needed:"
            Write-Host "  1. Go to https://www.gyan.dev/ffmpeg/builds/"
            Write-Host "  2. Download ffmpeg-release-essentials.zip"
            Write-Host "  3. Extract bin\ffmpeg.exe to C:\Windows\System32 or add folder to PATH"
            Write-Host "Press Enter when ready..."
            Read-Host
        }
    }

    # 3. jq
    if (-not (Get-Command jq -ErrorAction SilentlyContinue)) {
        Install-WithWinget "jqlang.jq" "jq"
        if (-not (Get-Command jq -ErrorAction SilentlyContinue)) {
            Write-Host "Manual install:"
            Write-Host "  Download from https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-win64.exe"
            Write-Host "  Save as jq.exe in C:\Windows\System32"
            Write-Host "Press Enter when done..."
            Read-Host
        }
    }

    # 4. Deno (for JS challenge solving)
    if (-not (Get-Command deno -ErrorAction SilentlyContinue)) {
        Install-WithWinget "DenoLand.Deno" "Deno"
        if (-not (Get-Command deno -ErrorAction SilentlyContinue)) {
            Write-Host "Manual install:"
            Write-Host "  Go to https://deno.com"
            Write-Host "  Download installer for Windows"
            Write-Host "  Run it and restart PowerShell"
            Write-Host "Press Enter when done..."
            Read-Host
        }
    }

    # 5. Python packages (curl-cffi + yt-dlp-ejs)
    Write-Host "Updating Python packages (curl-cffi, yt-dlp-ejs)..."
    pip install --upgrade yt-dlp[default,curl-cffi] yt-dlp-ejs

    Write-Host ""
    Write-Host "Dependency check finished!" -ForegroundColor Green
    Write-Host "Press Enter to continue..." -ForegroundColor Cyan
    Read-Host
} else {
    Write-Host "Skipping dependency check. Some features may not work if tools are missing." -ForegroundColor Yellow
}
Write-Host ""


if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
    Write-Host "yt-dlp not found. Install: winget install yt-dlp" -ForegroundColor Red
    exit 1
}


# ────────────────────────────────────────────────
# Proxy selection
# ────────────────────────────────────────────────

Log "Proxy setup" "Cyan"
Write-Host "1 = No proxy"
Write-Host "2 = SOCKS5 127.0.0.1:10808 (v2ray)"
Write-Host "3 = SOCKS5 127.0.0.1:12334 (Hiddify mixed)"
Write-Host "4 = Manual"
$proxyChoice = Read-Host "Choose (1/2/3/4) [default=1]"

$proxyArg = @()
switch ($proxyChoice) {
    "2" { $proxyUrl = "socks5://127.0.0.1:10808" }
    "3" { $proxyUrl = "socks5://127.0.0.1:12334" }
    "4" { $proxyUrl = Read-Host "Full proxy URL" }
    default { $proxyUrl = $null }
}

if ($proxyUrl) {
    $env:http_proxy = $proxyUrl
    $env:https_proxy = $proxyUrl
    $proxyArg = @("--proxy", $proxyUrl)
    Log "Using proxy: $proxyUrl" "Green"
} else {
    Log "No proxy" "Cyan"
}
Write-Host ""

# 1. URL
$URL = Read-Host "Enter YouTube URL"
if (-not $URL) { Log "No URL"; Stop-Transcript; exit 1 }

# 2. Cookies
$defaultCookies = Join-Path $PWD "cookies.txt"
$cookiesPath = Read-Host "Cookies path (Enter = $defaultCookies)"
if (-not $cookiesPath) { $cookiesPath = $defaultCookies }

$cookieArg = @()
if (Test-Path $cookiesPath) {
    $cookieArg = @("--cookies", $cookiesPath)
    Log "Using cookies: $cookiesPath" "Green"
} else {
    Log "No cookies found" "Yellow"
}

# 3. Output dir
$outputDir = Read-Host "Output directory (Enter = current)"
if (-not $outputDir) { $outputDir = $PWD.Path }
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}
Log "Output directory: $outputDir" "Green"

# 4. Download type
Write-Host "1 = Video+Audio+Subs`n2 = Audio only`n3 = Subtitles only"
$downloadType = Read-Host "Choose"
switch ($downloadType) {
    "1" { $mode = "video" }
    "2" { $mode = "audio" }
    "3" { $mode = "subs" }
    default { Log "Invalid choice"; Stop-Transcript; exit 1 }
}

# Playlist detection
Log "Analyzing URL..."
$playlistTitle = yt-dlp --flat-playlist --print "%(playlist_title)s" $URL 2>$null | Select-Object -First 1
$isPlaylist = $playlistTitle -and $playlistTitle -ne "NA" -and $playlistTitle.Trim()

if ($isPlaylist) {
    Log "Playlist: $playlistTitle" "Green"
} else {
    $title = yt-dlp --get-title $URL 2>$null
    $displayTitle = if ($title) { $title } else { '(title unavailable)' }
    Log "Single video: $displayTitle" "Green"
}


# Playlist selection
$playlistItems = ""
if ($isPlaylist) {
    $choice = Read-Host "1 = All`n2 = Select`nChoice"
    if ($choice -eq "2") {
        Log "Listing first 30 items..." "Yellow"
        yt-dlp --flat-playlist --print "%(playlist_index)s  %(title)s" $URL 2>$null | Select-Object -First 30
        $selectionInput = Read-Host "Numbers/ranges (e.g. 1 3-7 12 or all)"
        if ($selectionInput -and $selectionInput -ne "all") {
            $numbers = @()
            foreach ($part in ($selectionInput -split '[ ,]+')) {
                if ($part -match '^(\d+)-(\d+)$') {
                    $numbers += [int]$Matches[1]..[int]$Matches[2]
                } elseif ($part -match '^\d+$') {
                    $numbers += [int]$part
                }
            }
            $numbers = $numbers | Sort-Object -Unique
            if ($numbers.Count -gt 0) {
                $playlistItems = $numbers -join ","
                Log "Selected items: $playlistItems" "Green"
            }
        }
    }
}

# Common safety flags (rate limit + JS challenge fix)
$ytSafetyArgs = @(
    "--extractor-args", "youtubetab:skip=authcheck",
    "--sleep-requests", "1",
    "--playlist-end", "50",
    "--js-runtimes", "deno",
    "--remote-components", "ejs:github",
    "-i",
    "--sleep-interval", "12",
    "--max-sleep-interval", "30"
)

switch ($mode) {
    "subs" {
        $subLangs = Read-Host "Languages (comma separated, e.g. en,fa or all)"
        if (-not $subLangs) { $subLangs = "en" }

        $subFmt = Read-Host "1=srt 2=vtt"
        $subExt = if ($subFmt -eq "2") { "vtt" } else { "srt" }

        $subType = Read-Host "1=all 2=manual 3=auto"
        $subFlags = @()
        if ($subType -in "1","2") { $subFlags += "--write-subs" }
        if ($subType -in "1","3") { $subFlags += "--write-auto-subs" }

        Log "Starting subtitles download..."
        yt-dlp --skip-download @subFlags "--sub-langs" $subLangs "--convert-subs" $subExt `
               "-o" "$outputDir\%(playlist_index)s-%(title)s.%(ext)s" `
               @cookieArg @proxyArg @ytSafetyArgs `
               $playlistItems ? @("--playlist-items", $playlistItems) : @() `
               $URL

				# After any yt-dlp call
		$exitCode = $LASTEXITCODE

		$filesCreated = Get-ChildItem -Path $outputDir -File -ErrorAction SilentlyContinue |
						Where-Object { $_.Extension -match '\.(webm|mp4|mkv|opus|mp3|wav|srt|vtt)$' }

		if ($filesCreated.Count -gt 0 -or $exitCode -eq 0) {
			Write-Host "Download completed successfully (files found)" -ForegroundColor Green
			Log "Success: Files created" "Green"
		} else {
			Write-Host "No files created (code $exitCode). Check log." -ForegroundColor Red
			Log "Failure: Exit code $exitCode, no files" "Red"
		}
		exit
    }
	

    "audio" {
        $audioFmt = Read-Host "Audio format code (Enter = bestaudio)"
        if (-not $audioFmt) { $audioFmt = "bestaudio" }

        Log "Starting audio download..."
        yt-dlp "-f" $audioFmt "--embed-metadata" `
               "-o" "$outputDir\%(playlist_index)s-%(title)s.%(ext)s" `
               @cookieArg @proxyArg @ytSafetyArgs `
               $playlistItems ? @("--playlist-items", $playlistItems) : @() `
               $URL

   				# After any yt-dlp call
		$exitCode = $LASTEXITCODE

		$filesCreated = Get-ChildItem -Path $outputDir -File -ErrorAction SilentlyContinue |
						Where-Object { $_.Extension -match '\.(webm|mp4|mkv|opus|mp3|wav|srt|vtt)$' }

		if ($filesCreated.Count -gt 0 -or $exitCode -eq 0) {
			Write-Host "Download completed successfully (files found)" -ForegroundColor Green
			Log "Success: Files created" "Green"
		} else {
			Write-Host "No files created (code $exitCode). Check log." -ForegroundColor Red
			Log "Failure: Exit code $exitCode, no files" "Red"
		}
		exit

    }

    "video" {
        $videoQ = Read-Host "Quality (best/1080/720/480/360/code)"
        $format = switch ($videoQ) {
            "best"  { "bestvideo+bestaudio/best" }
            "1080"  { "bestvideo[height<=1080]+bestaudio/best[height<=1080]" }
            "720"   { "bestvideo[height<=?720]+bestaudio/best[height<=?720]" }
            "480"   { "bestvideo[height<=?480]+bestaudio/best[height<=?480]" }
            "360"   { "bestvideo[height<=?360]+bestaudio/best[height<=?360]" }
            default { $videoQ }
        }

        $subLangsVideo = Read-Host "Subtitles (en,fa,... none all)"
        $subArg = @()
        if ($subLangsVideo -and $subLangsVideo -ne "none") {
            $subArg = @("--write-subs", "--write-auto-subs", "--sub-langs", $subLangsVideo, "--convert-subs", "srt", "--embed-subs")
        }

        Log "Starting video download..."
        yt-dlp "-f" $format @subArg "--embed-metadata" `
               "-o" "$outputDir\%(playlist_index)s-%(title)s.%(ext)s" `
               @cookieArg @proxyArg @ytSafetyArgs `
               $playlistItems ? @("--playlist-items", $playlistItems) : @() `
               $URL

					# After any yt-dlp call
		$exitCode = $LASTEXITCODE

		$filesCreated = Get-ChildItem -Path $outputDir -File -ErrorAction SilentlyContinue |
						Where-Object { $_.Extension -match '\.(webm|mp4|mkv|opus|mp3|wav|srt|vtt)$' }

		if ($filesCreated.Count -gt 0 -or $exitCode -eq 0) {
			Write-Host "Download completed successfully (files found)" -ForegroundColor Green
			Log "Success: Files created" "Green"
		} else {
			Write-Host "No files created (code $exitCode). Check log." -ForegroundColor Red
			Log "Failure: Exit code $exitCode, no files" "Red"
		}
		exit

	}
}
Stop-Transcript -ErrorAction SilentlyContinue
Log "Finished"

Write-Host "Finished. Log saved to $logFile" -ForegroundColor Green
