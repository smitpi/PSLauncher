
<#PSScriptInfo

.VERSION 1.1.2

.GUID fc2f6108-c6fb-494e-98e3-015eb6ea8e38

.AUTHOR Pierre Smit

.COMPANYNAME HTPCZA Tech

.COPYRIGHT

.TAGS ps

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
Created [30/09/2021_21:20] Initial Script Creating
Updated [05/10/2021_08:30] Spit into more functions
Updated [24/10/2021_05:59] 'Updated module/script info'

.PRIVATEDATA

#>





<#

.DESCRIPTION
Creates the config file with the provided settings

#>
<#
.SYNOPSIS
Creates the config file with the provided settings

.DESCRIPTION
Creates the config file with the provided settings

.PARAMETER Color1
Run Start-PSLauncherColorPicker to change.

.PARAMETER Color2
Run Start-PSLauncherColorPicker to change.

.PARAMETER LabelColor
Run Start-PSLauncherColorPicker to change.

.PARAMETER TextColor
Run Start-PSLauncherColorPicker to change.

.PARAMETER LogoPath
Run Start-PSLauncherColorPicker to change.

.PARAMETER Title
Text in the title of the app.

.PARAMETER Panel01
Name of the 1st panel

.PARAMETER Panel02
Name of the 2nd panel

.PARAMETER ConfigPath
Path where the config file will be saved.

.PARAMETER CreateShortcut
Creates a shortcut in the same directory that calls PowerShell and the config.

.PARAMETER LaunchColorPicker
Launches Start-PSLauncherColorPicker

.EXAMPLE
New-PSLauncherConfigFile -ConfigPath c:\temp -LaunchColorPicker

#>
Function New-PSLauncherConfigFile {
    [Cmdletbinding(HelpURI = 'https://smitpi.github.io/PSLauncher/New-PSLauncherConfigFile/')]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript( { (Test-Path $_) })]
        [System.IO.DirectoryInfo]$ConfigPath,
        [switch]$CreateShortcut = $false,
        [string]$Color1 = '#E5E5E5',
        [string]$Color2 = '#061820',
        [string]$LabelColor = '#FFD400',
        [string]$TextColor = '#000000',
        [string]$LogoPath = 'https://gist.githubusercontent.com/smitpi/ecdaae80dd79ad585e571b1ba16ce272/raw/6d0645968c7ba4553e7ab762c55270ebcc054f04/default-monochrome%2520(2).png',
        [string]$Title = 'PowerShell Launcher',
        [string]$Panel01 = 'First',
        [string]$Panel02 = 'Second',
        [switch]$LaunchColorPicker = $false
    )

    $json = @"
{
    "Config":  [
                   {
                       "Color1st":  "$color1",
                       "Color2nd":  "$color2",
                       "LabelColor": "$labelColor",
                       "TextColor": "$TextColor",
                       "LogoUrl":  "$LogoPath",
                       "AppTitle":  "$title"
                   }
               ],
    "Buttons":  [
                    {
                        "$Panel01":  [
                                        {
                                            "Config":  {
                                                           "PanelNumber":  "1"
                                                       },
                                            "buttons":  [
                                                        ]
                                        }
                                    ],
                        "$Panel02":  [
                                        {
                                            "Config":  {
                                                           "PanelNumber":  "2"
                                                       },
                                            "buttons":  [
                                                        ]
                                        }
                                    ]
                    }
                ]
}

"@
    $Configfile = (Join-Path $ConfigPath -ChildPath \PSLauncherConfig.json)
    $check = Test-Path -Path $Configfile -ErrorAction SilentlyContinue
    if (-not($check)) {
        Write-Output 'Config File does not exit, creating default settings.'
        Set-Content -Value $json -Path $Configfile
    } else {
        Write-Warning 'File exists, renaming file now'
        Rename-Item $Configfile -NewName "PSSysTrayConfig_$(Get-Date -Format ddMMyyyy_HHmm).json"
        Set-Content -Value $json -Path $Configfile
    }
    if ($CreateShortcut) {
        $module = Get-Module pslauncher
        if (![bool]$module) { $module = Get-Module pslauncher -ListAvailable }

        $string = @"
`$psl = Get-ChildItem `"$((Join-Path ((Get-Item $module.ModuleBase).Parent).FullName "\*\$($module.name).psm1"))`" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1
Import-Module `$psl.fullname -Force
Start-PSLauncher -PSLauncherConfigFile $((Join-Path $ConfigPath -ChildPath \PSLauncherConfig.json -Resolve))
"@
        Set-Content -Value $string -Path (Join-Path $ConfigPath -ChildPath \PSLauncher.ps1) | Get-Item
        $launcher = (Join-Path $ConfigPath -ChildPath \PSLauncher.ps1) | Get-Item

        $WScriptShell = New-Object -ComObject WScript.Shell
        $lnkfile = ($launcher.FullName).Replace('ps1', 'lnk')
        $Shortcut = $WScriptShell.CreateShortcut($($lnkfile))
        $Shortcut.TargetPath = 'powershell.exe'
        $Shortcut.Arguments = "-NoLogo -NoProfile -WindowStyle Hidden -ExecutionPolicy bypass -file `"$($launcher.FullName)`""
        $icon = Get-Item (Join-Path $module.ModuleBase .\Private\pslauncher.ico)
        $Shortcut.IconLocation = $icon.FullName
        #Save the Shortcut to the TargetPath
        $Shortcut.Save()

        $string = @"
`$psl = Get-ChildItem `"$((Join-Path ((Get-Item $module.ModuleBase).Parent).FullName "\*\$($module.name).psm1"))`" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1
Import-Module `$psl.fullname -Force
Start-PSSysTrayLauncher -PSLauncherConfigFile $((Join-Path $ConfigPath -ChildPath \PSLauncherConfig.json -Resolve))
"@
        Set-Content -Value $string -Path (Join-Path $ConfigPath -ChildPath \PSSysTrayLauncher.ps1) | Get-Item
        $PSSysTrayLauncher = (Join-Path $ConfigPath -ChildPath \PSSysTrayLauncher.ps1) | Get-Item

        $WScriptShell = New-Object -ComObject WScript.Shell
        $lnkfile = ($PSSysTrayLauncher.FullName).Replace('ps1', 'lnk')
        $Shortcut = $WScriptShell.CreateShortcut($($lnkfile))
        $Shortcut.TargetPath = 'powershell.exe'
        $Shortcut.Arguments = "-NoLogo -NoProfile -WindowStyle Hidden -ExecutionPolicy bypass -file `"$($PSSysTrayLauncher.FullName)`""
        $icon = Get-Item (Join-Path $module.ModuleBase .\Private\pslauncher.ico)
        $Shortcut.IconLocation = $icon.FullName
        #Save the Shortcut to the TargetPath
        $Shortcut.Save()
        Start-Process explorer.exe $ConfigPath
    }

    if ($LaunchColorPicker -like $true) {
        Start-PSLauncherColorPicker -PSLauncherConfigFile (Join-Path $ConfigPath -ChildPath \PSLauncherConfig.json)
    }
} #end Function
