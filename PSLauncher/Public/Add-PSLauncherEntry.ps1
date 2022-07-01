
<#PSScriptInfo

.VERSION 0.1.0

.GUID 33956e23-df4a-4a4e-a716-2cea1fc2fc28

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
Created [01/04/2022_21:34] Initial Script Creating

.PRIVATEDATA

#>

#Requires -Module PSWriteColor

<#

.DESCRIPTION
 Add a button or panel to the config

#>


<#
.SYNOPSIS
Add a button or panel to the config.

.DESCRIPTION
Add a button or panel to the config.

.PARAMETER PSLauncherConfigFile
Path to the config file created by New-PSLauncherConfigFile

.PARAMETER Execute
Run Start-PSLauncher after config change.

.EXAMPLE
Add-PSLauncherEntry -PSLauncherConfigFile c:\temp\PSLauncherConfig.json

#>
Function Add-PSLauncherEntry {
	[Cmdletbinding(HelpURI = 'https://smitpi.github.io/PSLauncher/Add-PSLauncherEntry')]
	Param (
		[System.IO.FileInfo]$PSLauncherConfigFile,
		[switch]$Execute = $false
	)

	try {
		[System.Collections.Generic.List[psobject]]$jsondata = Get-Content $PSLauncherConfigFile | ConvertFrom-Json -ErrorAction stop
	} catch {
		Add-Type -AssemblyName System.Windows.Forms
		$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ Filter = 'JSON | *.json' }
		[void]$FileBrowser.ShowDialog()
		$PSLauncherConfigFile = Get-Item $FileBrowser.FileName
		[System.Collections.Generic.List[psobject]]$jsondata = Get-Content $PSLauncherConfigFile | ConvertFrom-Json
	}

	Clear-Host
	Write-Color 'Edit Config File' -Color DarkYellow -LinesAfter 1
	Write-Color '0', ': ', 'Add a Panel' -Color Yellow, Yellow, Green
	Write-Color '1', ': ', 'Add a Button' -Color Yellow, Yellow, Green
	Write-Color '2', ': ', 'Launch Color Picker Window' -Color Yellow, Yellow, Green
	Write-Color '3', ': ', 'ReOrder Existing Panels' -Color Yellow, Yellow, Green
	Write-Color '4', ': ', 'ReOrder Existing Buttons' -Color Yellow, Yellow, Green
	Write-Output ' '
	[int]$GuiAddChoice = Read-Host 'Answer'


	if ($GuiAddChoice -eq 0) {
		Clear-Host
		[System.Collections.Generic.List[psobject]]$data = $jsondata.Buttons
		$data.Add(
			[pscustomobject]@{
				name        = (Read-Host 'Panel Name')
				PanelNumber = (($data.panelnumber | Sort-Object -Descending | Select-Object -First 1 ) + 1)
				Buttons     = [pscustomobject]@{}
			})

		$Update = @()
		$Update = [psobject]@{
			Config  = $jsondata.Config
			Buttons = $data
		}

		$Update | ConvertTo-Json -Depth 5 | Set-Content -Path $PSLauncherConfigFile -Force

	}
	if ($GuiAddChoice -eq 1) {
		[System.Collections.Generic.List[psobject]]$data = $jsondata.Buttons
		$index = 0
		Clear-Host
		Write-Color 'Select the panel where the button will be added' -Color DarkYellow -LinesAfter 1
		foreach ($p in $data) {
			Write-Color $index, ': ', $p.name -Color Yellow, Yellow, Green
			$index++
		}
		Write-Output ' '
		[int]$indexnum = Read-Host 'Panel Number '

		
		do {
			$name = Read-Host 'New Button Name'

			Write-Color 'Choose the mode:' -Color DarkRed -StartTab 1 -LinesBefore 2
			Write-Color '0) ', 'PowerShell Script file' -Color Yellow, Green
			Write-Color '1) ', 'PowerShell Command' -Color Yellow, Green
			Write-Color '2) ', 'Other Executable' -Color Yellow, Green
			$modechoose = Read-Host 'Answer'

			switch ($modechoose) {
				'0' {
					$mode = 'PSFile'
					$command = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
					$arguments = Read-Host 'Path to .ps1 file'
				}
				'1' {
					$mode = 'PSCommand'
					$command = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
					$arguments = Read-Host 'PowerShell command or scriptblock'

				}
				'2' {
					$mode = 'Other'
					$command = Read-Host 'Path to executable'
					$arguments = Read-Host 'Arguments for the executable'
				}
			}
			$cmd = [PSCustomObject]@{
				mode      = $mode
				command   = $command
				arguments = $arguments
			}

			Write-Color 'Choose the window size:' -Color DarkRed -StartTab 1 -LinesBefore 2
			Write-Color '0) ', 'Hidden' -Color Yellow, Green
			Write-Color '1) ', 'Normal' -Color Yellow, Green
			Write-Color '2) ', 'Minimized' -Color Yellow, Green
			Write-Color '3) ', 'Maximized' -Color Yellow, Green
			$modechoose = Read-Host 'Answer'

			switch ($modechoose) {
				'0' {$Window = 'Hidden'}
				'1' {$Window = 'Normal'}
				'2' {$Window = 'Minimized'}
				'3' {$Window = 'Maximized'}
			}

			Write-Color 'Run As Admin:' -Color DarkRed -StartTab 1 -LinesBefore 2
			Write-Color '0) ', 'Yes' -Color Yellow, Green
			Write-Color '1) ', 'No' -Color Yellow, Green
			$modechoose = Read-Host 'Answer'
			switch ($modechoose) {
				'0' {$RunAs = 'Yes'}
				'1' {$RunAs = 'No'}
			}

			if ([string]::IsNullOrEmpty($jsondata.Buttons[$indexnum].buttons)) {
				[System.Collections.Generic.List[psobject]]$jsondata.Buttons[$indexnum].buttons = [PSCustomObject] @{
					ID         = 0
					Name       = $name
					Command    = $cmd.command
					Arguments  = $cmd.arguments
					Mode       = $cmd.mode
					Window     = $Window
					RunAsAdmin = $RunAs
				}
			} else {
				[System.Collections.Generic.List[psobject]]$jsondata.Buttons[$indexnum].buttons += [PSCustomObject] @{
					ID         = (($jsondata.Buttons[$indexnum].buttons.id | Sort-Object -Descending | Select-Object -First 1) + 1)
					Name       = $name
					Command    = $cmd.command
					Arguments  = $cmd.arguments
					Mode       = $cmd.mode
					Window     = $Window
					RunAsAdmin = $RunAs
				}
			}

			Write-Output ' '
			$yn = Read-Host "Add another button in $($jsondata.Buttons[$indexnum].name) (y/n)"
		}
		until ($yn.ToLower() -eq 'n')
		$jsondata | ConvertTo-Json -Depth 4 | Out-File $PSLauncherConfigFile
	}
	if ($GuiAddChoice -eq 2) {
		$module = Get-Module pslauncher
		if (![bool]$module) { $module = Get-Module pslauncher -ListAvailable }
		Start-Process -FilePath 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -ArgumentList "-NoLogo -NoProfile -WindowStyle Hidden -ExecutionPolicy bypass -command ""& {Start-PSLauncherColorPicker -PSLauncherConfigFile $($PSLauncherConfigFile)}"""
	}
	if ($GuiAddChoice -eq 3) {
		[System.Collections.Generic.List[psobject]]$SortData = $jsondata.buttons
		[System.Collections.Generic.List[psobject]]$NewSortData = @()
		$index1 = 0
		do {
			Clear-Host
			$index = 0
			foreach ($d in $SortData) {
				Write-Color $index, ': ', $d.name -Color Yellow, Yellow, Green
				$index++
			}
			[int]$indexnum = Read-Host 'Select Panel Number '
			$SortData[$indexnum].PanelNumber = $index1
			$NewSortData.Add($SortData[$indexnum])
			$SortData.Remove($SortData[$indexnum])
			$index1++   
		}
		while ($SortData.Count -gt 0)

		$Update = @()
		$Update = [psobject]@{
			Config  = $jsondata.Config
			Buttons = $NewSortData
		}
		$Update | ConvertTo-Json -Depth 5 | Set-Content -Path $PSLauncherConfigFile -Force
	}


	if ($GuiAddChoice -eq 4) {
		[System.Collections.Generic.List[psobject]]$data = $jsondata.Buttons
		$index = 0
		Clear-Host
		Write-Color 'Select the panel to ReOrder buttons' -Color DarkYellow -LinesAfter 1
		foreach ($p in $data) {
			Write-Color $index, ': ', $p.name -Color Yellow, Yellow, Green
			$index++
		}
		Write-Output ' '
		[int]$indexnum = Read-Host 'Panel Number '

		[System.Collections.Generic.List[psobject]]$SortData = $jsondata.Buttons[$indexnum].buttons
		[System.Collections.Generic.List[psobject]]$NewSortData = @()
		$index1 = 0
		do {
			Clear-Host
			$index = 0
			foreach ($d in $SortData) {
				Write-Color $index, ': ', $d.name -Color Yellow, Yellow, Green
				$index++
			}
			[int]$num = Read-Host 'Button Number '
			$SortData[$num].ID = $index1
			$NewSortData.Add($SortData[$num])
			$SortData.Remove($SortData[$num])
			$index1++   
		}
		while ($SortData.Count -gt 0)
		$jsondata.Buttons[$indexnum].buttons = $NewSortData
		$jsondata | ConvertTo-Json -Depth 4 | Out-File $PSLauncherConfigFile

	}
	if ($Execute) {
		Start-Process -FilePath 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -ArgumentList "-NoLogo -NoProfile -WindowStyle Hidden -ExecutionPolicy bypass -command ""& {Start-PSLauncher -PSLauncherConfigFile $($PSLauncherConfigFile)}"""
	}

} #end Function
