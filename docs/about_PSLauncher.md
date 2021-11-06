# PSLauncher
## about_PSLauncher

# SHORT DESCRIPTION
a GUI to launch any PowerShell function, file or executable. You can also create a systray tool for quick access.
Gui is build from a json / csv config file. Also included helper functions to create the buttons for you.

# LONG DESCRIPTION
a GUI to launch any PowerShell function, file or executable. You can also create a systray tool for quick access.
Gui is build from a json / csv config file. Also included helper functions to create the buttons for you.

# EXAMPLES
-------------------------- Install-PSLauncherConfigFile --------------------------
Install-PSLauncherConfigFile -ConfigPath c:\temp -LaunchColorPicker
-------------------------- Install-PSSysTrayConfigFile --------------------------
Install-PSSysTrayConfigFile -ConfigPath C:\temp -CreateShortcut
-------------------------- Start-PSLauncher --------------------------
Start-PSLauncher -ConfigFilePath c:\temp\config.json
-------------------------- Start-PSLauncherColorPicker --------------------------
Start-PSLauncherColorPicker -ConfigFilePath c:\temp\config.json
-------------------------- Start-PSSysTray --------------------------
Start-PSSysTray -ConfigFilePath C:\temp\PSSysTrayConfig.csv


# SEE ALSO
https://github.com/smitpi/PSLauncher

