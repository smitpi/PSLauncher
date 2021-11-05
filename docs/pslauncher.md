---
Module Name: PSLauncher
Module Guid: 5a3184bf-ebc3-4ed5-b7b2-f04863597f68
Download Help Link:
help Version: 0.1.5
Locale: en-US
---

# PSLauncher Module
## Description
a GUI to launch any PowerShell function, file or executable. You can also create a systray tool for quick access.
Gui is build from a json / csv config file. Also included helper functions to create the buttons for you.

## PSLauncher Cmdlets
### [Install-PSLauncherConfigFile](Install-PSLauncherConfigFile.md)
Creates the config file with the provided settings

### [Install-PSSysTrayConfigFile](Install-PSSysTrayConfigFile.md)
Creates the config file for Start-PSSysTray

### [Start-PSLauncher](Start-PSLauncher.md)
Reads the config file and launches the gui

### [Start-PSLauncherColorPicker](Start-PSLauncherColorPicker.md)
Launches a gui form to test and change the color of PSLauncher.

### [Start-PSSysTray](Start-PSSysTray.md)
Gui menu app in your systray with custom executable functions

