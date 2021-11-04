
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
Creates the config file for Start-PSSysTray

#> 


#.ExternalHelp PSLauncher-help.xml

Function Install-PSSysTrayConfigFile {
<#
.SYNOPSIS
Creates the config file for Start-PSSysTray

.DESCRIPTION
Creates the config file for Start-PSSysTray

.PARAMETER ConfigPath
Path where config file will be saved.

.PARAMETER CreateShortcut
Create a shortcut to launch the gui

.EXAMPLE
Install-PSSysTrayConfigFile -ConfigPath C:\temp -CreateShortcut

#>
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

	$Configfile = (Join-Path $ConfigPath -ChildPath \PSSysTrayConfig.csv)
	$check = Test-Path -Path $Configfile  -ErrorAction SilentlyContinue
		if (-not($check)) {
			Write-Output 'Config File does not exit, creating default settings.'
			$export | Export-Csv -Path $Configfile -NoClobber
		} else {
			Write-Warning 'File exists, renaming file now'
			Rename-Item $Configfile -NewName "PSSysTrayConfig_$(Get-Date -Format ddMMyyyy_HHmm).csv"
			$export | Export-Csv -Path $Configfile -NoClobber
		}

	if ($CreateShortcut) {

		$string = "import-module  $((Join-Path (Get-Module pslauncher).ModuleBase \PSLauncher.psm1 -Resolve)) -Force -ErrorAction SilentlyContinue;"
		$string += 'Import-Module PSLauncher -Force -ErrorAction SilentlyContinue;'
		$string += "Start-PSSysTray -ConfigFilePath $((Join-Path $ConfigPath -ChildPath \PSSysTrayConfig.csv -Resolve))"

		Set-Content -Value $string.Split(';') -Path (Join-Path $ConfigPath -ChildPath \PSSystray.ps1)

		$WScriptShell = New-Object -ComObject WScript.Shell
		$lnkfile = (Join-Path $ConfigPath -ChildPath \PSSystray.ps1 -Resolve).Replace('ps1', 'lnk')
		$Shortcut = $WScriptShell.CreateShortcut($($lnkfile))
		$Shortcut.TargetPath = 'powershell.exe'
		$Shortcut.Arguments = "-NoLogo -NoProfile -ExecutionPolicy bypass -file `"$((Join-Path $ConfigPath -ChildPath \PSSystray.ps1))`""
		$Shortcut.IconLocation = (Join-Path (Get-Module pslauncher).ModuleBase .\Private\pslauncher.ico -Resolve)
		#Save the Shortcut to the TargetPath
		$Shortcut.Save()
		Start-Process explorer.exe $ConfigPath
	}



} #end Function
