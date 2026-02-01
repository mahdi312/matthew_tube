# Install-Matthew_Tube_Windows_Deps.ps1
# Downloads & configures yt-dlp + ffmpeg + jq + wget/curl helpers

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host " Installing dependencies for Matthew_Tube downloader " -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

$toolsFolder = "$env:USERPROFILE\Tools\Matthew_Tube_Downloader"
New-Item -ItemType Directory -Force -Path $toolsFolder | Out-Null

Write-Host "→ Creating folder: $toolsFolder" -ForegroundColor Green

Set-Location $toolsFolder

# ───────────────────────────────────────
# yt-dlp
# ───────────────────────────────────────
Write-Host "Downloading yt-dlp..." -ForegroundColor Yellow
Invoke-WebRequest -Uri "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe" -OutFile "yt-dlp.exe"

# ───────────────────────────────────────
# ffmpeg (gyan.dev essentials build)
# ───────────────────────────────────────
Write-Host "Downloading ffmpeg..." -ForegroundColor Yellow
$ffmpegZip = "ffmpeg-essentials.zip"
Invoke-WebRequest -Uri "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip" -OutFile $ffmpegZip

Expand-Archive -Path $ffmpegZip -DestinationPath "ffmpeg" -Force
Move-Item -Path "ffmpeg\ffmpeg-*\bin\*" -Destination . -Force
Remove-Item -Path "ffmpeg" -Recurse -Force
Remove-Item $ffmpegZip -Force

# ───────────────────────────────────────
# jq
# ───────────────────────────────────────
Write-Host "Downloading jq..." -ForegroundColor Yellow
Invoke-WebRequest -Uri "https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-win64.exe" -OutFile "jq.exe"

Write-Host ""
Write-Host "Adding folder to PATH (current user)..." -ForegroundColor Yellow

$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$toolsFolder*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$toolsFolder", "User")
    Write-Host "→ PATH updated. You may need to restart PowerShell / Terminal." -ForegroundColor Green
} else {
    Write-Host "→ Path already contains the folder." -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Finished. Testing tools..." -ForegroundColor Cyan
Write-Host ""

yt-dlp --version
ffmpeg -version | Select-Object -First 1
jq --version

Write-Host ""
Write-Host "All done! You can now run your downloader script." -ForegroundColor Green
Write-Host "Recommended next step: export cookies.txt using Chrome/Edge extension 'Get cookies.txt LOCALLY'"
Pause