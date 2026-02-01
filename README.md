# matthew_tube
A simple, interactive script to easily download YouTube videos or entire playlists — with quality selection, cookies support for restricted content, and proxy-friendly stability.


## Matthew_Tube Downloader

### Document for Windows users

**How to use Matthew_Tube Downloader on Windows**

**Requirements**  

- Windows 10 or 11  
- Internet connection

**Step 1 – Install yt-dlp (one time only)**

Open **PowerShell** (press Win + S → type “PowerShell” → open it)

Paste this command and press Enter:

```powershell
winget install yt-dlp
```

Wait until it finishes.  
Check it works:

```powershell
yt-dlp --version
```

You should see a version number.

**Step 2 – Get cookies.txt (very important for age-restricted / members-only / blocked videos)**

1. Open Chrome or Edge  
2. Go to Chrome Web Store / Edge Add-ons  
3. Search for **Get cookies.txt LOCALLY**  
4. Install it  
5. Go to youtube.com and make sure you are logged in  
6. Click the extension icon → Export → save file as `cookies.txt`  
   (save it for example on Desktop or in Downloads)

**Step 3 – Download and run the script**

1. Download the file `matthew_tube.ps1` (or copy-paste the code into Notepad and save as `matthew_tube.ps1`)  
2. Put it in any folder you like (example: Desktop or D:\Downloads)  
3. Open **PowerShell**  
4. Go to the folder where you saved the script:

```powershell
cd "D:\Downloads"          # ← change to your folder
```

5. Run the script:

```powershell
.\matthew_tube.ps1
```

(First time you may need to allow scripts – run this once:)

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Then run the script again.

**Step 4 – How to use it**

- Paste YouTube link (single video or playlist)
- When it asks for cookies.txt path:  
  → drag the file from File Explorer into PowerShell window (easiest)  
  → or copy-paste the full path (example: `D:\Downloads\cookies.txt`)  
  → press Enter
- Choose quality, select videos if playlist, etc.

**Tips**

- If download is slow or times out → try different server in your VPN
- Re-export cookies.txt every few days if videos become blocked again
- You can put `cookies.txt` in the same folder as the script → easier to find

Enjoy downloading!

---

### Document for Linux users (including WSL)

**How to use Matthew_Tube Downloader on Linux / WSL**

**Requirements**

- Linux (Ubuntu, Debian, Fedora, Arch, …) or WSL on Windows
- Internet connection

**Step 1 – Install yt-dlp (one time only)**

Open terminal and run:

```bash
# Ubuntu / Debian / WSL
sudo apt update
sudo apt install yt-dlp

# Fedora
sudo dnf install yt-dlp

# Arch
sudo pacman -S yt-dlp

# Or universal way (recommended)
curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o ~/yt-dlp
chmod +x ~/yt-dlp
sudo mv ~/yt-dlp /usr/local/bin/
```

Check:

```bash
yt-dlp --version
```

**Step 2 – Get cookies.txt (important for restricted videos)**

1. In your browser (Firefox / Chrome / Edge)  
2. Install extension **Get cookies.txt LOCALLY**  
3. Go to youtube.com → make sure logged in  
4. Click extension → Export → save as `cookies.txt`  
   (save to `~/Downloads` or anywhere you like)

**Step 3 – Download and run the script**

1. Download `yt-dlpp.sh` (or copy-paste code into file)
2. Open terminal
3. Go to the folder:

```bash
cd ~/Downloads               # ← change to your folder
```

4. Make script executable:

```bash
chmod +x yt-dlpp.sh
```

5. Run it:

```bash
./yt-dlpp.sh
```

**Step 4 – How to use it**

- Paste YouTube link
- When it asks for cookies.txt path:  
  → type full path, example: `/home/yourname/Downloads/cookies.txt`  
  → or `~/Downloads/cookies.txt`  
  → press Enter (or just Enter to skip)
- Choose quality, select videos if playlist, wait…

**Tips for WSL users (Windows + Linux)**

- Use mirrored networking (already done if you have it)
- Proxy settings (V2Ray / Clash / etc.):

```bash
export http_proxy="socks5://172.xx.xx.1:10808"
export https_proxy="socks5://172.xx.xx.1:10808"
# or use your real Windows host IP
```

- Put `cookies.txt` in `~/` or Downloads folder



### Document for macOS users

**How to use Matthew_Tube Downloader on macOS**

**Requirements**  

- macOS Ventura / Sonoma / Sequoia (or older recent versions)  
- Internet connection  
- Terminal app (already built-in)

**Step 1 – Install yt-dlp (one time only)**

The easiest & recommended way uses **Homebrew** (a free package manager for macOS).

1. Open **Terminal** (press Cmd + Space → type “Terminal” → open it)

2. Install Homebrew (if you don't have it yet) — paste this and press Enter:

   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

   Follow the on-screen instructions (it may ask for your password).

3. Install yt-dlp:

   ```bash
   brew install yt-dlp
   ```

4. Check it works:

   ```bash
   yt-dlp --version
   ```

   You should see a version number.

(Alternative if you don't want Homebrew: download the binary from https://github.com/yt-dlp/yt-dlp/releases → yt-dlp_macos → make it executable with `chmod +x yt-dlp` and move to `/usr/local/bin/` — but Homebrew is simpler.)

**Step 2 – Get cookies.txt (important for age-restricted / members-only / "not a bot" videos)**

Safari does **not** support the "Get cookies.txt LOCALLY" extension directly (it's for Chrome/Edge).

Best options:

- Use **Chrome** or **Edge** on macOS (install from their websites)  
  → Install "Get cookies.txt LOCALLY" from Chrome Web Store / Edge Add-ons  
  → Log in to youtube.com  
  → Click extension icon → Export → save as `cookies.txt` (e.g. on Desktop)

- If you insist on Safari: use a tool like Cookie-Editor extension (available in Safari Extensions via App Store) or manually export cookies (more complicated — not recommended for beginners).

**Step 3 – Download and run the script**

1. Download `yt-dlpp.sh` (or copy-paste the bash code into TextEdit → save as plain text with .sh extension)

2. Open Terminal

3. Go to the folder where you saved it:

   ```bash
   cd ~/Desktop               # ← change to your folder, e.g. cd ~/Downloads
   ```

4. Make it executable:

   ```bash
   chmod +x yt-dlpp.sh
   ```

5. Run it:

   ```bash
   ./yt-dlpp.sh
   ```

**Step 4 – How to use it**

- Paste YouTube link (video or playlist)
- When it asks for cookies.txt path:  
  → type full path, example: `/Users/yourname/Desktop/cookies.txt`  
  → or drag the file from Finder into Terminal window (easiest — auto-fills path)  
  → press Enter (or just Enter to skip)
- Follow prompts for quality, selection, etc.

**Tips**

- If downloads time out → try different VPN/server or add more retries in script
- Re-export fresh cookies.txt if login/block issues return
- Update yt-dlp regularly: `brew upgrade yt-dlp`

Enjoy!

---

### Quick comparison note (for all platforms)

| Platform        | Script type       | yt-dlp install (easiest)          | Cookies method (recommended)             | Run command          | Notes                                     |
| --------------- | ----------------- | --------------------------------- | ---------------------------------------- | -------------------- | ----------------------------------------- |
| **Windows**     | PowerShell (.ps1) | `winget install yt-dlp`           | Chrome/Edge + Get cookies.txt LOCALLY    | `.\matthew_tube.ps1` | Drag file into PowerShell for path        |
| **Linux / WSL** | Bash (.sh)        | `sudo apt install yt-dlp` or curl | Chrome/Edge/Firefox + extension          | `./yt-dlpp.sh`       | Works great in WSL with proxy setup       |
| **macOS**       | Bash (.sh)        | `brew install yt-dlp`             | Chrome/Edge + extension (Safari limited) | `./yt-dlpp.sh`       | Homebrew is king — use Chrome for cookies |

All three versions use the same logic and prompts (URL → cookies path → quality → download).

If someone has Apple Silicon (M1/M2/M3/M4), Homebrew works perfectly (native support since years ago).



Have fun downloading!

---

***Mahdi Mostafavi***
