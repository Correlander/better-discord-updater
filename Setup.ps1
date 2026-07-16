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
            Write-Host "Creating directory" -ForegroundColor Blue
            New-Item -Path $script:directoryPath -ItemType Directory -ErrorAction Stop | Out-Null
            Write-Host "Succeeded" -ForegroundColor Blue
        }
        catch {
            Write-Host "Error: Failed to create the directory `"$script:directoryPath`" - Please copy this error and open an issue" -ForegroundColor White
            Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "`nPress any key to continue..."
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            Exit
        }
    }

    try {# Install Updater.ps1
        Write-Host "Installing Updater.ps1" -ForegroundColor Blue
        Invoke-WebRequest -Uri $updaterUrl -OutFile $updaterPath -ErrorAction Stop
        Set-ItemProperty -Path -Name IsReadOnly -Value $true -ErrorAction Stop
        Write-Host "Succeeded" -ForegroundColor Blue
    }
    catch {
        Write-Host "Error: Failed to create the file `"Updater.ps1`" - Please copy this error and open an issue" -ForegroundColor White
        Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "`nPress any key to continue..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        Exit
    }

    try {# Install LICENSE
        Write-Host "Installing LICENSE" -ForegroundColor Blue
        Invoke-WebRequest -Uri $licenseUrl -OutFile $licensePath -ErrorAction Stop
        Set-ItemProperty -Path -Name IsReadOnly -Value $true -ErrorAction Stop
        Write-Host "Succeeded" -ForegroundColor Blue
    }
    catch {
        Write-Host "Error: Failed to create the file `"LICENSE`" - Please copy this error and open an issue" -ForegroundColor White
        Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "`nPress any key to continue..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        Exit
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
        $Branch,
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

    $parentPath = "$env:LOCALAPPDATA\$Branch"
    if (Test-Path -Path (Join-Path -Path $parentPath -ChildPath "Update.exe"))
    {
        Write-Host "Installation at Default path `"$parentPath`" automatically found." -ForegroundColor Green
        return $true
    } else {
        Write-Host "Installation at Default path `"$parentPath`" not found." -ForegroundColor Yellow
        return $false
    }
}

function Modify-Task {# Adds or removes tasks associated with this program within the Windows Task Scheduler
    param(# Parameters
        [String]$Type,
        [String]$Branch
    )

    # Define variables
    $taskName = "BetterDiscordUpdater$branch"

    switch ($Type) {
        'add' {# Add a task to Windows Task Scheduler that will run the updater script upon user login for the specified Discord branch

            # Before trying to create it, make sure we have a path to use
            [String]$installDirectory
            if (-not (Find-Default-Path)) {# If not installed at the default path
                $installDirectory = Enter-Custom-Path -Branch $Branch -IsRequired # Ask the user for a custom path
                if ($installDirectory -eq '') { # If we get a blank string back, user chose to Cancel
                    Write-Host "`nAborting task creation" -ForegroundColor Yellow
                    return
                }
            }

            try {
                # Define task creation parameters
                $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$script:directoryPath\Updater.ps1`" -Branch `"$Branch`""
                $trigger = New-ScheduledTaskTrigger -AtLogOn
                $settings = New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
                $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive

                # Create the task
                Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force -ErrorAction Stop | Out-Null

                Write-Host "Scheduled Task created successfully!" -ForegroundColor Green
            }
            catch {# Used -ErrorAction Stop, so any error with registering the scheduled task will be considered termination worthy.
                Write-Host "Error: Failed to add the task to Task Scheduler - Please copy this error and open an issue" -ForegroundColor White
                Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "`nPress any key to continue..."
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            }
        }
        'remove' {# Remove the task associated with the provided branch, if it exists
            $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
            if ($existingTask) {
                try {
                    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction Stop
                    Write-Host "Deleted task associated with Discord[$Branch]" -ForegroundColor Blue
                }
                catch {
                    Write-Host "Error: Failed to remove the task from Task Scheduler - Please copy this error and open an issue" -ForegroundColor White
                    Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host "`nPress any key to continue..."
                    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
                }
            } else {
                Write-Host "Warning: No background task found for [$Branch]" -ForegroundColor Yellow
            }
        }
        default {
            Write-Host "Error: Modify-Task was called with no `$Type flag." -ForegroundColor Red
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
    Write-Host "All tasks have been removed from the Windows Task Scheduler, and all files have been deleted..." -ForegroundColor Blue
}

# ======================================================================= #
# ============================ UI Functions ============================= #

function Main-Menu {# UI logic regarding the main menu

    Script-Bootstrapping # Install core files

    while ($true) {

        Clear-Host
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "   BetterDiscord Updater - Setup v2.0   " -ForegroundColor Cyan
        Write-Host "========================================`n" -ForegroundColor Cyan

        # Give prompts
        Write-Host "[1] Manage Background Updates"
        Write-Host "[2] Settings Manager"
        Write-Host "[3] Full Uninstall"
        Write-Host "[4] Exit"

        # Get user's input
        $choice = Read-Host -Prompt "Type an option (1-4) and press enter: "

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
                Write-Host "`nInvalid Selection. Please only enter a number between 1 and 4." -ForegroundColor Red
                Start-Sleep -Seconds 3 # Pauses for 3 seconds so they can see their mistake in bright red before it refreshes and allows them to try again
            }
        }
    }
}

function Tasks-Menu {# UI logic regarding the Background Updates sub-menu

    while ($true) {# Hold user in this sub-menu until the function returns

        Clear-Host
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "       Manage Background Updates        " -ForegroundColor Cyan
        Write-Host "========================================`n" -ForegroundColor Cyan
        Write-Host "Choose a number to swap whether the branch is automatically updated on startup`n" -ForegroundColor Magenta

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
        $choice = Read-Host -Prompt "Type an option (1-4) and press enter: "

        # Map the choice to the branch
        $selectedBranch = $null 
        switch ($choice) {
            '1' { $selectedBranch = 'Stable' }
            '2' { $selectedBranch = 'Canary' }
            '3' { $selectedBranch = 'PTB' }
            '4' { return }
            default {
                Clear-Host
                Write-Host "`nInvalid Selection. Please only enter a number between 1 and 4." -ForegroundColor Red
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
    param (
        [String]$Branch,
        [switch]$IsRequired
    )

    Write-Host "`nEnter the path to your custom installation for Discord[$Branch]" -ForegroundColor Cyan
    Write-Host "`nMake sure it is the ABSOLUTE PATH for the folder containing `"Update.exe`"" -ForegroundColor Cyan
    Write-Host "`n(In File Explorer, if you navigate into the folder, you can right click the address bar and click `"Copy address as text`")" -ForegroundColor DarkGray

    # Change last prompt based on whether this path is required, or if it's fine to be returned as Default
    if ($IsRequired) {
        Write-Host "(A valid path is required. Type 'cancel' to abort setup)`n" -ForegroundColor Yellow
    } else {
        Write-Host "(Leave blank and press Enter to revert to Default)`n" -ForegroundColor DarkGray
    }

    while ($true) {
        
        # Grab input
        $newPath = Read-Host -Prompt "Path: "
        # Trim the input of string signifiers, in case the user enters them thinking they are needed
        $newPath = $newPath.Trim('"').Trim("'")

        # Handle the cancel keyword
        if (($IsRequired) -and ($newPath.ToLower() -eq 'cancel')) {
            return "" # If task setup receives this, should cancel the setup
        }

        # Handle blank inputs
        if ($newPath -eq "") {
            if ($IsRequired) {
                Write-Host "`nInvalid Path: A valid path is required. Type 'cancel' to abort, or enter a valid path" -ForegroundColor Yellow
            } else {
                return "" # Settings menu behavior, just returns "" and will set the entry to that, which is default value
            }
        }

        # Validation Step, if neither special case met
        if (Test-Path (Join-Path -Path $newPath -ChildPath "Update.exe")) {
            return $newPath
        } else {
            Write-Host "`nInvalid Path: That directory does not exist. Please verify and try again." -ForegroundColor Yellow
        }
    }
}

function Settings-Menu {# UI logic regarding the settings sub-menu

    while ($true) {# Hold user in this sub-menu until the function returns
        
        Clear-Host
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "            Settings Manager            " -ForegroundColor Cyan
        Write-Host "========================================`n" -ForegroundColor Cyan
        Write-Host "Select a branch to override its installation path.`n" -ForegroundColor Magenta

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

        $choice = Read-Host -Prompt "`nType an option (1-5) and press enter: "

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
                Write-Host "`nInvalid Selection. Please only enter a number between 1 and 5." -ForegroundColor Red
                Start-Sleep -Seconds 3
                continue # Skips the rest of the loop
            }
        }

        # Get the path they want to set the selected branch to
        $customPath = Enter-Custom-Path -Branch $selectedBranch
        Modify-Setting -Branch $selectedBranch -Path $customPath
        
        Write-Host "`nPress any key to continue..."
        $null = $host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
}

function Full-Uninstall-Menu {# UI logic regarding the sub-menu for confirming a full uninstall
    
    while ($true) {# Hold user in this sub-menu until the function returns

        Clear-Host
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "             FULL UNINSTALL             " -ForegroundColor Cyan
        Write-Host "========================================`n" -ForegroundColor Cyan

        Write-Host "Proceeding will fully delete all files and tasks associated with this updater.`n"
        
        $choice = Read-Host -Prompt "Type `"DELETE`" to continue with uninstallation, or anything else to cancel, then press enter."

        if ($choice -eq 'DELETE') {
            Full-Uninstall
            Write-Host "`nUninstallation complete. Exiting..." -ForegroundColor Green
            Start-Sleep -Seconds 3
            Exit
        }
    }
}

# Begin UI logic by running the Main Menu
Main-Menu