# Better Discord Automatic Updater
A Powershell script that will automatically update Better Discord, so you don't need to run the installer manually every Sunday when Discord pushes their weekly update.  
Installation of this updater script is extremely easy, as it is paired with a setup script that can be used for setting it up and/or changing settings later on (found below).
Made for Windows, there is already a Linux version out there.  

_There are several other things like this out there for Windows already, but all required third party setup of another language, so I made this project. It only depends on tools all modern Windows environments start with, and has a simplistic setup._  

# Installation
The command will use the bypass flag to bypass your execution policy, as I'm obviously not going to pay $100+ yearly for a certificate key for such a small project. The code is of course not malicious but I encourage you to read the code if you don't trust it. The bypass flag is essentially saying you understand the script you're running and trust it, and don't need it to be certified by an external source.  

_If you're on a Company machine, your Domain Admin would likely strictly enforce execution policies using a Group Policy - in other words you cannot install this if that's the case_  

To install, run the following command inside your Windows command prompt (press your Windows key, type "cmd", press enter). After running the command, follow the prompts. Everything should be straight-forward and self-explanatory.  

_If you haven't installed BetterDiscord at least once, do that first. This is ONLY an updater for an existing instance of it!_  
```
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "iwr -useb https://raw.githubusercontent.com/Correlander/better-discord-updater/main/Setup.ps1 | iex"
```  

### Notes
Feel free to open an issue even for something as simple as you think a certain part could be more efficient or look cleaner if done a different way. I love making things perfect. Also of course if any prompts or pieces of the setup script aren't clear, again feel free to leave an issue.  
