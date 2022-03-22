# PSLauncher
 
## Description
A GUI to launch any PowerShell script, function, file, or any other executables. You can also create a SysTray tool for quick access. Both apps use the same json config file. So, all your config is in sync.
    Also created menus that assists in creating the buttons and panels. It just asks you a couple of questions, and it adds the config to the json file. After a refresh, the new buttons or panels are available to everyone using it.
 
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
