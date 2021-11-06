﻿
<#PSScriptInfo

.VERSION 1.1.2

.GUID fc2f6108-c6fb-494e-98e3-015eb6ea8e38

.AUTHOR Pierre Smit

.COMPANYNAME iOCO Tech

.COPYRIGHT

.TAGS ps

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
Created [30/09/2021_21:20] Initital Script Creating
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
Text in the titple of the app.

.PARAMETER Panel01
Name of the 1st panel

.PARAMETER Panel02
Name of the 2nd panel

.PARAMETER ConfigPath
Path where the config file will be saved.

.PARAMETER CreateShortcut
Creates a shortcut in the same directory that calls powershell and the config.

.PARAMETER LaunchColorPicker
Launches Start-PSLauncherColorPicker

.EXAMPLE
Install-PSLauncherConfigFile -ConfigPath c:\temp -LaunchColorPicker

#>
Function Install-PSLauncherConfigFile {
    param(
        [string]$Color1 = '#E5E5E5',
        [string]$Color2 = '#061820',
        [string]$LabelColor = '#FFD400',
        [string]$TextColor = '#000000',
        [string]$LogoPath = 'https://gist.githubusercontent.com/smitpi/0e36b701419dbf9282ecfc6d0f7b654c/raw/8fe6a2fc91a27a9ebccb753f6508a2edd039c208/default-monochrome-black.png',
        [string]$Title = 'PowerShell Launcher',
        [string]$Panel01 = 'First',
        [string]$Panel02 = 'Second',
        [ValidateScript( { (Test-Path $_) })]
        [System.IO.DirectoryInfo]$ConfigPath = (Join-Path (Get-Module pslauncher).ModuleBase \config),
        [switch]$CreateShortcut = $false,
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
                       "AppTitle":  "$title by Pierre Smit",
                       "ModuleRoot": $((Get-Module pslauncher).ModuleBase | ConvertTo-Json)
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
    }
    else {
        Write-Warning 'File exists, renaming file now'
        Rename-Item $Configfile -NewName "PSSysTrayConfig_$(Get-Date -Format ddMMyyyy_HHmm).csv"
        Set-Content -Value $json -Path $Configfile
    }
    if ($CreateShortcut) {

        $string = "import-module  $((Join-Path (Get-Module pslauncher).ModuleBase \PSLauncher.psm1 -Resolve)) -Force -ErrorAction SilentlyContinue;"
        $string += 'Import-Module PSLauncher -Force -ErrorAction SilentlyContinue;'
        $string += "Start-PSLauncher -ConfigFilePath $((Join-Path $ConfigPath -ChildPath \PSLauncherConfig.json -Resolve))"

        Set-Content -Value $string.Split(';') -Path (Join-Path $ConfigPath -ChildPath \PSLauncher.ps1)
        $WScriptShell = New-Object -ComObject WScript.Shell
        $lnkfile = (Join-Path $ConfigPath -ChildPath \PSLauncher.ps1 -Resolve).Replace('ps1', 'lnk')
        $Shortcut = $WScriptShell.CreateShortcut($($lnkfile))
        $Shortcut.TargetPath = 'powershell.exe'
        $Shortcut.Arguments = "-NoLogo -NoProfile -ExecutionPolicy bypass -file `"$((Join-Path $ConfigPath -ChildPath \PSLauncher.ps1))`""
        $icon = Get-Item (Join-Path (Get-Module pslauncher).ModuleBase .\Private\pslauncher.ico)
        $Shortcut.IconLocation = $icon.FullName
        #Save the Shortcut to the TargetPath
        $Shortcut.Save()
        Start-Process explorer.exe $ConfigPath
    }

    if ($LaunchColorPicker -like $true) {
        Start-PSLauncherColorPicker -ConfigFilePath (Join-Path $ConfigPath -ChildPath \PSLauncherConfig.json)
    }
} #end Function