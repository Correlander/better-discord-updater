'https://github.link.here.ill.make.one.later'
'BetterDiscord-AutoInstaller v1.0'

[bool]$VALID_INSTALL_PATH = $false
[bool]$VALID_BRANCH = $false

# Set working directory to the folder the script is stored in. Just lets me be lazier with file references
Set-Location -Path $PSScriptRoot

# Function to load settings from file and check their validity
function LoadSettings
{
    [array]$SETTINGS = Get-Content 'settings.txt'
    $BRANCH = $SETTINGS[0]
    $PARENT_PATH = $SETTINGS[1]
    if (($BRANCH -eq 'Discord') -or ($BRANCH -eq 'DiscordPTB') -or ($BRANCH -eq 'DiscordCanary'))
    {
        $script:VALID_BRANCH = $true
    }
    if ($script:VALID_BRANCH)
    {
        if ([System.IO.File]::Exists("$env:LOCALAPPDATA\$BRANCH\Update.exe"))
        {
            $script:VALID_INSTALL_PATH = $true
        }
    }
}

# Function that goes through the setup for settings. Called on first run, if the settings were corrupted, or if the user just wants to for some reason.
function Setup
{
    [string]$BRANCH
    [string]$INSTALLATIONS_PARENT_PATH

    [bool]$CHOOSING = $true
    while ($CHOOSING)
    { # Get the Branch the user is using - I hate this wording :(
        $INPUT = Read-Host -Prompt "Choose which branch of Discord you'd like to use.`n[0] Exit`n[1] Discord`n[2] DiscordPTB`n[3] Discord Canary`n"
        switch ($INPUT)
        {
            '0'
            {
                Write-Host "You've chosen to exit. Bye!"
                Exit
            }
            '1'
            {
                Write-Host "You've chosen Discord."
                $BRANCH = 'Discord'
                $CHOOSING = $false
            }
            '2'
            {
                Write-Host "You've chosen DiscordPTB."
                $BRANCH = 'DiscordPTB'
                $CHOOSING = $false
            }
            '3'
            {
                Write-Host "You've chosen DiscordCanary."
                $BRANCH = 'DiscordCanary'
                $CHOOSING = $false
            }
            default
            {
                'Invalid input.'
            }
        }
    }

    $PARENT_PATH = "$env:LOCALAPPDATA\$BRANCH"
    if ([System.IO.File]::Exists("$PARENT_PATH\Update.exe"))
    {
        Write-Host "Automatically found install path at `"$PARENT_PATH`"."
    }
    else
    {
        while ($true)
        {
            $INSTALLATIONS_PARENT_PATH = Read-Host -Prompt "Couldn't automatically find your Discord installation folder at `"$PARENT_PATH`".`nPlease type in the absolute path for the folder containing `"Update.exe`" (if you navigate to it, right click the address bar and click `"Copy address as text`").`n"
            if ([System.IO.File]::Exists("$PARENT_PATH\Update.exe"))
            {
                "Successfully found your install folder at `"$INSTALLATIONS_PARENT_PATH`". Thanks!"
            }
            else
            {
                "The path you entered wasn't valid, please try again."
            }
        }
    }

    # Now that we have both valid values, save them to file
    $BRANCH,$PARENT_PATH,'' | Out-File -FilePath 'settings.txt'
    'Entered settings have been saved to file.'
}

# Check if settings file was already generated
if ([System.IO.File]::Exists('.\settings.txt'))
{
    LoadSettings
    # If it exists, make sure the settings stored are valid still
    if ($VALID_BRANCH -and $VALID_INSTALL_PATH)
    {
        [bool]$CHOOSING = $true
        while ($CHOOSING)
        {
            $INPUT = Read-Host -Prompt 'Your settings file already exists, and is valid. Would you still like to go through setup again? [y/n]'
            switch ($INPUT)
            {
                'y'
                {
                    Write-Host 'Resetting your settings file, and sending you to setup.'
                    Setup
                    $CHOOSING = $false
                }
                'n'
                {
                    Write-Host 'Bye!'
                    Exit
                }
                default
                {
                    Write-Host 'Invalid response.'
                }
            }
        }
    }
    else
    {
        Write-Host "Your settings file exists, but it doesn't seem to be valid. Sending you to setup."
        Setup
    } 
}
else
{
    Write-Host "Your settings file doesn't exist, sending you to setup."
    Setup
}

Write-Host 'Setup has finished, running Updater.ps1...'
& ".\Updater.ps1"