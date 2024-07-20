# ======================================================================= #
# =========================== Initialization ============================ #

[string]$LOCALAPPDATA = "$env:LOCALAPPDATA"
[string]$APPDATA = "$env:APPDATA"

# Set working directory to the folder the script is stored in. Just lets me be lazier with file references
Set-Location -Path $PSScriptRoot

# Create new log
'Updater.ps1 Running - BetterDiscord-AutoInstaller v1.0' | Out-File -FilePath 'latest.log'
"https://github.link.here.i'll.make.one.later" | Add-Content 'latest.log'

# Make sure settings are valid before proceeding
"Checking validity of 'settings.txt'." | Add-Content 'latest.log'
if (-not([System.IO.File]::Exists('settings.txt')))
{
    "Settings file doesn't exist, please run Setup.ps1." | Add-Content 'latest.log'
    Exit
}
else
{
    [bool]$VALID_INSTALL_PATH = $false
    [bool]$VALID_BRANCH = $false

    [array]$SETTINGS = Get-Content 'settings.txt'

    [string]$BRANCH = $SETTINGS[0]
    [string]$PARENT_PATH = $SETTINGS[1]
    [string]$LAST_INSTALLED_VERSION = $SETTINGS[2]

    if (($BRANCH -eq 'Discord') -or ($BRANCH -eq 'DiscordPTB') -or ($BRANCH -eq 'DiscordCanary'))
    {
        $VALID_BRANCH = $true
    }
    if ($VALID_BRANCH)
    {
        if ([System.IO.File]::Exists("$PARENT_PATH\Update.exe"))
        {
            $script:VALID_INSTALL_PATH = $true
        }
    }

    if ((-not $VALID_BRANCH) -or (-not $VALID_INSTALL_PATH))
    {
        "Settings file is corrupted. Please run Setup.ps1 again." | Add-Content 'latest.log'
        Exit
    }
}

# If it reaches this point, settings are valid
"Settings are confirmed valid.`nBranch - `"$BRANCH`"`nInstallations Parent Path - `"$PARENT_PATH`"`nLast Installed Version - '$LAST_INSTALLED_VERSION'." | Add-Content 'latest.log'



# ======================================================================= #
# ============================== Updating =============================== #

$PROCESSES = Get-WmiObject Win32_Process -Filter "name = '$script:BRANCH.exe'" | Select-Object CommandLine, ProcessId
# Function to update PROCESSES variable with current list. Not necessarry, but lets me type more lazily
function UPL
{
    $script:PROCESSES = Get-WmiObject Win32_Process -Filter "name = '$script:BRANCH.exe'" | Select-Object CommandLine, ProcessId
}

# Function to start discord
function StartDiscord
{
    Start-Process -FilePath "$script:PARENT_PATH\Update.exe" -ArgumentList "--processStart $script:BRANCH.exe"
}

# Check if discord is already open
if ($PROCESSES.Length -lt 1)
{ # if discord isn't open, start it
    "Discord isn't open. Starting it" | Add-Content 'latest.log'
    StartDiscord
    while ($true)
    { # wait for it to open
        [int]$FAILURES = 0
        if ($FAILURES -gt 60)
        { # If it has ran 60 times without success, just exit the script, something went wrong or the pc is lagging terribly
            "Script waited 60 seconds for Discord to start, and it never started. Exiting..." | Add-Content 'latest.log'
            Exit
        }

        UPL # Update processes
        if (-not $PROCESSES.Length -lt 1)
        { # If it's open break out of the loop
            break
        }
        else
        {
            $FAILURES = $FAILURES + 1
        }

        Start-Sleep -Seconds 1
    }
}

# Now that discord is running, wait for it to finish updating
[bool]$DISCORD_UPDATING = $true
"Waiting for Discord to finish updating..." | Add-Content 'latest.log'
while ($DISCORD_UPDATING)
{ # Exit this loop once it finishes updating
    UPL
    foreach ($process in $PROCESSES)
    {
        [string]$filterArgs = $process | Select-String -Pattern '--service-sandbox-type=audio'
        if ($filterArgs.Length -gt 0)
        {
            $DISCORD_UPDATING = $false
        }
    }
    if ($DISCORD_UPDATING) { Start-Sleep -Seconds 5 } # wait 5 seconds to check again
}
"Discord finished updating. Killing it." | Add-Content 'latest.log'

# Now that discord is up to date, kill it
while ($true)
{
    UPL
    foreach($process in $PROCESSES)
    { # Kill each Discord process
        Stop-Process -Id $process.ProcessId -ErrorAction SilentlyContinue
    }
    UPL
    if (-not $PROCESSES.Length -lt 1)
    { # if Discord processes are still open, if they are, wait a second for the killing to finish
        Start-Sleep -Seconds 2
    }
    else
    { # if they are closed, break the loop
        break
    }
}
"Discord processes have all been killed. Comparing versions." | Add-Content 'latest.log'

# Compare last installed to latest installed
[string]$LATEST_INSTALLED_VERSION = (Get-ChildItem -Path $PARENT_PATH -Directory | Where-Object Name -match app)[-1]
if ($LAST_INSTALLED_VERSION -eq $LATEST_INSTALLED_VERSION)
{
    "Last installed version matches the latest version. Starting Discord then exiting updater." | Add-Content 'latest.log'
    #StartDiscord
    #Exit
}

# If script reaches this point, need to install a BD update.
# Make sure required folders for download exists
[array]$BD_REQUIRED_FOLDERS = "$APPDATA\betterdiscord","$APPDATA\betterdiscord\data","$APPDATA\betterdiscord\themes","$APPDATA\betterdiscord\plugins"
"Checking for required BetterDiscord folders..." | Add-Content 'latest.log'
foreach ($folderPath in $BD_REQUIRED_FOLDERS)
{
    New-Item -ItemType Directory -Path $folderPath -ErrorAction SilentlyContinue
}

# Download BD asar
[string]$BD_ASAR_URL = 'https://github.com/rauenzi/BetterDiscordApp/releases/latest/download/betterdiscord.asar'
[string]$BD_ASAR_SAVE_PATH = "$APPDATA\BetterDiscord\data\betterdiscord.asar"
Invoke-WebRequest $BD_ASAR_URL -OutFile $BD_ASAR_SAVE_PATH
"Asar file downloaded to `"$BD_ASAR_SAVE_PATH`"" | Add-Content 'latest.log'



# Patch the startup script
"Trying to patch the BD startup script..." | Add-Content 'latest.log'

# Firstly though, construct path to index.js
[string]$DISCORD_PATH = Join-Path -Path $PARENT_PATH -ChildPath (Get-ChildItem -Path $PARENT_PATH -Directory | Where-Object Name -match app)[-1] # Two different ways
$DESKTOP_CORE_FOLDER = Get-ChildItem -Path "$DISCORD_PATH\modules" -Directory | Where-Object { $_.Name -like 'discord_desktop_core-*' } | Select-Object -First 1 # To do same thing
[string]$INDEX_JS_PATH = Join-Path -Path $DESKTOP_CORE_FOLDER.FullName -ChildPath 'discord_desktop_core\index.js'

[array]$CONTENT = Get-Content -Path $INDEX_JS_PATH -Raw -Encoding UTF8
if ($CONTENT -match "betterdiscord.asar")
{
    "Discord startup script already patched. Proceeding" | Add-Content 'latest.log'
}
else
{
    $patchLine = "require(`"$BD_ASAR_SAVE_PATH`");`n" -replace '\\', '/'
    $CONTENT = $patchLine + $CONTENT
    Set-Content -Path $INDEX_JS_PATH -Value $CONTENT -Encoding UTF8
    "Discord startup script has been patched. Proceeding" | Add-Content 'latest.log'
}

# Should be good to go. Update settings, startup discord, then exit
$BRANCH,$PARENT_PATH,$LATEST_INSTALLED_VERSION | Out-File -FilePath 'settings.txt' # Write to settings
StartDiscord
"Installation complete! Exiting." | Add-Content 'latest.log' # Finish log
Exit

# ONCE THIS IS WORKING UNCOMMENT THE STUFF IN VERSION COMPARISON THAT EXITS