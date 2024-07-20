Write-Host 'This script is to manage the running of Update.ps1 on startup of your machine.'
[bool]$CHOOSING = $true
[string]$SHORTCUT_PATH = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\BDUpdater.lnk"
[string]$TARGET_PATH = "powershell.exe"
[string]$ARGUMENTS = "-ExecutionPolicy Bypass -File $PSScriptRoot\Updater.ps1"
[string]$WORKING_DIRECTORY = $PSScriptRoot

while ($CHOOSING)
{
    $INPUT = Read-Host "[0] Exit`n[1] Add to startup`n[2] Remove from startup`n"
    switch ($INPUT)
    {
        '0'
        {
            Write-Host 'Exiting...'
            Exit
        }
        '1'
        {
            Write-Host 'Added to startup.'

            # Add it to startup
            $SHELL = New-Object -ComObject WScript.Shell
            $SHORTCUT = $SHELL.CreateShortcut($SHORTCUT_PATH)

            $SHORTCUT.TargetPath = $TARGET_PATH
            $SHORTCUT.Arguments = $ARGUMENTS
            $SHORTCUT.WorkingDirectory = $WORKING_DIRECTORY
            $SHORTCUT.Description = 'Shortcut that adds the updater script for better discord to windows startup.'

            $SHORTCUT.Save()

            $CHOOSING = $false
        }
        '2'
        {
            Write-Host 'Removed from startup.'

            # Remove it from startup
            if ([System.IO.File]::Exists($SHORTCUT_PATH))
            {
                Remove-Item -Path $SHORTCUT_PATH
            }

            $CHOOSING = $false
        }
        default
        {
            'Invalid input.'
        }
    }
}