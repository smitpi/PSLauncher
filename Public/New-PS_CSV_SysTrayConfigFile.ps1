
<#PSScriptInfo

.VERSION 0.1.0

.GUID 28d6de4c-10fc-45c0-8d96-1869a965134c

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
Created [27/10/2021_05:31] Initital Script Creating

.PRIVATEDATA

#>

<#

.DESCRIPTION
Creates the config file for Start-PS_CSV_SysTray

#>


<#
.SYNOPSIS
Creates the config file for Start-PS_CSV_SysTray

.DESCRIPTION
Creates the config file for Start-PS_CSV_SysTray

.PARAMETER ConfigPath
Path where config file will be saved.

.PARAMETER CreateShortcut
Create a shortcut to launch the gui

.EXAMPLE
New-PS_CSV_SysTrayConfigFile -ConfigPath C:\temp -CreateShortcut

#>
Function New-PS_CSV_SysTrayConfigFile {
    [Cmdletbinding()]
    PARAM(
        [ValidateScript( { (Test-Path $_) })]
        [System.IO.DirectoryInfo]$ConfigPath,
        [switch]$CreateShortcut = $false
    )


    [System.Collections.ArrayList]$Export = @()
    $export += [PSCustomObject]@{
        MainMenu   = 'Level1'
        ScriptName = 'TempScript'
        ScriptPath = 'C:\temp\script.ps1'
        Mode       = 'PSFile'
    }
    $export += [PSCustomObject]@{
        MainMenu   = 'Level2'
        ScriptName = 'Command'
        ScriptPath = 'get-command'
        Mode       = 'PSCommand'
    }
    $export += [PSCustomObject]@{
        MainMenu   = 'Level3'
        ScriptName = 'Restart'
        ScriptPath = 'shutdown /f /r /t 0'
        Mode       = 'Other'
    }

    $Configfile = (Join-Path $ConfigPath -ChildPath \PS_CSV_SysTrayConfig.csv)
    $check = Test-Path -Path $Configfile -ErrorAction SilentlyContinue
    if (-not($check)) {
        Write-Output 'Config File does not exit, creating default settings.'
        $export | Export-Csv -Path $Configfile -NoClobber -NoTypeInformation
    }
    else {
        Write-Warning 'File exists, renaming file now'
        Rename-Item $Configfile -NewName "PSSysTrayConfig_$(Get-Date -Format ddMMyyyy_HHmm).csv"
        $export | Export-Csv -Path $Configfile -NoClobber -NoTypeInformation
    }

    if ($CreateShortcut) {
        $module = Get-Module pslauncher
        if (![bool]$module) { $module = Get-Module pslauncher -ListAvailable }

        $string = @"
`$psl = get-item `"$((Join-Path $module.ModuleBase \PSLauncher.psm1 -Resolve))`"
import-module `$psl.fullname -Force
Start-PS_CSV_SysTray -ConfigFilePath $((Join-Path $ConfigPath -ChildPath \PS_CSV_SysTrayConfig.csv -Resolve))
"@
        Set-Content -Value $string -Path (Join-Path $ConfigPath -ChildPath \PS_CSV_SysTray.ps1) | Get-Item
        $PS_CSV_SysTray = (Join-Path $ConfigPath -ChildPath \PS_CSV_SysTray.ps1) | Get-Item

        $WScriptShell = New-Object -ComObject WScript.Shell
        $lnkfile = ($PS_CSV_SysTray.FullName).Replace('ps1', 'lnk')
        $Shortcut = $WScriptShell.CreateShortcut($($lnkfile))
        $Shortcut.TargetPath = 'powershell.exe'
        $Shortcut.Arguments = "-NoLogo -NoProfile -ExecutionPolicy bypass -file `"$($PS_CSV_SysTray.FullName)`""
        $icon = Get-Item (Join-Path $module.ModuleBase .\Private\PS_CSV_SysTray.ico)
        $Shortcut.IconLocation = $icon.FullName
        #Save the Shortcut to the TargetPath
        $Shortcut.Save()
        Start-Process explorer.exe $ConfigPath


    }



} #end Function
