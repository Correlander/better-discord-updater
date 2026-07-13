# Better Discord Automatic Updater
A Powershell script which will update your better discord for you just by running. Said script can be added to windows startup for full automation, all easily setup from the installation script paired with it.
Made for Windows, there is already a Linux version out there.  

_There are several other things like this out there for Windows already, but all required third party setup of another language, so I made this project. It only depends on tools all modern Windows environments start with, and has a simplistic setup._  

# Installation
The command will use the bypass flag to bypass your execution policy, as I'm obviously not going to pay $100+ yearly for a certificate key for such a small project. The code is of course not malicious but I encourage you to read the code if you don't trust it. The bypass flag is essentially saying you understand the script you're running and trust it, and don't need it to be certified by an external source.  

_If you're on a Company machine, your Domain Admin would likely strictly enforce execution policies using a Group Policy - in other words you cannot install this if that's the case_  

To install, run the following command inside your Windows command prompt (press your Windows key, type "cmd", press enter). After running the command, you just need to follow the prompts, everything should be straight-forward and explain itself.  

_If you haven't installed BetterDiscord at least once, please do that first. This is only an updater for an existing instance of it! It will not create the files required if they don't exist already, it only patches the ones that are there already._  
```
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "iwr -useb https://raw.githubusercontent.com/Correlander/better-discord-updater/main/Setup.ps1 | iex"
```  

### Notes
Feel free to open an issue even for something as simple as you think a certain part could be more efficient or look cleaner if done a different way. I love making things perfect. Also of course if any prompts or pieces of the setup script aren't clear, again feel free to leave an issue.  
  
_If you installed Discord from Microsoft Store, it's file location might be different. If it can't automatically find your installation, let me know, as I was unsure where it stores the installation when you download it from that source._
