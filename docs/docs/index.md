## Description
a GUI to launch any PowerShell function, file or executable. You can also create a systray tool for quick access. One systray tool will use
the same json config file as the full gui. Or create a seperate systray tool with a .csv as a config file.
Also included is helper functions to create buttons and panels for you.

## Getting Started
- `Install-Module -Name PSLauncher -Verbose`
- `Import-Module PSLauncher -Verbose -Force`
- `Get-Command -Module PSLauncher`

## Functions
- [New-PS_CSV_SysTrayConfigFile](New-PS_CSV_SysTrayConfigFile.md) -- Creates the config file for Start-PS_CSV_SysTray
- [New-PSLauncherConfigFile](New-PSLauncherConfigFile.md) -- Creates the config file with the provided settings
- [Start-PS_CSV_SysTray](Start-PS_CSV_SysTray.md) -- Gui menu app in your systray with custom executable functions
- [Start-PSLauncher](Start-PSLauncher.md) -- Reads the config file and launches the gui
- [Start-PSLauncherColorPicker](Start-PSLauncherColorPicker.md) -- Launches a gui form to test and change the color of PSLauncher.
- [Start-PSSysTrayLauncher](Start-PSSysTrayLauncher.md) -- Gui menu app in your systray with custom executable functions


