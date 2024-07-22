# BetterDiscordAutoInstaller
Powershell scripts that will update your better discord automatically if added to startup
Only intended for Windows, there is already a Linux version out there (I believe). You can try running it on Linux, if you wish.

# Installation
Firstly make sure your execution policy is set to unrestricted
Check with Get-ExecutionPolicy
Either run it as admin and set it for your entire system with Set-ExecutionPolicy -ExecutionPolicy Unrestricted
Or set it just for you, as a user with Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser


If you have git, just clone the repo  
If you don't have git, here you go  
1- `Open PowerShell`  
2- `cd "path\you\want\the\files"` Don't include the {}  
3- `Invoke-WebRequest 'https://github.com/Correlander/BetterDiscordAutoInstaller/archive/refs/heads/main.zip' -OutFile .\BDAT.zip`  
4 - `Expand-Archive .\BDAT.zip .\`  
5 - `Rename-Item .\BetterDiscordAutoInstaller-main .\BetterDiscordAutoInstaller`  
6 - `Remove-Item .\BDAT.zip`  
You should now have all the files needed  

Next:  
Right click Setup.ps1, click Run with Powershell  
Follow the Prompts  
Next:  
If you want it to run on startup, just run StartupManager.ps1 in PowerShell and choose the prompt option to add to the startup folder  

### Notes  
This was my first time doing anything with PowerShell, hopefully it's good  
Feel free to open an issue even for something as simple as you think a certain part could be more efficient or look cleaner if done a different way  
