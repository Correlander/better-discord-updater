# BetterDiscordAutoInstaller
Powershell scripts that will update your better discord automatically if added to startup
Only intended for Windows, there is already a Linux version out there (I believe). You can try running it on Linux, if you wish.

# Installation
Firstly make sure your execution policy is set to unrestricted
Check with Get-ExecutionPolicy
Either run it as admin and set it for your entire system with Set-ExecutionPolicy -ExecutionPolicy Unrestricted
Or set it just for you, as a user with Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser


Clone repo to wherever you want to store it
Right click Setup.ps1, click Run with Powershell
Follow the Prompts


Setting it up to run on startup, just run StartupManager.ps1 and choose the prompt option to add to the startup folder

### Notes
This was my first time doing anything with PowerShell, hopefully it's good
Feel free to open an issue even for something as simple as you think a certain part could be more efficient or look cleaner if done a different way
