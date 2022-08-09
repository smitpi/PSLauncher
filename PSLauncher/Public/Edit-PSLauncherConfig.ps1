
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
Edit-PSLauncherConfig -PSLauncherConfigFile c:\temp\PSLauncherConfig.json

#>
Function Edit-PSLauncherConfig {
	[Cmdletbinding(HelpURI = 'https://smitpi.github.io/PSLauncher/Edit-PSLauncherConfig')]
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
	Write-Color 'Do you want to Configure' -Color DarkYellow -LinesAfter 1
	Write-Color '0', ') ', 'Add a Panel' -Color Yellow, Yellow, Green
	Write-Color '1', ') ', 'Add a Button' -Color Yellow, Yellow, Green
	Write-Color '2', ') ', 'Bulk Add Buttons from script folder' -Color Yellow, Yellow, Green
	Write-Color '3', ') ', 'ReOrder Existing Panels' -Color Yellow, Yellow, Green
	Write-Color '4', ') ', 'ReOrder Existing Buttons' -Color Yellow, Yellow, Green
	Write-Color '6', ') ', 'Launch Color Picker Window' -Color Yellow, Yellow, Green
	Write-Color 'Q', ') ', 'Quit this menu' -Color Yellow, Yellow, Green
	Write-Output ' '
	$Choice = Read-Host 'Answer'

	if ($Choice.ToLower() -like 'q') {
		if ($Execute) {
			Start-Process -FilePath 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -ArgumentList "-NoLogo -NoProfile -WindowStyle Hidden -ExecutionPolicy bypass -command ""& {Start-PSLauncher -PSLauncherConfigFile $($PSLauncherConfigFile)}"""
		}
		exit
	} else {[int]$GuiAddChoice = $Choice}

	if ($GuiAddChoice -eq 0) {
		[System.Collections.Generic.List[psobject]]$data = $jsondata.Buttons
		Clear-Host
		$data.Add(
			[pscustomobject]@{
				name        = (Read-Host 'New Panel Name')
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
			Write-Color $index, ') ', $p.name -Color Yellow, Yellow, Green
			$index++
		}
		Write-Output ' '
		[int]$indexnum = Read-Host 'Panel Number '
			
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

		Write-Color 'Run As Different User:' -Color DarkRed -StartTab 1 -LinesBefore 2
		Write-Color '0) ', 'Yes' -Color Yellow, Green
		Write-Color '1) ', 'No' -Color Yellow, Green
		$modechoose = Read-Host 'Answer'
		switch ($modechoose) {
			'0' {$RunAsUser = read-host "PSCredential Variable Name "}
			'1' {$RunAsUser = 'LoggedInUser'}
		}

		Write-Color 'Run As Admin:' -Color DarkRed -StartTab 1 -LinesBefore 2
		Write-Color '0) ', 'Yes' -Color Yellow, Green
		Write-Color '1) ', 'No' -Color Yellow, Green
		$modechoose = Read-Host 'Answer'
		switch ($modechoose) {
			'0' {$RunAs = 'Yes'}
			'1' {$RunAs = 'No'}
		}

		if ([string]::IsNullOrEmpty($jsondata.Buttons[$indexnum].Buttons.id)) {[int]$ID = 0}
		else { [int]$ID = (($jsondata.Buttons[$indexnum].Buttons.id | Sort-Object -Descending | Select-Object -First 1) + 1)}
		[System.Collections.Generic.List[psobject]]$TempButtons = @()
		$jsondata.Buttons[$indexnum].Buttons | ForEach-Object {$TempButtons.Add($_)}
		$TempButtons.Add([PSCustomObject] @{
				ID         = $ID
				Name       = $name
				Command    = $cmd.command
				Arguments  = $cmd.arguments
				Mode       = $cmd.mode
				Window     = $Window
				RunAsUser  = $RunAsUser
				RunAsAdmin = $RunAs
			})
		$jsondata.Buttons[$indexnum].Buttons = $TempButtons
		$jsondata | ConvertTo-Json -Depth 5 | Out-File $PSLauncherConfigFile
	}
	if ($GuiAddChoice -eq 6) {
		Start-Process -FilePath 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -ArgumentList "-NoLogo -NoProfile -WindowStyle Hidden -ExecutionPolicy bypass -command ""& {Start-PSLauncherColorPicker -PSLauncherConfigFile $($PSLauncherConfigFile)}"""
	}
	if ($GuiAddChoice -eq 3) {
		[System.Collections.Generic.List[psobject]]$SortData = $jsondata.buttons
		[System.Collections.Generic.List[psobject]]$NewSortData = @()
		$index1 = 0
		do {
			Clear-Host
			Write-Color 'Select the next Panel (Left to Right)' -Color DarkYellow -LinesAfter 1
			$index = 0
			foreach ($d in $SortData) {
				Write-Color $index, ') ', $d.name -Color Yellow, Yellow, Green
				$index++
			}
			[int]$indexnum = Read-Host 'Panel Number '
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
			Write-Color $index, ') ', $p.name -Color Yellow, Yellow, Green
			$index++
		}
		Write-Output ' '
		[int]$indexnum = Read-Host 'Panel Number '

		[System.Collections.Generic.List[psobject]]$SortData = $jsondata.Buttons[$indexnum].buttons
		[System.Collections.Generic.List[psobject]]$NewSortData = @()
		$index1 = 0
		do {
			Clear-Host
			Write-Color 'Select the next Button (Top to Bottom)' -Color DarkYellow -LinesAfter 1
			$index = 0
			foreach ($d in $SortData) {
				Write-Color $index, ') ', $d.name -Color Yellow, Yellow, Green
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
		$jsondata | ConvertTo-Json -Depth 5 | Out-File $PSLauncherConfigFile
	}
	if ($GuiAddChoice -eq 2) {
		[System.Collections.Generic.List[psobject]]$data = $jsondata.Buttons
		$index = 0
		Clear-Host
		Write-Color 'Select the panel where the button will be added' -Color DarkYellow -LinesAfter 1
		foreach ($p in $data) {
			Write-Color $index, ') ', $p.name -Color Yellow, Yellow, Green
			$index++
		}
		Write-Output ' '
		[int]$indexnum = Read-Host 'Panel Number '

		try {
			$folder = Get-Item (Read-Host 'Path to script ps1 files')
			$files = Get-ChildItem "$($folder.FullName)\*.ps1"
		} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}

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

		[System.Collections.Generic.List[psobject]]$TempButtons = @()
		$jsondata.Buttons[$indexnum].Buttons | ForEach-Object {$TempButtons.Add($_)}
		foreach ($psfile in $files) {
			if ([string]::IsNullOrEmpty($jsondata.Buttons[$indexnum].Buttons.id)) {[int]$ID = 0}
			else { [int]$ID = (($jsondata.Buttons[$indexnum].Buttons.id | Sort-Object -Descending | Select-Object -First 1) + 1)}
			
			$TempButtons.Add([PSCustomObject] @{
					ID         = $ID
					Name       = $psfile.BaseName
					Command    = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
					Arguments  = $psfile.FullName
					Mode       = 'PSFile'
					Window     = $Window
					RunAsAdmin = $RunAs
				})	
		}
		$jsondata.Buttons[$indexnum].Buttons = $TempButtons
		$jsondata | ConvertTo-Json -Depth 5 | Out-File $PSLauncherConfigFile
	}
	if ($GuiAddChoice -eq 5) {
		do {
			[System.Collections.Generic.List[psobject]]$data = $jsondata.Buttons
			$index = 0
			Clear-Host
			Write-Color 'Original Panel' -Color DarkYellow -LinesAfter 1
			foreach ($p in $data) {
				Write-Color $index, ') ', $p.name -Color Yellow, Yellow, Green
				$index++
			}
			Write-Output ' '
			[int]$indexnum = Read-Host 'Panel Number '

			[System.Collections.Generic.List[psobject]]$OldPanel = @()
			$jsondata.buttons[$indexnum].Buttons | ForEach-Object {[void]$OldPanel.Add($_)}
			$index = 0
			Write-Color 'Button to move' -Color DarkYellow -LinesAfter 1
			foreach ($but in $OldPanel) {
    Write-Color $index, ') ', $but.name -Color Yellow, Yellow, Green
    $index++
			}
			Write-Output ' '
			[int]$indexbut = Read-Host 'Button Number '

			$index = 0
			Write-Color 'Destination Panel' -Color DarkYellow -LinesAfter 1
			foreach ($p in $data) {
				Write-Color $index, ') ', $p.name -Color Yellow, Yellow, Green
				$index++
			}
			Write-Output ' '
			[int]$destnum = Read-Host 'Panel Number '
			[System.Collections.Generic.List[psobject]]$NewPanel = @()
			$jsondata.buttons[$destnum].Buttons | ForEach-Object {[void]$NewPanel.Add($_)}

			if ([string]::IsNullOrEmpty($NewPanel.id)) {$OldPanel[$indexbut].ID = 0}
			else {$OldPanel[$indexbut].ID = (($NewPanel.id | Sort-Object -Descending)[0] + 1)}
 
			[void]$NewPanel.Add($OldPanel[$indexbut])
			[void]$OldPanel.Remove($OldPanel[$indexbut])

			$NewPanel | Where-Object {$_ -like $null} | ForEach-Object {$NewPanel.Remove($_)}
			$OldPanel | Where-Object {$_ -like $null} | ForEach-Object {$OldPanel.Remove($_)}

			$buttonsort = 0
			$OldPanel | Sort-Object -Property ID | ForEach-Object {
    $_.ID = $buttonsort
    $buttonsort++
			}

			$jsondata.buttons[$indexnum].Buttons = $OldPanel
			$jsondata.buttons[$destnum].Buttons = $NewPanel
			$jsondata | ConvertTo-Json -Depth 5 | Out-File $PSLauncherConfigFile

			$check = Read-Host 'Move another button (y/n) '
		}
		while ($check.ToLower() -notlike 'n')
	}
	if ($Execute) {
		Start-Process -FilePath 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -ArgumentList "-NoLogo -NoProfile -WindowStyle Hidden -ExecutionPolicy bypass -command ""& {Start-PSLauncher -PSLauncherConfigFile $($PSLauncherConfigFile)}"""
	}

} #end Function
