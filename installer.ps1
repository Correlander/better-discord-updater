# ANSI code variables for ease of use
$bold = "`e[1m"
$green = "`e[32m"
$blue = "`e[34m"
$reset = "`e[0m"

# Fluff
Write-Host "${bold}`e]35mBetterDiscord Updater Install Script v1.1${reset}"
Write-Host "Copyright (c) 2024 Correlander - MIT License"
Write-Host "https://github.com/Correlander/better-discord-updater"

# Define the directory and file paths
[String]$directoryPath = "$env:LOCALAPPDATA\BetterDiscordUpdater"
[String]$fileName = "Updater.ps1"
[String]$updaterFilePath = Join-Path -Path $directoryPath -ChildPath "Updater.ps1"
[String]$licenseFilePath = Join-Path -Path $directoryPath -ChildPath "LICENSE"
[String]$updaterFileUrl = 'https://raw.githubusercontent.com/Correlander/better-discord-updater/main/Updater.ps1'
[String]$licenseFileUrl = 'https://raw.githubusercontent.com/Correlander/better-discord-updater/main/LICENSE'

# Main block of logic, lets user make a choice and then offers them those choices again until they exit to let them set everything up
while ($true) {
    [String]$input

    Write-Host "Enter a number to select one of the following options:"
    Write-Host "[0] Install the BetterDiscord updater script."
    Write-Host "[1] Add or remove the BetterDiscord updater script from startup."
    Write-Host "[2] Exit."

    [bool]$choosing = $true

    while ($choosing) {

        # Get user's input
        $input = Read-Host -Prompt "Type a number then press Enter"

        # Do different things base off that input
        switch ($input) {
            '0' {
                # Check if the directory exists
                if (-not (Test-Path -Path $directoryPath)) {
                    # If not, create it -- and any non-existing parent directories
                    New-Item -Path $directoryPath -ItemType Directory -ErrorAction SilentlyContinue
                }
                # Check if the file exists
                if (-not (Test-Path -Path $updaterFilePath)) {
                    # If not, download the file
                    Invoke-WebRequest -Uri $updaterFileUrl -OutFile $updaterFilePath
                    Invoke-WebRequest -Uri $licenseFileUrl -OutFile $licenseFilePath
                    Write-Output "Downloaded $fileName to $directoryPath."
                } else {
                    Write-Output "$fileName already exists in $directoryPath."
                }
            }
            '1'{
                # Give them new prompts
                Write-Host "Enter a number to select one of the following options:"
                Write-Host "[0] Add BetterDiscord Updater to startup."
                Write-Host "[1] Remove BetterDiscord Updater from startup."
                Write-Host "[2] Back."

                [bool]$choosing

                while ($choosing) {
                    
                    # Get user's input
                    $input = Read-Host -Prompt "Type a number then press Enter"

                    switch ($input) {
                        '0' {
                            # Create the shortcut and save it in the startup folder
                            [String]$shortcutPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\BetterDiscordUpdater.lnk"
                            [String]$targetPath = "powershell.exe"
                            [String]$arguments = "-NoProfile -WindowStyle Minimized -ExecutionPolicy Bypass -File $env:LOCALAPPDATA\BetterDiscordUpdater\Updater.ps1"

                            $shell = New-Object -ComObject WScript.Shell
                            $shortcut = $shell.CreateShortcut($shortcutPath)

                            $shortcut.TargetPath = $targetPath
                            $shortcut.Arguments = $arguments
                            $shortcut.Description = 'Shortcut that adds the updater script for better discord to windows startup.'

                            $shortcut.Save()
                        }
                        '1' {
                            # Remove the startup shortcut, if it exists
                            if (Test-Path -Path $shortcutPath) {
                                Remove-Item -Path $shortcutPath
                            }
                        }
                        '2' {
                            $choosing = $false
                        }
                        default {
                            Write-Host "That is not a valid input... try again."
                        }
                    }
                }
            }
            '2'{
                Write-Host 'Exiting. Goodbye...'
                Start-Sleep -Seconds 3
                Exit
            }
            default {
                Write-Host 'That is not a valid input... try again.'
            }
        }
    }  
}