# ======================================================================= #
# =========================== Initialization ============================ #

# Fluff
Write-Host "BetterDiscord Updater Setup Script v2.0"
Write-Host "Copyright (c) 2026 Correlander - MIT License"
Write-Host "https://github.com/Correlander/better-discord-updater"
Write-Host "`n"

# Variables
[String]$directoryPath = Join-Path -Path $env:LOCALAPPDATA -ChildPath "BetterDiscordUpdater"
[String]$configPath = Join-Path -Path $directoryPath -ChildPath "config.json"

# ======================================================================= #
# ========================= Internal Functions ========================== #

function Script-Bootstrapping {# Installs core script and associated license, forcefully overwrites existing versions to accommodate any updates, installs default settings file if no existing settings file

    # Define variables
    [String]$updaterPath = Join-Path -Path $script:directoryPath -ChildPath "Updater.ps1"
    [String]$licensePath = Join-Path -Path $script:directoryPath -ChildPath "LICENSE.txt"
    [String]$updaterUrl = 'https://raw.githubusercontent.com/Correlander/better-discord-updater/main/Updater.ps1'
    [String]$licenseUrl = 'https://raw.githubusercontent.com/Correlander/better-discord-updater/main/LICENSE'

    if (-not (Test-Path -Path $script:directoryPath)) {# Check if directory for the updater exists
        
        try {# If not, create it -- and any non-existing parent dirs
            Write-Host "Creating directory" -ForegroundColor Blue -BackgroundColor Black
            New-Item -Path $script:directoryPath -ItemType Directory -ErrorAction Stop | Out-Null
            Write-Host "Succeeded" -ForegroundColor Blue -BackgroundColor Black
        }
        catch {
            Write-Host "Error: Failed to create the directory [$script:directoryPath]" -ForegroundColor White -BackgroundColor DarkRed
            Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Red -BackgroundColor Black
        }
    }

    try {# Install Updater.ps1
        Write-Host "Installing Updater.ps1" -ForegroundColor Blue -BackgroundColor Black
        Invoke-WebRequest -U -OutFi -ErrorAction Stop
        Set-ItemProperty -Pa -Name IsReadOnly -Value $true -ErrorAction Stop
        Write-Host "Succeeded" -ForegroundColor Blue -BackgroundColor Black
    }
    catch {
        Write-Host "Error: Failed to create the file a]" -ForegroundColor White -BackgroundColor DarkRed
        Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Red -BackgroundColor Black
    }

    try {# Install LICENSE
        Write-Host "Installing LICENSE" -ForegroundColor Blue -BackgroundColor Black
        Invoke-WebRequest -U -OutFi -ErrorAction Stop
        Set-ItemProperty -Pa -Name IsReadOnly -Value $true -ErrorAction Stop
        Write-Host "Succeeded" -ForegroundColor Blue -BackgroundColor Black
    }
    catch {
        Write-Host "Error: Failed to create the file a]" -ForegroundColor White -BackgroundColor DarkRed
        Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Red -BackgroundColor Black
    }

    if (-not (Test-Path -Path $script:configPath)) {# If no existing settings file
        Default-Settings # Create it
    }
}

function Default-Settings {# Create/overwrite the settings file such that is in the default state

    $defaultSettings = @{# Create a hashtable of the default values
        'Stable' = ""
        'Canary' = ""
        'PTB' = ""
    }

    # Then convert it to JSON and write it to disk
    $defaultSettings | ConvertTo-Json | Out-File -FilePath $script:configPath -Force
}

function Modify-Setting {# Modifies an entry ($Branch) in the settings file to have a new value ($Path)
    param (
        $Branch
        $Path
    )

    $config = Get-Content -Path $script:configPath | ConvertFrom-Json

    if ($Path -eq "") {
        $config.$Branch = ""
        Write-Host "`nSet path for $Branch to Default." -ForegroundColor Green
    } else {
        $config.$Branch = $Path
        Write-Host "`nSet path for $Branch to `"$Path`"." -ForegroundColor Green
    }

    # Write the updated object back to the JSON file
    $config | ConvertTo-Json | Out-File -FilePath $script:configPath -Force
}

function Find-Default-Path {# Attempts to find the default installation path for a Branch, returns true if found and false if not
    [OutputType([bool])]
    param (
        $Branch
    )
    # incomplete, not used in logic yet anyways
}

function Modify-Task {# Adds or removes tasks associated with this program within the Windows Task Scheduler
    param(# Parameters
        [String]$Type
        [String]$Branch
    )

    # Define variables
    $taskName = "BetterDiscordUpdater$branch"

    switch ($Type) {
        'add' {# Add a task to Windows Task Scheduler that will run the updater script upon user login for the specified Discord branch
            try {
                # Define task creation parameters
                $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$script:directoryPath\Updater.ps1`" -Branch `"$Branch`""
                $trigger = New-ScheduledTaskTrigger -AtLogOn
                $settings = New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
                $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive

                # Create the task
                Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force -ErrorAction Stop | Out-Null

                Write-Host "Scheduled Task created successfully!" -ForegroundColor Green -BackgroundColor Black
            }
            catch {# Used -ErrorAction Stop, so any error with registering the scheduled task will be considered termination worthy.
                Write-Host "Error: Failed to add the task to Task Scheduler" -ForegroundColor White -BackgroundColor DarkRed
                Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Red -BackgroundColor Black
            }
        }
        'remove' {# Remove the task associated with the provided branch, if it exists
            $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
            if ($existingTask) {
                try {
                    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction Stop
                    Write-Host "Deleted task associated with Discord[$Branch]" -ForegroundColor Blue -BackgroundColor Black
                }
                catch {
                    Write-Host "Error: Failed to remove the task from Task Scheduler" -ForegroundColor White -BackgroundColor DarkRed
                    Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Red -BackgroundColor Black
                }
            } else {
                Write-Host "Warning: No background task found for [$Branch]" -ForegroundColor Yellow -BackgroundColor Black
            }
        }
        default {
            Write-Host "Error Details: Modify-Task was called with no `$Type flag." -ForegroundColor Red -BackgroundColor Black
            Exit
        }
    }
}

function Full-Uninstall {# Fully uninstalls all files and tasks associated with the BD Automatic Updater

    # Remove any possibly existing tasks
    [String[]]$branches = "Stable","Canary","PTB"
    foreach ($branch in $branches) { 
        Modify-Task -Type 'remove' -Branch $branch
    }
    # Wipe the parent directory that contains all related program files
    Remove-Item -Path $script:directoryPath -Recurse -Force
    Write-Host "All tasks have been removed from the Windows Task Scheduler, and all files have been deleted..." -ForegroundColor Blue -BackgroundColor Black
}

# ======================================================================= #
# ============================ UI Functions ============================= #

function Main-Menu {# UI logic regarding the main menu

    Script-Bootstrapping # Install core files

    while ($true) {

        Clear-Host
        Write-Host "========================================" -ForegroundColor Cyan -BackgroundColor Black
        Write-Host "   BetterDiscord Updater - Setup v2.0   " -ForegroundColor Cyan -BackgroundColor Black
        Write-Host "========================================`n" -ForegroundColor Cyan -BackgroundColor Black

        # Give prompts
        Write-Host "[1] Manage Background Updates"
        Write-Host "[2] Settings Manager"
        Write-Host "[3] Full Uninstall"
        Write-Host "[4] Exit"

        # Get user's input
        $choice = Read-Host -Prompt "Type an option (1-4) and press enter | "

        switch ($choice) {
            '1' {
                Tasks-Menu
            }
            '2' {
                Settings-Menu
            }
            '3' {
                Full-Uninstall-Menu
            }
            '4' {
                Exit
            }
            default {
                Clear-Host
                Write-Host "`nInvalid Selection. Please only enter a number between 1 and 4." -ForegroundColor Red -BackgroundColor Black
                Start-Sleep -Seconds 3 # Pauses for 3 seconds so they can see their mistake in bright red before it refreshes and allows them to try again
            }
        }
    }
}

function Tasks-Menu {# UI logic regarding the Background Updates sub-menu

    while ($true) {# Hold user in this sub-menu until the function returns

        Clear-Host
        Write-Host "========================================" -ForegroundColor Cyan -BackgroundColor Black
        Write-Host "       Manage Background Updates        " -ForegroundColor Cyan -BackgroundColor Black
        Write-Host "========================================`n" -ForegroundColor Cyan -BackgroundColor Black
        Write-Host "Choose a number to swap whether the branch is automatically updated on startup`n" -ForegroundColor Magenta -BackgroundColor Black

        # Populate dictionary with the statuses of all branches associated tasks
        [String[]]$branches = @('Stable', 'Canary', 'PTB')
        $statuses = @{} # I prefer variables more strictly typed

        foreach ($branch in $branches) {
            $taskName = "BetterDiscordUpdater$branch"
            if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
                $statuses[$branch] = '[INSTALLED]'
            } else {
                $statuses[$branch] = '[   NIL   ]'
            }
        }

        # Give prompts
        Write-Host "[1] $($statuses['Stable']) Discord Stable" -ForegroundColor White
        Write-Host "[2] $($statuses['Canary']) Discord Canary" -ForegroundColor White
        Write-Host "[3] $($statuses['PTB']) Discord PTB" -ForegroundColor White
        Write-Host "[4] Back" -ForegroundColor DarkGray

        # Get user's input
        $choice = Read-Host -Prompt "Type an option (1-4) and press enter | "

        # Map the choice to the branch
        $selectedBranch = $null 
        switch ($choice) {
            '1' { $selectedBranch = 'Stable' }
            '2' { $selectedBranch = 'Canary' }
            '3' { $selectedBranch = 'PTB' }
            '4' { return }
            default {
                Clear-Host
                Write-Host "`nInvalid Selection. Please only enter a number between 1 and 4." -ForegroundColor Red -BackgroundColor Black
                Start-Sleep -Seconds 3 # Pauses for 3 seconds so they can see their mistake in bright red before it refreshes and allows them to try again
            }
        }

        # Toggle Logic
        if ($selectedBranch) {
            if ($statuses[$selectedBranch] -match "INSTALLED") {
                Clear-Host
                Write-Host "Removing updater task for Discord $selectedBranch..." -ForegroundColor Yellow
                Modify-Task -Type 'remove' -Branch $selectedBranch
            } else {
                Clear-Host
                Write-Host "Installing updater task for Discord $selectedBranch..." -ForegroundColor Green
                Modify-Task -Type 'add' -Branch $selectedBranch
            }
        }

        # Pause at the end of the logic so user can bear witness to any outputs before cycling back to a clean menu
        Write-Host "`nPress any key to continue..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
}

function Enter-Custom-Path {# UI logic regarding entering a custom file path, returns the path user entered
    [OutputType([String])]

    $newPath = Read-Host -Prompt "Path | "

    $newPath = $newPath.Trim('"').Trim("'")

    return $newPath
}

function Settings-Menu {# UI logic regarding the settings sub-menu

    while ($true) {# Hold user in this sub-menu until the function returns
        
        Clear-Host
        Write-Host "========================================" -ForegroundColor Cyan -BackgroundColor Black
        Write-Host "            Settings Manager            " -ForegroundColor Cyan -BackgroundColor Black
        Write-Host "========================================`n" -ForegroundColor Cyan -BackgroundColor Black
        Write-Host "Select a branch to override its installation path.`n" -ForegroundColor Magenta -BackgroundColor Black

        # Read the current settings from the JSON file
        $config = Get-Content -Path $script:configPath | ConvertFrom-Json

        # Format the display strings
        [String]$displayStable = if ($config.Stable -eq "") { "Default (Auto-Detect)" } else { $config.Stable }
        [String]$displayCanary = if ($config.Canary -eq "") { "Default (Auto-Detect)" } else { $config.Canary }
        [String]$displayPTB = if ($config.PTB -eq "") { "Default (Auto-Detect)" } else { $config.PTB }
    

        Write-Host "[1] Stable Path: $displayStable" -ForegroundColor White
        Write-Host "[2] Canary Path: $displayCanary" -ForegroundColor White
        Write-Host "[3] PTB Path:    $displayPTB" -ForegroundColor White
        Write-Host "[4] Clear all custom paths" -ForegroundColor Yellow
        Write-Host "[5] Back" -ForegroundColor DarkGray

        $choice = Read-Host -Prompt "`nType an option (1-5) and press enter | "

        $selectedBranch = $null
        switch ($choice) {
            '1' { $selectedBranch = 'Stable' }
            '2' { $selectedBranch = 'Canary' }
            '3' { $selectedBranch = 'PTB' }
            '4' {# Reset all to blank
                Default-Settings
                Write-Host "`nAll custom paths have been cleared." -ForegroundColor Green
                Start-Sleep -Seconds 2
                continue # Skips the rest of the loop
            }
            '5' { return }
            default {
                Clear-Host
                Write-Host "`nInvalid Selection. Please only enter a number between 1 and 5." -ForegroundColor Red -BackgroundColor Black
                Start-Sleep -Seconds 3
                continue # Skips the rest of the loop
            }
        }

        # Work with the user to get custom path
        Write-Host "`nEnter the custom folder path for Discord[$Branch]" -ForegroundColor Cyan
        Write-Host "(Leave blank and press Enter to revert to Default)`n" -ForegroundColor DarkGray

        $customPath = Enter-Custom-Path
        Modify-Setting -Branch $selectedBranch -Path $customPath
        
        Write-Host "`nPress any key to continue..."
        $null = $host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
}

function Full-Uninstall-Menu {# UI logic regarding the sub-menu for confirming a full uninstall
    
    while ($true) {# Hold user in this sub-menu until the function returns

        Clear-Host
        Write-Host "========================================" -ForegroundColor Cyan -BackgroundColor Black
        Write-Host "             FULL UNINSTALL             " -ForegroundColor Cyan -BackgroundColor Black
        Write-Host "========================================`n" -ForegroundColor Cyan -BackgroundColor Black

        Write-Host "Proceeding will fully delete all files and tasks associated with this updater.`n"
        
        $choice = Read-Host -Prompt "Type `"DELETE`" to continue with uninstallation, or anything else to cancel, then press enter."

        if ($choice -eq 'DELETE') {
            Full-Uninstall
            return
        }
    }
}

# Begin UI logic by running the Main Menu
Main-Menu























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
    $branch,$parentPath,'' | Out-File -FilePath "$script:directoryPath\settings.txt"
    Write-Host "Entered settings have been saved to file." -ForegroundColor Green -BackgroundColor Black
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
                if (Test-Path -Path "$script:directoryPath\settings.txt") {
                    
                    [array]$settings = Get-Content "$script:directoryPath\settings.txt"
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