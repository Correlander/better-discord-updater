# BetterDiscordAutoInstaller
Powershell scripts that will update your better discord for you just by running. Said script can be added to windows startup for full automation.
Made for Windows, there is already a Linux version out there. You can try running this on Linux if you wish. I doubt it would work.

# Installation
_All commands I list are meant to be done in powershell_  
  
Firstly make sure your execution policy is set to unrestricted  
Check with `Get-ExecutionPolicy`  
Either run it as admin and set it for your entire system with `Set-ExecutionPolicy -ExecutionPolicy Unrestricted`  
Or set it just for you, as a user with `Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser`  

Now that your execution policy is set, you should be good to actually install it. Literally just run the following command and follow the prompts. If you haven't installed BetterDiscord yet at least once, please do that first. This is only an updater! Not an installer.  
If it bugs out please open an issue, but as far as I know, it should work fine.  
```
iwr -useb https://raw.githubusercontent.com/Correlander/better-discord-updater/main/Setup.ps1 | iex
```  
  
### Notes  
Feel free to open an issue even for something as simple as you think a certain part could be more efficient or look cleaner if done a different way. I love making things perfect.
