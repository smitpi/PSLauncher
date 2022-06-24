# PSLauncher
 
## Description
A GUI to launch any PowerShell script, function, or any other executables. You have the option to run any of these options as a normal user or as an Admin. Everything is saved in a json config file. Also created menu items that assists in creating the buttons, panels, and colour schemes. There is no need to manually edit the config file.
 
## Getting Started
- Install from PowerShell Gallery [PS Gallery](https://www.powershellgallery.com/packages/PSLauncher)
```
Install-Module -Name PSLauncher -Verbose
```
- or from GitHub [GitHub Repo](https://github.com/smitpi/PSLauncher)
```
git clone https://github.com/smitpi/PSLauncher (Join-Path (get-item (Join-Path (Get-Item $profile).Directory 'Modules')).FullName -ChildPath PSLauncher)
```
- Then import the module into your session
```
Import-Module PSLauncher -Verbose -Force
```
- or run these commands for more help and details.
```
Get-Command -Module PSLauncher
Get-Help about_PSLauncher
```
Documentation can be found at: [Github_Pages](https://smitpi.github.io/PSLauncher)
 
## Functions
- [`Add-PSLauncherEntry`](https://smitpi.github.io/PSLauncher/Add-PSLauncherEntry) -- Add a button or panal to the config.
- [`New-PSLauncherConfigFile`](https://smitpi.github.io/PSLauncher/New-PSLauncherConfigFile) -- Creates the config file with the provided settings
- [`Start-PSLauncher`](https://smitpi.github.io/PSLauncher/Start-PSLauncher) -- Reads the config file and launches the GUI
- [`Start-PSLauncherColorPicker`](https://smitpi.github.io/PSLauncher/Start-PSLauncherColorPicker) -- Launches a GUI form to test and change the Color of PSLauncher.
