# BetterDiscordAutoInstaller
Powershell scripts that will update your better discord for you just by running. Said script can be added to windows startup for full automation.
Made for Windows, there is already a Linux version out there. You can try running this on Linux if you wish. I doubt it would work.

# Installation
Firstly make sure your execution policy is set to unrestricted  
Check with `Get-ExecutionPolicy`  
Either run it as admin and set it for your entire system with `Set-ExecutionPolicy -ExecutionPolicy Unrestricted`  
Or set it just for you, as a user with `Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser`  
  
1 - `Open Powershell`  
2- paste and run the following `iwr -useb https://raw.githubusercontent.com/Correlander/better-discord-updater/main/Setup.ps1 | iex`  
  
### Notes  
Feel free to open an issue even for something as simple as you think a certain part could be more efficient or look cleaner if done a different way.
