# Fluff
Write-Host "BetterDiscord Updater Setup Script v1.2"
Write-Host "Copyright (c) 2024 Correlander - MIT License"
Write-Host "https://github.com/Correlander/better-discord-updater"
Write-Host "`n"

# Function for prompts to handle startup. Add or remove Updater.ps1 to startup.
function Startup-Manager {

    # Give prompts
    Write-Host "Enter a number to select one of the following options:" -ForegroundColor DarkMagenta -BackgroundColor Black
    Write-Host "[0] Add BetterDiscord Updater to startup."
    Write-Host "[1] Remove BetterDiscord Updater from startup."
    Write-Host "[2] Back."

    [bool]$choosing = $true

    # Input loop
    while ($choosing) {

        # Get user's input
        $input = Read-Host -Prompt "Type a number then press Enter"

        # Define path to shortcut
        [String]$shortcutPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\BetterDiscordUpdater.lnk"

        switch ($input) {
            '0' {
                # Create the shortcut and save it in the startup folder
                [String]$targetPath = "powershell.exe"
                [String]$arguments = "-NoProfile -WindowStyle Minimized -ExecutionPolicy Bypass -File $env:LOCALAPPDATA\BetterDiscordUpdater\Updater.ps1"

                $shell = New-Object -ComObject WScript.Shell
                $shortcut = $shell.CreateShortcut($shortcutPath)

                $shortcut.TargetPath = $targetPath
                $shortcut.Arguments = $arguments
                $shortcut.Description = 'Shortcut that adds the updater script for better discord to windows startup.'

                $shortcut.Save()

                Write-Host "The shortcut was created! If you haven't installed the script yet, this will NOT WORK. Make sure to go through the install for the script as well!" -ForegroundColor Green -BackgroundColor Black
            }
            '1' {
                # Remove the startup shortcut, if it exists
                if (Test-Path -Path $shortcutPath) {
                    Remove-Item -Path $shortcutPath
                    Write-Host "Removed the shortcut from startup!" -ForegroundColor Green -BackgroundColor Black
                } else {
                    Write-Host "There was no shortcut to remove! You're already good to go." -ForegroundColor Green -BackgroundColor Black
                }
            }
            '2' {
                Write-Host "Going to main menu...`n`n" -ForegroundColor Blue -BackgroundColor Black
                $choosing = $false
            }
            default {
                Write-Host "That is not a valid input... try again." -ForegroundColor Red -BackgroundColor Black
            }
        }
    }
}

# Function to go through settings setup
function Setup-Settings {
    [string]$branch
    [string]$installationsParentPath

    [bool]$choosing = $true

    # Give prompts
    Write-Host "Enter a number to select one of the following Discord branches:" -ForegroundColor DarkMagenta -BackgroundColor Black
    Write-Host "[0] Discord."
    Write-Host "[1] DiscordPTB."
    Write-Host "[2] DiscordCanary."

    # Input loop
    while ($choosing) {

        # Get user's input
        $input = Read-Host -Prompt "Type a number then press Enter"

        switch ($input) {
            '0' {
                Write-Host "You've chosen Discord." -ForegroundColor Blue -BackgroundColor Black
                $branch = 'Discord'
                $choosing = $false
            }
            '1' {
                Write-Host "You've chosen DiscordPTB." -ForegroundColor Blue -BackgroundColor Black
                $branch = 'DiscordPTB'
                $choosing = $false
            }
            '2' {
                Write-Host "You've choice DiscordCanary." -ForegroundColor Blue -BackgroundColor Black
                $branch = 'DiscordCanary'
                $choosing = $false
            }
            default {
                Write-Host "That is not a valid input... try again.`n`n" -ForegroundColor Red -BackgroundColor Black
            }
        }
    }

    $parentPath = "$env:LOCALAPPDATA\$branch"
    if (Test-Path -Path "$parentPath\Update.exe")
    {
        Write-Host "Automatically found install path at `"$parentPath`"." -ForegroundColor Blue -BackgroundColor Black
    }
    else
    {
        while ($true)
        {
            $installationsParentPath = Read-Host -Prompt "Couldn't automatically find your Discord installation folder at `"$parentPath`".`nPlease type in the absolute path for the folder containing `"Update.exe`" (if you navigate to it, right click the address bar and click `"Copy address as text`").`n"
            if (Test-Path -Path "$parentPath\Update.exe")
            {
                Write-Host "Successfully found your install folder at `"$installationsParentPath`". Thanks!" -ForegroundColor Blue -BackgroundColor Black
                Break
            }
            else
            {
                Write-Host "The path you entered wasn't valid, please try again." -ForegroundColor Red -BackgroundColor Black
            }
        }
    }

    # Now that we have both valid values, save them to file
    $branch,$parentPath,'' | Out-File -FilePath "$env:LOCALAPPDATA\BetterDiscordUpdater\settings.txt"
    Write-Host "Entered settings have been saved to file.`n`n" -ForegroundColor Green -BackgroundColor Black
}

# Function for prompts to handle settings. Check if they are valid still, and/or go through setup again.
function Settings-Manager {

    # Give prompts
    Write-Host "Enter a number to select one of the following options:" -ForegroundColor DarkMagenta -BackgroundColor Black
    Write-Host "[0] Check if settings are valid."
    Write-Host "[1] Go through settings setup again."
    Write-Host "[2] Back."

    [bool]$choosing = $true

    # Input loop
    while ($choosing) {
        
        # Get user's input
        $input = Read-Host -Prompt "Type a number then press Enter"

        switch ($input) {
            '0' {
                [bool]$validInstallPath = $false
                [bool]$validBranch = $false

                # Check if the settings file exists
                if (Test-Path -Path ".\settings.txt") {
                    
                    [array]$settings = Get-Content 'settings.txt'
                    $branch = $settings[0]
                    $parentPath = $settings[1]

                    # Check if Branch is valid
                    if (($branch -eq 'Discord') -or ($branch -eq 'DiscordPTB') -or ($branch -eq 'DiscordCanary')) {
                        $validBranch = $true

                        # Since branch was valid, check parent path
                        if (Test-Path "$env:LOCALAPPDATA\$branch\Update.exe") {
                            $validInstallPath = $true
                        } else {
                            Write-Host "Your branch setting is valid, but the install path doesn't appear to be valid. Please go through settings setup again." -ForegroundColor Red -BackgroundColor Black
                        }
                    } else {
                        Write-Host "The branch setting is corrupted. Please go through settings setup again." -ForegroundColor Red -BackgroundColor Black
                    }
                } else {
                    Write-Host "Your settings file doesn't seem to even exist... Please run install once if you haven't already. If you have, and your settings file has disappeared, please go through setup again." -ForegroundColor Red -BackgroundColor Black
                }

                # If settings are valid, let user know
                if (($validBranch) -and ($validInstallPath)) {
                    Write-Host "Your settings file is valid." -ForegroundColor Green -BackgroundColor Black
                }
            }
            '1' {
                Setup-Settings
            }
            '2' {
                Write-Host "Going to main menu...`n`n" -ForegroundColor Blue -BackgroundColor Black
                $choosing = $false
            }
            default {
                Write-Host "That is not a valid input... try again." -ForegroundColor Red -BackgroundColor Black
            }
        }
    }
}

# Function to install the updater script
function Run-Installer {
    
    # Define the directory and file paths
    [String]$directoryPath = "$env:LOCALAPPDATA\BetterDiscordUpdater"
    [String]$fileName = "Updater.ps1"
    [String]$updaterFilePath = Join-Path -Path $directoryPath -ChildPath "Updater.ps1"
    [String]$licenseFilePath = Join-Path -Path $directoryPath -ChildPath "LICENSE.txt"
    [String]$updaterFileUrl = 'https://raw.githubusercontent.com/Correlander/better-discord-updater/main/Updater.ps1'
    [String]$licenseFileUrl = 'https://raw.githubusercontent.com/Correlander/better-discord-updater/main/LICENSE'

    # Check if directory is setup for the script/license
    if (-not (Test-Path -Path $directoryPath)) {
        # If not, create it -- and any non-existing parent dirs
        New-Item -Path $directoryPath -ItemType Directory -ErrorAction SilentlyContinue
    }

    # Install Updater.ps1 and LICENSE.txt
    Invoke-WebRequest -Uri $updaterFileUrl -OutFile $updaterFilePath
    Invoke-WebRequest -Uri $licenseFileUrl -OutFile $licenseFilePath

    Setup-Settings
}

# Main 'logic' for the UI

while ($true) {
    
    # Give prompts
    Write-Host "Enter a number to select one of the following options:" -ForegroundColor DarkMagenta -BackgroundColor Black
    Write-Host "[0] Install the BetterDiscord updater script (will erase current settings and go through setup again. can be used to reinstall, will delete existing script if it exists)."
    Write-Host "[1] Startup manager (add/remove script to/from startup)."
    Write-Host "[2] Settings manager (check if settings are valid, go through setup again)."
    Write-Host "[3] Exit."

    [bool]$choosing = $true

    while ($choosing) {

        # Get user's input
        $input = Read-Host -Prompt "Type a number and press Enter"

        switch ($input) {
            '0' {
                Write-Host "Going to installation menu..." -ForegroundColor Blue -BackgroundColor Black
                Run-Installer
                $choosing = $false
            }
            '1' {
                Write-Host "Going to startup menu...`n`n" -ForegroundColor Blue -BackgroundColor Black
                Startup-Manager
                $choosing = $false
            }
            '2' {
                Write-Host "Going to settings menu...`n`n" -ForegroundColor Blue -BackgroundColor Black
                Settings-Manager
                $choosing = $false
            }
            '3' {
                Exit
            }
            default {
                Write-Host "That is not a valid input... try again." -ForegroundColor Red -BackgroundColor Black
            }
        }
    }
}