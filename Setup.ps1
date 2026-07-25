# ======================================================================= #
# =========================== Initialization ============================ #

# Fluff
Write-Host "BetterDiscord Updater Setup Script v2.0"
Write-Host "Copyright (c) 2026 Correlander - MIT License"
Write-Host "https://github.com/Correlander/better-discord-updater"

# Variables
[String]$directoryPath = Join-Path -Path $env:LOCALAPPDATA -ChildPath "BetterDiscordUpdater"
[String]$configPath = Join-Path -Path $directoryPath -ChildPath "config.cfg"

# ======================================================================= #
# ========================= Internal Functions ========================== #

function Run-Bootstrapping {# Installs core script and associated license, forcefully overwrites existing versions to accommodate any updates, installs default settings file if no existing settings file

    # Define variables
    [String]$updaterPath = Join-Path -Path $script:directoryPath -ChildPath "Updater.exe"
    [String]$licensePath = Join-Path -Path $script:directoryPath -ChildPath "LICENSE.txt"
    [String]$updaterUrl = 'https://raw.githubusercontent.com/Correlander/better-discord-updater/main/Updater.ps1'
    [String]$licenseUrl = 'https://raw.githubusercontent.com/Correlander/better-discord-updater/main/LICENSE'

    if (-not (Test-Path -Path $script:directoryPath)) {# Check if directory for the updater exists

        try {# If not, create it -- and any non-existing parent dirs
            Write-Host "`nCreating directory" -ForegroundColor Blue
            New-Item -Path $script:directoryPath -ItemType Directory -ErrorAction Stop | Out-Null
            Write-Host "Success" -ForegroundColor Green
        }
        catch {
            Write-Host "Error: Failed to create the directory `"$script:directoryPath`" - Please copy this error and open an issue" -ForegroundColor Red
            Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            Exit
        }
    }

    try {# Install Updater.exe

        # If it already exists, remove read only flag so we can overwrite
        if (Test-Path -Path $updaterPath) {
            Set-ItemProperty -Path $updaterPath -Name IsReadOnly -Value $false -ErrorAction Stop
        }

        Write-Host "`nInstalling Updater.exe" -ForegroundColor Blue
        Invoke-WebRequest -Uri $updaterUrl -OutFile $updaterPath -ErrorAction Stop
        Set-ItemProperty -Path $updaterPath -Name IsReadOnly -Value $true -ErrorAction Stop
        Write-Host "Success" -ForegroundColor Green
    }
    catch {
        Write-Host "Error: Failed to create the file `"Updater.exe`" - Please copy this error and open an issue" -ForegroundColor Red
        Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "`nPress any key to continue..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        Exit
    }

    try {# Install LICENSE

        # If it already exists, remove read only flag so we can overwrite
        if (Test-Path -Path $licensePath) {
            Set-ItemProperty -Path $licensePath -Name IsReadOnly -Value $false -ErrorAction Stop
        }

        Write-Host "`nInstalling LICENSE" -ForegroundColor Blue
        Invoke-WebRequest -Uri $licenseUrl -OutFile $licensePath -ErrorAction Stop
        Set-ItemProperty -Path $licensePath -Name IsReadOnly -Value $true -ErrorAction Stop
        Write-Host "Success" -ForegroundColor Green
    }
    catch {
        Write-Host "Error: Failed to create the file `"LICENSE`" - Please copy this error and open an issue" -ForegroundColor Red
        Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "`nPress any key to continue..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        Exit
    }

    if (-not (Test-Path -Path $script:configPath)) {# If no existing settings file
        Modify-Settings -SetDefault # Create it
    }
}

function Read-Config {# Load settings and return dictionary
    [OutputType([Hashtable])]

    try {
        $rawContent = Get-Content -Path $script:configPath -Raw -ErrorAction Stop
        $config = $rawContent | ConvertFrom-StringData -ErrorAction Stop
        return $config
    }
    catch {
        Write-Host "Error: Failed to load existing settings from disk - Please copy this error and open an issue" -ForegroundColor Red
        Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "`nPress any key to continue..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        Exit
    }
}

function Save-Config {# Saves given settings to file
    param (
        [Hashtable]$Settings
    )

    try {
        $formattedLines = $Settings.GetEnumerator() | ForEach-Object { "$($_.Name)=$($_.Value)" } -ErrorAction Stop
        Set-Content -Path $script:configPath -Value $formattedLines -Force -ErrorAction Stop
    }
    catch {
        Write-Host "Error: Failed to write configuration file to disk - Please copy this error and open an issue" -ForegroundColor Red
        Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "`nPress any key to continue..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        Exit
    }
}

function Modify-Settings {# Modifies an entry ($Branch) in the settings file to have a new value ($Path), or resets settings to default
    param (
        [String]$Branch,
        [String]$Path,
        [switch]$SetDefault
    )

    if ($SetDefault) {# If set default is declared
        # Create a hashtable of the default values
        [Hashtable]$settings = @{ 'Stable' = ''; 'Canary' = ''; 'PTB' = '' }
        # Then write it to disk and return
        Save-Config -Settings $settings
        return
    }

    # Get settings from config
    [Hashtable]$settings = Read-Config

    # Update the target branch value
    $settings[$Branch] = $Path
    if ($Path -eq "") {
        Write-Host "`nCleared directory path for Discord-$Branch"
    } else {
        Write-Host "`nSet path for Discord-$Branch to `"$Path`""
    }

    # Save modified settings to config
    Save-Config -Settings $settings
}

function Add-RegistryEntry {# Adds entry to the Registry so Updater.exe runs on startup

    # Define variables
    [String]$regKey = "BetterDiscordUpdater"
    [String]$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    [String]$exePath = Join-Path $script:directoryPath -ChildPath "Updater.exe"
    [String]$command = "`"$exePath`""
    
    try { # Try to create the registry entry      
        Set-ItemProperty -Path $regPath -Name $regKey -Value $command -ErrorAction Stop
        Write-Host "Wrote [Key: `"$regKey`" Value: `"$exePath`"] entry to the registry at `"Software\Microsoft\Windows\CurrentVersion\Run`"" -ForegroundColor Green
    }
    catch {
        Write-Host "Error: Failed to write entry to Registry - Please copy this error and open an issue" -ForegroundColor Red
        Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "`nPress any key to continue..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
}

function Remove-RegistryEntry {# Removes entry from the Registry so Updater.exe won't run on startup

    # Define variables
    [String]$regKey = "BetterDiscordUpdater"
    [String]$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"

    # Check if the registry key exists before trying to delete it
    if (Get-ItemProperty -Path $regPath -Name $regKey -ErrorAction SilentlyContinue) {
        try {# Try to delete the registry entry
            Remove-ItemProperty -Path $regPath -Name $regKey -ErrorAction Stop
            Write-Host "Deleted entry for `"BetterDiscordUpdater`" from the registry" -ForegroundColor Yellow
        }
        catch {
            Write-Host "Error: Failed to remove entry from Registry - Please copy this error and open an issue" -ForegroundColor Red
            Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        }
    } else {
        Write-Host "Warning: Attempted to delete a Registry entry, but no entry was found" -ForegroundColor Yellow
    }
}

function Get-DefaultPath {# Attempts to find the default installation path for a Branch, returns the path if found and "" if not
    [OutputType([String])]
    param (
        $Branch
    )

    [String]$discordDirectory
    switch ($Branch) {# Discord has nothing signifying a stable branch, but I need to identify the stable branch's difference in my code, hence the switch statement for an accurate directory name
        'Stable' {
            $discordDirectory = "Discord"
        }
        'Canary' {
            $discordDirectory = "DiscordCanary"
        }
        'PTB' {
            $discordDirectory = "DiscordPTB"
        }
        default {
            Write-Host "Error: Find-Default-Path was called with an invalid `$Branch flag -> `"$Branch`"" -ForegroundColor Red
            Exit
        }
    }

    $discordPath = Join-Path -Path $env:LOCALAPPDATA -ChildPath $discordDirectory
    if (Test-Path -Path (Join-Path -Path $discordPath -ChildPath "Update.exe"))
    {
        Write-Host "Installation at Default path `"$discordPath`" automatically found" -ForegroundColor Green
        return $discordPath
    } else {
        Write-Host "Installation at Default path `"$discordPath`" not found" -ForegroundColor Yellow
        return ""
    }
}

function Full-Uninstall {# Fully uninstalls all files and tasks associated with the BD Automatic Updater

    # Remove entry from registry
    Remove-RegistryEntry

    # Wipe the parent directory that contains all related program files
    Remove-Item -Path $script:directoryPath -Recurse -Force
    Write-Host "All files have been deleted" -ForegroundColor Green
}

# ======================================================================= #
# ============================ UI Functions ============================= #

function Main-Menu {# UI logic regarding the main menu

    while ($true) {

        Clear-Host
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "   BetterDiscord Updater - Setup v2.0   " -ForegroundColor Cyan
        Write-Host "========================================`n" -ForegroundColor Cyan

        # Give prompts
        Write-Host "[1] Configure Auto-Updater"
        Write-Host "[2] Full Uninstall"
        Write-Host "[3] Exit"

        # Get user's input
        $choice = Read-Host -Prompt "Type an option (1-3) and press enter"

        switch ($choice) {
            '1' {
                Update-Management-Menu
            }
            '2' {
                Full-Uninstall-Menu
            }
            '3' {
                Exit
            }
            default {
                Clear-Host
                Write-Host "`nInvalid Selection, please only enter a number between 1 and 3" -ForegroundColor Red
                Start-Sleep -Seconds 3 # Pauses for 3 seconds so they can see their mistake in bright red before it refreshes and allows them to try again
            }
        }
    }
}

function Update-Management-Menu {# UI logic regarding the Background Updates sub-menu

    while ($true) {# Hold user in this sub-menu until the function returns

        Clear-Host
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "         Configure Auto-Updater         " -ForegroundColor Cyan
        Write-Host "========================================`n" -ForegroundColor Cyan
        Write-Host "Choose a number to swap whether the branch is automatically updated on startup" -ForegroundColor Magenta
        Write-Host "Note: If you need to change an installation path that has been set, turn the Discord branch you wish to change off and on again`n`n" -ForegroundColor DarkGray

        # Get settings
        [Hashtable]$settings = Read-Config

        # Give (dynamic) prompts
        [String[]]$branches = @('Stable', 'Canary', 'PTB')
        $menuNumber = 1
        foreach ($branch in $branches) {
            [String]$path = $settings[$branch]
            [String]$paddedName = $branch.padRight(6)

            Write-Host "[$menuNumber] Discord-$paddedName : [ " -NoNewLine

            if ([String]::IsNullOrWhiteSpace($path)) {
                Write-Host "DISABLED" -ForegroundColor DarkGray -NoNewLine
                Write-Host " ]"
            } else {
                Write-Host "ENABLED " -ForegroundColor Green -NoNewLine
                Write-Host " ] -> $path"
            }
            $menuNumber++
        }
        Write-Host "[4] Back"

        # Get user's input
        $choice = Read-Host -Prompt "Type an option (1-4) and press enter"

        # Map the choice to the branch
        [String]$selectedBranch
        switch ($choice) {
            '1' { $selectedBranch = 'Stable' }
            '2' { $selectedBranch = 'Canary' }
            '3' { $selectedBranch = 'PTB' }
            '4' { return }
            default {
                Clear-Host
                Write-Host "`nInvalid Selection, please only enter a number between 1 and 4" -ForegroundColor Red
                Start-Sleep -Seconds 3 # Pauses for 3 seconds so they can see their mistake in bright red before it refreshes and allows them to try again
                continue
            }
        }

        # Toggling Logic
        if ([String]::IsNullOrWhiteSpace($settings[$selectedBranch])) {
            Write-Host "Adding automatic updates for Discord-$selectedBranch" -ForegroundColor Green

            # Get path
            [String]$path = Get-DefaultPath -Branch $selectedBranch

            if ($path -ne "") {# If default path found
                Write-Host "Default path found at `"$path`", would you like to use it?"
                $choice = Read-Host -Prompt "Would you like to use it? type `"yes`" if so"
                if ($choice -ne 'yes') {
                    $path = "" # Clear it because they don't want to install wherever the default path was found, supports edge case of them having a second install that's not the default
                }
            }

            if ([String]::IsNullOrWhiteSpace($path)) {# If path still hasn't been decided after looking for default
                Write-Host "`nEnter the path to your installation for Discord-$selectedBranch"
                $path = Enter-Custom-Path
            }

            if ([String]::IsNullOrWhiteSpace($path)) {# If path is still an empty string, the user chose to cancel the setup
                Write-Host "Aborting installation of Auto-Updater for Discord-$selectedBranch" -ForegroundColor Yellow
                Start-Sleep -Seconds 2
                Continue # Skip rest of loop if aborting
            }

            # Store the chosen path and add registry entry
            Modify-Settings -Branch $selectedBranch -Path $path
            Add-RegistryEntry
        } else {
            Write-Host "Removing automatic updates for Discord-$selectedBranch" -ForegroundColor Yellow
            Modify-Settings -Branch $selectedBranch -Path ""
            
            # Refresh settings variable
            [Hashtable]$settings = Read-Config

            # If no branches are enabled, remove the Registry entry so Updater.exe isn't pointlessly running on startup
            [bool]$anyActive = $false
            foreach ($branch in $branches) {
                if (-not ([String]::IsNullOrWhiteSpace($settings[$branch]))) {
                    $anyActive = $true
                    break # exit early if set true
                }
            }
            # Remove registry entry if no branches are active
            if (-not $anyActive) { Remove-RegistryEntry }
        }

        # Pause at the end of the logic so user can bear witness to any outputs before cycling back to a clean menu
        Start-Sleep -Seconds 3
    }
}

function Enter-Custom-Path {# UI logic regarding entering a custom file path, returns the path user entered or "" if cancelled
    [OutputType([String])]

    Write-Host "Make sure provided path is the ABSOLUTE PATH for the folder containing `"Update.exe`""
    Write-Host "In File Explorer, navigate into the folder, right click the address bar, and click `"Copy address as text`"" -ForegroundColor DarkGray
    Write-Host "`n(A valid path is required. You can type 'cancel' to abort)" -ForegroundColor Yellow

    while ($true) {
        
        # Grab input
        $newPath = Read-Host -Prompt "Path"
        # Trim the input of string signifiers, in case the user enters them thinking they are needed
        $newPath = $newPath.Trim('"').Trim("'")

        # Handle the cancel keyword
        if ($newPath.ToLower() -eq 'cancel') {
            return ""
        }

        # Handle blank inputs
        if ([String]::IsNullOrWhiteSpace($newPath)) { # While an edge case, I only check for these to avoid the possibility of an Update.exe being in whatever the working directory is, and a possible false positive for passing the check
            Write-Host "`nInvalid Path: A valid path is required, type 'cancel' to abort, or enter a valid path" -ForegroundColor Yellow
            Continue # So there aren't two error messages
        }

        # Validation Step, if neither special case met
        if (Test-Path (Join-Path -Path $newPath -ChildPath "Update.exe")) {
            return $newPath
        } else {
            Write-Host "`nInvalid Path: Discord does not exist within that directory, please verify and try again" -ForegroundColor Yellow
        }
    }
}

function Full-Uninstall-Menu {# UI logic regarding the sub-menu for confirming a full uninstall
    
    while ($true) {# Hold user in this sub-menu until the function returns

        Clear-Host
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "             FULL UNINSTALL             " -ForegroundColor Cyan
        Write-Host "========================================`n" -ForegroundColor Cyan

        Write-Host "Proceeding will fully delete all files and tasks associated with this updater." -ForegroundColor Yellow
        Write-Host "Type `"DELETE`" to proceed with the full uninstall" -ForegroundColor White
        Write-Host "Type anything else to cancel`n" -ForegroundColor DarkGray
        
        $choice = Read-Host -Prompt "Press Enter to submit input"

        if ($choice -eq 'DELETE') {
            Full-Uninstall
            Write-Host "Uninstallation complete. Exiting..." -ForegroundColor Green
            Exit
        } else {
            return
        }
    }
}

function Run-FirstInstallPrompts {# Simplistic install menu you're automatically put into on first run, will simplify the experience and make it as accessible as possible for edge cases in the people's understanding department

    [String]$path

    # FIND PATH SECTION
    # path found for discord stable, do you want to use it? if yes proceed using this found path
    # path found for discord canary, do you want to use it? if yes proceed using this found path
    # path found for discord ptb, do you want to use it? if yes proceed using this found path
    # no paths found/said yes to, enter path to discord installation or type EXIT to exit

    # No paths found, ask for custom installation path or for them to exit
    #Write-Host "`nEnter the path to your installation of Discord you'd like to automatically update"
    #$path = Enter-Custom-Path
    #if ($path -eq "") {
    #    "Abandoning installation" -ForegroundColor Yellow
    #}





# Run default path for all branches
# If found ask if they want to use it, if not say it's not found
# If it wasn't found or they said they don't want to use it
}

# ======================================================================= #
# ============================ Script Logic ============================= #

# Check if this is their first time running the installer
[bool]$firstInstall = $false # NOT ACTUALLY CHECKED YET, DUMMY VALUE

# Install core files - reinstalls regardless of first install, so that it will update itself on Setup run
Run-Bootstrapping

# Let user read the outputs from those bootstrapping operations so screen isn't just flashing
Write-Host "`nBootstrapping complete, proceeding to menu..."
Start-Sleep -Seconds 3

# If it's the first time installing this, run the first install menu
#if ($firstInstall) {
#    Run-FirstInstallPrompts
#}

# Go to main menu for any further management (post initial install, or running the setup again to further manage things)
Main-Menu