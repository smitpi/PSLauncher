# PSLauncher
 
## Description
a GUI to launch any PowerShell function, file or executable. You can also create a systray tool for quick access. One systray tool will use
the same json config file as the full gui. Or create a seperate systray tool with a .csv as a config file.
Also included is helper functions to create buttons and panels for you.
 
## Getting Started
```
- Install-Module -Name PSLauncher -Verbose
```
OR
```
git clone https://github.com/smitpi/PSLauncher (Join-Path (get-item (Join-Path (Get-Item $profile).Directory 'Modules')).FullName -ChildPath PSLauncher)
```
Then:
```
- Import-Module PSLauncher -Verbose -Force
 
- Get-Command -Module PSLauncher
- Get-Help about_PSLauncher
```
