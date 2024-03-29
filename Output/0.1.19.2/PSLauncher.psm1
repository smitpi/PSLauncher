﻿#region Public Functions
#region Edit-PSLauncherConfig.ps1
######## Function 1 of 4 ##################
# Function:         Edit-PSLauncherConfig
# Module:           PSLauncher
# ModuleVersion:    0.1.19.2
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/08/09 20:43:29
# ModifiedOn:       2022/08/21 00:12:17
# Synopsis:         Add a button or panel to the config.
#############################################
 
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
	Write-Color '2', ') ', 'Bulk Add Buttons from Script Folder' -Color Yellow, Yellow, Green
	Write-Color '3', ') ', 'ReOrder Existing Panels' -Color Yellow, Yellow, Green
	Write-Color '4', ') ', 'ReOrder Existing Buttons' -Color Yellow, Yellow, Green
	Write-Color '6', ') ', 'Launch Color Picker Window' -Color Yellow, Yellow, Green
	Write-Color '7', ') ', 'Remove a Button' -Color Yellow, Yellow, Green
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
				Name        = (Read-Host 'New Panel Name')
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
			'0' {$RunAsUser = Read-Host 'PSCredential Variable Name '}
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

		Write-Color 'Run As Different User:' -Color DarkRed -StartTab 1 -LinesBefore 2
		Write-Color '0) ', 'Yes' -Color Yellow, Green
		Write-Color '1) ', 'No' -Color Yellow, Green
		$modechoose = Read-Host 'Answer'
		switch ($modechoose) {
			'0' {$RunAsUser = Read-Host 'PSCredential Variable Name '}
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
					RunAsUser  = $RunAsUser
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
	if ($GuiAddChoice -eq 7) {
		[System.Collections.Generic.List[psobject]]$data = $jsondata.Buttons
		$index = 0
		Clear-Host
		Write-Color 'Select the panel' -Color DarkYellow -LinesAfter 1
		foreach ($p in $data) {
			Write-Color $index, ') ', $p.name -Color Yellow, Yellow, Green
			$index++
		}
		Write-Output ' '
		[int]$indexnum = Read-Host 'Panel Number '

		[System.Collections.Generic.List[psobject]]$SortData = $jsondata.Buttons[$indexnum].buttons
		Clear-Host
		Write-Color 'Select the Button' -Color DarkYellow -LinesAfter 1
		$index = 0
		foreach ($d in $SortData) {
			Write-Color $index, ') ', $d.name -Color Yellow, Yellow, Green
			$index++
		}
		[int]$num = Read-Host 'Button Number '
		$SortData.Remove($SortData[$num])
		$index = 0 
		$SortData | ForEach-Object {
			$_.id = $index
			$index++
		}

		$jsondata.Buttons[$indexnum].buttons = $SortData
		$jsondata | ConvertTo-Json -Depth 5 | Out-File $PSLauncherConfigFile
	}
	if ($Execute) {
		Start-Process -FilePath 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -ArgumentList "-NoLogo -NoProfile -WindowStyle Hidden -ExecutionPolicy bypass -command ""& {Start-PSLauncher -PSLauncherConfigFile $($PSLauncherConfigFile)}"""
	}

} #end Function
 
Export-ModuleMember -Function Edit-PSLauncherConfig
#endregion
 
#region New-PSLauncherConfigFile.ps1
######## Function 2 of 4 ##################
# Function:         New-PSLauncherConfigFile
# Module:           PSLauncher
# ModuleVersion:    0.1.19.2
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/08/09 19:17:56
# ModifiedOn:       2022/09/01 18:57:11
# Synopsis:         Creates the config file with the provided settings
#############################################
 
<#
.SYNOPSIS
Creates the config file with the provided settings

.DESCRIPTION
Creates the config file with the provided settings

.PARAMETER Description
Text to be used in the info panel.

.PARAMETER Color1
Run Start-PSLauncherColorPicker to change.

.PARAMETER Color2
Run Start-PSLauncherColorPicker to change.

.PARAMETER LabelColor
Run Start-PSLauncherColorPicker to change.

.PARAMETER ButtonColor
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
        [string]$Description,
        [string]$Color1 = '#E5E5E5',
        [string]$Color2 = '#061820',
        [string]$LabelColor = '#FFD400',
        [string]$ButtonColor = '#84ae46',
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
                       "Description": "$Description",
                       "Color2nd":  "$color2",
                       "LabelColor": "$labelColor",
                       "ButtonColor": "$ButtonColor",
                       "TextColor": "$TextColor",
                       "LogoUrl":  "$LogoPath",
                       "AppTitle":  "$title"
                   }
               ],
    "Buttons":  [
                    {
                        "name":  "$Panel01",
                        "PanelNumber":  0,
                        "Buttons":  {

                                    }

                                    
                    },
                                        {
                        "name":  "$Panel02",
                        "PanelNumber":  1,
                        "Buttons":  {

                                    }
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
        Start-Process explorer.exe $ConfigPath
    }

    if ($LaunchColorPicker -like $true) {
        Start-PSLauncherColorPicker -PSLauncherConfigFile (Join-Path $ConfigPath -ChildPath \PSLauncherConfig.json)
    }
} #end Function
 
Export-ModuleMember -Function New-PSLauncherConfigFile
#endregion
 
#region Start-PSLauncher.ps1
######## Function 3 of 4 ##################
# Function:         Start-PSLauncher
# Module:           PSLauncher
# ModuleVersion:    0.1.19.2
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/08/09 19:17:56
# ModifiedOn:       2022/09/08 08:47:36
# Synopsis:         Reads the config file and launches the GUI
#############################################
 
<#
.SYNOPSIS
Reads the config file and launches the GUI

.DESCRIPTION
Reads the config file and launches the GUI

.PARAMETER PSLauncherConfigFile
Path to the config file created by New-PSLauncherConfigFile

.EXAMPLE
Start-PSLauncher -PSLauncherConfigFile c:\temp\config.json

#>
Function Start-PSLauncher {
    [Cmdletbinding(HelpURI = 'https://smitpi.github.io/Start-PSLauncher/')]
    Param (
        [System.IO.FileInfo]$PSLauncherConfigFile
    )

        #region load json config file
        try {
            $Script:jsondata = Get-Content $PSLauncherConfigFile | ConvertFrom-Json -ErrorAction stop
        } catch {
            Add-Type -AssemblyName System.Windows.Forms
            $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ Filter = 'JSON | *.json' }
            [void]$FileBrowser.ShowDialog()
            $PSLauncherConfigFile = Get-Item $FileBrowser.FileName
            $Script:jsondata = Get-Content $PSLauncherConfigFile | ConvertFrom-Json
        }
        $users = $jsondata.buttons.buttons | Where-Object {$_.RunAsUser -notlike 'LoggedInUser'} 
        foreach ($User in ($users.RunAsUser | Sort-Object -Unique)) {
            $exists = Get-Variable -Name $User -ErrorAction SilentlyContinue
            $Vartype = (Get-Variable -Name $User -ErrorAction SilentlyContinue).Value.GetType().Name
            if (-not($exists) -or $Vartype -notlike 'PSCredential') {
                $tmp = Get-Credential -Message "Username and password for $($User)"
                New-Variable -Name $User -Value $tmp -Option AllScope -Visibility Public -Scope global -Force
                Write-Color '[PSCredential]: ', "$($User): ", 'Complete' -Color Yellow, Cyan, Green
            } else {Write-Color '[PSCredential]: ', "$($User): ", 'Already Created' -Color Yellow, Cyan, DarkGray}
        }
        #endregion

        #region load psconfigfile json config file
        # try {
        #     Invoke-PSConfigFile -ConfigFile (Get-Item $PSLauncherCredentialFile).FullName -DisplayOutput -ErrorAction Stop
        # } catch {
        #     Add-Type -AssemblyName System.Windows.Forms
        #     $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ Filter = 'JSON | *.json' }
        #     [void]$FileBrowser.ShowDialog()
        #     Invoke-PSConfigFile -ConfigFile (Get-Item $FileBrowser.FileName).FullName -DisplayOutput -ErrorAction Stop
        # }
        #endregion

        #region variables
        $script:LoggingEnabled = $false
        $script:PanelDraw = 10
        $script:Color1st = $jsondata.Config.Color1st
        $script:Color2nd = $jsondata.Config.Color2nd #The darker background for the panels
        $script:ButtonColor = $jsondata.Config.ButtonColor 
        $script:LabelColor = $jsondata.Config.LabelColor
        $script:TextColor = $jsondata.Config.TextColor
        #endregion

        #region Assembly
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.Application]::EnableVisualStyles()
        # Declare assemblies
        [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null
        [System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | Out-Null
        [System.Reflection.Assembly]::LoadWithPartialName('System.Drawing') | Out-Null
        [System.Reflection.Assembly]::LoadWithPartialName('WindowsFormsIntegration') | Out-Null

        Add-Type -AssemblyName 'System.Windows.Forms'
        Add-Type -Name Window -Namespace Console -MemberDefinition '
    [DllImport("Kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
        $Script:PSConsole = [Console.Window]::GetConsoleWindow()

        #endregion

        #region functions
        function ShowConsole {
            [Console.Window]::ShowWindow($PSConsole, 5)
        }
        function HideConsole {
            [Console.Window]::ShowWindow($PSConsole, 0)
        }
        Function Invoke-Action {
            Param (
                [string]$command,
                [string]$arguments,
                [string]$mode,
                [string]$Window,
                [string]$RunAsUser,
                [string]$RunAsAdmin
            )
            [hashtable]$processArguments = @{
                #'PassThru' = $($true)
                'FilePath' = $command
            }

            if ( $RunAsAdmin -like 'yes' ) { $processArguments.Add( 'Verb' , 'RunAs' )}
            if ( $Window -contains 'Hidden') { $processArguments.Add('WindowStyle' , 'Hidden') }
            if ( $Window -contains 'Normal') { $processArguments.Add('WindowStyle' , 'Normal') }
            if ( $Window -contains 'Maximized') { $processArguments.Add('WindowStyle' , 'Maximized') }
            if ( $Window -contains 'Minimized') { $processArguments.Add('WindowStyle' , 'Minimized') }

            if ($mode -eq 'PSFile') { $AddedArguments = "-NoLogo  -NoProfile -ExecutionPolicy Bypass -File `"$arguments`"" }
            if ($mode -eq 'PSCommand') { $AddedArguments = "-NoLogo -NoProfile -ExecutionPolicy Bypass -command ""(& {$arguments})""" }
            if (-not($mode -eq 'Other') -and $LoggingEnabled) {$AddedArguments = '-NoExit ' + $AddedArguments}
            if ($mode -eq 'Other') { $AddedArguments = $arguments}
            if (-not[string]::IsNullOrEmpty( $AddedArguments)) {$processArguments.Add( 'ArgumentList' , [Environment]::ExpandEnvironmentVariables( $AddedArguments)) }
        
            if ($RunAsUser -like 'LoggedInUser') {
                try {
                    Write-Color 'Running the following ', 'as LoggonUser:' -Color DarkYellow, DarkCyan -ShowTime
                    $processArguments.GetEnumerator().name | ForEach-Object {Write-Color ('{0,-15}:' -f "$($_)"), ('{0}' -f "$($processArguments.$($_))") -ForegroundColor Cyan, Green -ShowTime}
                    Start-Process @processArguments -ErrorAction Stop
                } catch {
                    $Text = $This.Text
                    [System.Windows.Forms.MessageBox]::Show("Failed to launch $Text`n`nMessage:$($_.Exception.Message)`nItem:$($_.Exception.ItemName)") > $null
                }
            } else {
                try {
                    $ModProcessArg = $processArguments
                    $ModProcessArg.ArgumentList = "'" + $($ModProcessArg.ArgumentList) + "'"
                    $params = "Start-Process $([string]::Join(' ', ($ModProcessArg.GetEnumerator() | ForEach-Object {"-$($_.Key) $($_.Value)"})))"
                    $BigHash = @{
                        'FilePath'     = 'powershell.exe'
                        'ArgumentList' = "-NoLogo -NoProfile -ExecutionPolicy Bypass -command ""(& {$params})"""
                        'WindowStyle'  = 'Hidden'
                        'Credential'   = (Get-Variable -Name $RunAsUser -ValueOnly)
                    }
                    if ($LoggingEnabled) {$BigHash.ArgumentList = '-NoExit ' + $BigHash.ArgumentList}
                    Write-Color 'Running the following ', "as $((Get-Variable -Name $RunAsUser -ValueOnly).username):" -Color DarkYellow, DarkCyan -ShowTime
                    $BigHash.GetEnumerator().name | ForEach-Object {Write-Color ('{0,-15}:' -f "$($_)"), ('{0}' -f "$($BigHash.$($_))") -ForegroundColor Cyan, Green -ShowTime}
                    Start-Process @BigHash
                } catch {
                    $Text = $This.Text
                    [System.Windows.Forms.MessageBox]::Show("Failed to launch $Text`n`nMessage:$($_.Exception.Message)`nItem:$($_.Exception.ItemName)") > $null
                }
            }
        }
 
        function NButton {
            param(
                [string]$Text = 'Placeholder Text',
                [scriptblock]$clickAction,
                [System.Windows.Forms.Panel]$panel
            )

            if (($panel.Size.Width) -lt 220) {$bwidth = 100}
            else {$bwidth = ($panel.Size.Width - 20)}

            $Button = New-Object system.Windows.Forms.Button
            $Button.text = $text
            $Button.width = $bwidth
            $Button.height = 30
            $Button.BackColor = [System.Drawing.ColorTranslator]::FromHtml($script:ButtonColor)
            $Button.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($script:TextColor)
            $Button.location = New-Object System.Drawing.Point(10, $panel.ButtonDraw)
            $Button.Font = New-Object System.Drawing.Font('Tahoma', 10)
            $button.add_click( $clickAction )
            $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Popup

            $panel.ButtonDraw = $panel.ButtonDraw + 35
            $Panel.controls.AddRange($button)
        }
        function NPanel {
            param(
                [string]$LabelText = 'Placeholder Text'
            )

            $Label = New-Object system.Windows.Forms.Label
            $Label.text = $LabelText
            $Label.AutoSize = $false
            $Label.TextAlign = [System.Drawing.ContentAlignment]::TopCenter
            $Label.Dock = [System.Windows.Forms.DockStyle]::Top
            $Label.width = $Label.PreferredWidth
            $Label.height = 50
            $Label.location = New-Object System.Drawing.Point(10, 10)
            $Label.Font = [System.Drawing.Font]::new('Tahoma', 24, [System.Drawing.FontStyle]::Bold)
            $Label.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($script:LabelColor)
            $Label.Refresh()

            if ($Label.PreferredWidth -lt 230) {$pwidth = 220}
            else {$pwidth = ($Label.PreferredWidth + 10)}

            $Panel = New-Object system.Windows.Forms.Panel
            $Panel.height = 490
            $Panel.width = $pwidth
            $Panel.location = New-Object System.Drawing.Point($PanelDraw, 10)
            $Panel.BorderStyle = 'Fixed3D'
            $Panel.BackColor = [System.Drawing.ColorTranslator]::FromHtml($script:Color2nd)
            $panel.AutoScroll = $true
            $panel.AutoSizeMode = 'GrowAndShrink'
            $Panel.Refresh()

            $Panel | Add-Member -Name ButtonDraw -Value 90 -MemberType NoteProperty
            $Panel.controls.AddRange(@($Label))
            $Form.controls.AddRange($Panel)

            $Panel
            $script:PanelDraw = $script:PanelDraw + $Panel.Size.Width

        }
        function EnableLogging {
            ShowConsole
            $script:LoggingEnabled = $True
            $script:GUIlogpath = "$($env:TEMP)\PSLauncher-$(Get-Date -Format yyyy.MM.dd-HH.mm).log"
            Write-Color 'Creating log file: ', $($GUIlogpath) -Color DarkYellow, DarkRed -ShowTime -LinesBefore 1
            Write-Color 'Starting Transcript.' -Color DarkYellow -ShowTime -LinesAfter 2
            Start-Transcript -Path $GUIlogpath -IncludeInvocationHeader -Force -NoClobber
        }
        function DisableLogging {
            Write-Color 'Stopping Transcript.' -Color DarkYellow -ShowTime -LinesBefore 2
            Write-Color 'Opening log file: ', $($GUIlogpath) -Color DarkYellow, DarkRed -ShowTime
            $script:LoggingEnabled = $false
            Stop-Transcript
            . (Get-Item $GUIlogpath).FullName
            HideConsole
        }
        #endregion

        #region GUI Icon
        $iconBase64 = 'AAABAAEAICAQMAAAAADoAgAAFgAAACgAAAAgAAAAQAAAAAEABAAAAAAAgAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAACAAAAAgIAAgAAAAIAAgACAgAAAgICAAMDAwAAAAP8AAP8AAAD//wD/AAAA/wD/AP//AAD///8AAAAAAAAHd3d3d3AAAAAAAAAAAAAHeIiIiIh3dwAAAAAAAAAHeIh3qqd4/4dwAAAAAAAAeIhqqqqqqqeId3AAAAAAd4hyIiqqqqqqp4d3AAAAAHiCIiIiqqqqqqqoh3AAAAeIIiIiIiqqqqqqqodwAAB4giIiIiIiqqqqqqqodwAAiCIiIiIiIqqqIqqqp4dwB4ciIidyIiIqqogqqqqHcAiCIiJ4hyIiIiiIgqqqeHAIiqIieIhyIiKIiPeqqqh3eHqiIieIhyIniIh6qqqnd3h3eqoieIhyeIiHIiIqp3eId3eqqieIiIiIciIiIqeHiHd3eqqieIiIhyIiIiKmh4h3d3eqqniIiHIiIiIiJoeId3d3eqJ4iIhyIiIiIieHiHd3d3cniIiIhyIiIiKnd3h3d3d3iIiHeIhyIiIip3cIh3d3eIiIeieIhyIiIqh3CId3d4+IiHqieIhyIip4cAeId3eP/4d3d3iIgiIqh3AAiId3ePh3d3d3iHd6p4cAAHiId3eHd3d3d3d3eniHAAAI+Id3d3d3d3d3d3eIcAAAAI+Id3d3d3d3d3d4hwAAAAAI+Ih3d3d3d3d3iHAAAAAAAIiIiHd3d3d3iIcAAAAAAAAHiIiIiIeIiIdwAAAAAAAAAAeIiIiIiIdwAAAAAAAAAAAAAHeIiHcAAAAAAAD/8Af//4AB//4AAH/8AAA/+AAAD/AAAA/gAAAHwAAAA8AAAAOAAAABgAAAAYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAGAAAABgAAAAcAAAAPAAAAD4AAAB/AAAA/4AAAf/AAAP/4AAH//gAH///AP/w=='
        $iconBytes = [Convert]::FromBase64String($iconBase64)
        $stream = New-Object IO.MemoryStream($iconBytes, 0, $iconBytes.Length)
        $stream.Write($iconBytes, 0, $iconBytes.Length)
        #endregion

        #region build main form
        $module = Get-Module pslauncher
        if (-not($module)) {$module = Get-Module pslauncher -ListAvailable}

        $Form = New-Object system.Windows.Forms.Form
        $Form.ClientSize = New-Object System.Drawing.Point(1050, 800)
        $Form.text = "$($jsondata.Config.AppTitle) (ver: $($module.Version)) "
        $Form.StartPosition = 'CenterScreen'
        $Form.TopMost = $false
        $Form.BackColor = [System.Drawing.ColorTranslator]::FromHtml($script:Color1st)
        $Form.AutoScaleDimensions = '256, 256'
        $Form.AutoScaleMode = 'Dpi'
        $Form.AutoScale = $True
        $Form.AutoSize = $True
        $Form.ClientSize = '1050, 800'
        $Form.FormBorderStyle = 'Fixed3D'
        $Form.Icon = [System.Drawing.Icon]::FromHandle((New-Object System.Drawing.Bitmap -Argument $stream).GetHIcon())
        $Form.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink
        $Form.AutoScroll = $True
        $Form.Refresh()
        #endregion

        #region create panels and buttons
        $data = $jsondata.Buttons
        foreach ($pan in $data) {
            $panel = NPanel -LabelText $pan.name
            foreach ($but in $pan.buttons) {
                if (-not([string]::IsNullOrEmpty($but))) {
                    [scriptblock]$clickAction = [scriptblock]::Create( "Invoke-Action -control `$_ -name `"$($but.Name)`" -command `"$($but.command)`" -arguments `"$(($but|Select-Object -ExpandProperty arguments -ErrorAction SilentlyContinue) -replace '"' , '`"`"')`" -mode $($but.Mode) -Window `"$($but.Window)`" -RunAsUser `"$($but.RunAsUser)`" -RunAsAdmin `"$($but.RunAsAdmin)`"" )
                    NButton -Text $but.Name -clickAction $clickAction -panel $panel
                }
            }
        }
        #endregion

        #region bginfo
        $BGInfoPanel = New-Object system.Windows.Forms.Panel
        $BGInfoPanel.height = 490
        $BGInfoPanel.width = 420
        $BGInfoPanel.location = New-Object System.Drawing.Point($PanelDraw, 10)
        $BGInfoPanel.BorderStyle = 'Fixed3D'
        $BGInfoPanel.BackColor = [System.Drawing.ColorTranslator]::FromHtml($script:Color2nd)
        $BGInfoPanel.AutoScroll = $false
        $BGInfoPanel.AutoSizeMode = 'GrowAndShrink'
        $BGInfoPanel.Refresh()

        $CompNameLabel = New-Object system.Windows.Forms.Label
        $CompNameLabel.text = "$(($env:COMPUTERNAME).ToUpper())"
        $CompNameLabel.AutoSize = $false
        $CompNameLabel.Dock = [System.Windows.Forms.DockStyle]::Top
        $CompNameLabel.width = 400
        $CompNameLabel.height = 50    
        $CompNameLabel.location = New-Object System.Drawing.Point(1, 10)
        $CompNameLabel.Font = [System.Drawing.Font]::new('Tahoma', 20, [System.Drawing.FontStyle]::Bold)
        $CompNameLabel.TextAlign = [System.Drawing.ContentAlignment]::TopCenter
        $CompNameLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($script:LabelColor)
        $CompNameLabel.Refresh()
        $BGInfoPanel.controls.AddRange(@($CompNameLabel))


        $DestriptionLabel = New-Object system.Windows.Forms.Label
        $DestriptionLabel.text = $jsondata.Config.Description
        $DestriptionLabel.AutoSize = $false
        $DestriptionLabel.width = 420
        $DestriptionLabel.height = 30
        $DestriptionLabel.location = New-Object System.Drawing.Point(1, 60)
        $DestriptionLabel.Font = [System.Drawing.Font]::new('Tahoma', 16)
        $DestriptionLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
        $DestriptionLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($script:LabelColor)
        $DestriptionLabel.Refresh()
        $BGInfoPanel.controls.AddRange(@($DestriptionLabel))

        $LineLabel = New-Object system.Windows.Forms.Label
        $LineLabel.text = ''
        $LineLabel.AutoSize = $false
        $LineLabel.width = 420
        $LineLabel.height = 2
        $LineLabel.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
        $LineLabel.location = New-Object System.Drawing.Point(1, 100)
        $LineLabel.Refresh()
        $BGInfoPanel.controls.AddRange(@($LineLabel))

        ### Build Clock
        ###

        try {
            $BginfoDetails = [PSCustomObject]@{
                'PC Domain'    = [string]((Get-CimInstance -ClassName Win32_ComputerSystem).domain).tolower()
                'User Name'    = "$($env:USERDOMAIN)\$(($env:USERNAME).ToLower())"
                'User Domain'  = ($env:USERDNSDOMAIN).tolower()
                OS             = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
                'Boot Time'    = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
                'Install Date' = (Get-CimInstance -ClassName Win32_OperatingSystem).InstallDate
                Memory         = "$([Math]::Round((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1gb)) GB"
                IP             = @(((Get-CimInstance -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=$true).ipaddress | Out-String).Trim())
                'Free Space'   = @(((Get-CimInstance -Namespace root/cimv2 -ClassName win32_logicaldisk | Where-Object {$_.DriveType -like 3} | ForEach-Object {"$($_.DeviceID) $([Math]::Round($_.FreeSpace / 1gb)) GB"}) | Out-String).trim())
            }
        } catch {Write-Warning 'Unable to collect pc details'}
    
        $HightIndex = 110
        $BginfoDetails.psobject.properties | Select-Object name, value | ForEach-Object {
            $TmpLabelName = New-Object system.Windows.Forms.Label
            $TmpLabelName.text = $_.name
            $TmpLabelName.AutoSize = $false
            $TmpLabelName.width = 150
            $TmpLabelName.height = 10
            $TmpLabelName.location = New-Object System.Drawing.Point(10, $HightIndex)
            $TmpLabelName.Font = [System.Drawing.Font]::new('Tahoma', 10, [System.Drawing.FontStyle]::Bold)
            $TmpLabelName.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
            $TmpLabelName.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($script:LabelColor)
            $TmpLabelName.Refresh()
            $BGInfoPanel.controls.AddRange(@($TmpLabelName))


            $TmpLabelValue = New-Object system.Windows.Forms.Label
            $TmpLabelValue.text = $_.value
            $TmpLabelValue.AutoSize = $true
            $TmpLabelValue.width = 250
            $TmpLabelValue.height = 10
            $TmpLabelValue.location = New-Object System.Drawing.Point(160, $HightIndex)
            $TmpLabelValue.Font = [System.Drawing.Font]::new('Tahoma', 10)
            $TmpLabelValue.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
            $TmpLabelValue.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($script:LabelColor)
            $TmpLabelValue.Refresh()
            $BGInfoPanel.controls.AddRange(@($TmpLabelValue))

            $HightIndex = $HightIndex + $TmpLabelValue.Size.Height + 5
       
        }
        #endregion

        #region buttons
        $exit = New-Object system.Windows.Forms.Button
        $exit.text = 'Exit'
        $exit.width = 100
        $exit.height = 30
        $exit.location = New-Object System.Drawing.Point(10, 510)
        $exit.Font = New-Object System.Drawing.Font('Tahoma', 8)
        $exit.BackColor = [System.Drawing.ColorTranslator]::FromHtml($script:ButtonColor)
        $exit.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($script:TextColor)
        $exit.FlatStyle = [System.Windows.Forms.FlatStyle]::Popup
        $exit.Add_Click( {
                Write-Output 'exiting Util'
                $Form.Close()
            })

        $reload = New-Object system.Windows.Forms.Button
        $reload.FlatStyle = [System.Windows.Forms.FlatStyle]::Popup
        $reload.text = 'Reload'
        $reload.width = 100
        $reload.height = 30
        $reload.location = New-Object System.Drawing.Point(115, 510)
        $reload.Font = New-Object System.Drawing.Font('Tahoma', 8)
        $reload.BackColor = [System.Drawing.ColorTranslator]::FromHtml($script:ButtonColor)
        $reload.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($script:TextColor)
        $reload.Add_Click( {
                Write-Output 'Reloading Util'
                Start-Process -FilePath 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -ArgumentList "-NoLogo -NoProfile -WindowStyle Hidden -ExecutionPolicy bypass -command ""& {Start-PSLauncher -PSLauncherConfigFile $($PSLauncherConfigFile)}"""
                $Form.Close()
            })

        $AddToConfig = New-Object system.Windows.Forms.Button
        $AddToConfig.FlatStyle = [System.Windows.Forms.FlatStyle]::Popup
        $AddToConfig.text = 'Edit GUI Config'
        $AddToConfig.width = 100
        $AddToConfig.height = 30
        $AddToConfig.location = New-Object System.Drawing.Point(10, 545)
        $AddToConfig.Font = New-Object System.Drawing.Font('Tahoma', 8)
        $AddToConfig.BackColor = [System.Drawing.ColorTranslator]::FromHtml($script:ButtonColor)
        $AddToConfig.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($script:TextColor)
        $AddToConfig.Add_Click( {
                Start-Process -FilePath 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -ArgumentList "-NoLogo -NoProfile -ExecutionPolicy bypass -command ""& {Edit-PSLauncherConfig -PSLauncherConfigFile $($PSLauncherConfigFile) -execute}"""
                $Form.Close()
            })

        $OpenConfigButton = New-Object system.Windows.Forms.Button
        $OpenConfigButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Popup
        $OpenConfigButton.text = 'Open Config File'
        $OpenConfigButton.width = 100
        $OpenConfigButton.height = 30
        $OpenConfigButton.location = New-Object System.Drawing.Point(115, 545)
        $OpenConfigButton.Font = New-Object System.Drawing.Font('Tahoma', 8)
        $OpenConfigButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml($script:ButtonColor)
        $OpenConfigButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($script:TextColor)
        $OpenConfigButton.Add_Click( { . $PSLauncherConfigFile })

        $EnableLogging = New-Object system.Windows.Forms.Button
        $EnableLogging.FlatStyle = [System.Windows.Forms.FlatStyle]::Popup
        $EnableLogging.text = 'Enable Logging'
        $EnableLogging.width = 100
        $EnableLogging.height = 30
        $EnableLogging.location = New-Object System.Drawing.Point(10, 580)
        $EnableLogging.Font = New-Object System.Drawing.Font('Tahoma', 8)
        $EnableLogging.BackColor = [System.Drawing.ColorTranslator]::FromHtml($script:ButtonColor)
        $EnableLogging.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($script:TextColor)
        $EnableLogging.Add_Click( { EnableLogging })

        $DisableLogging = New-Object system.Windows.Forms.Button
        $DisableLogging.FlatStyle = [System.Windows.Forms.FlatStyle]::Popup
        $DisableLogging.text = 'Disable Logging'
        $DisableLogging.width = 100
        $DisableLogging.height = 30
        $DisableLogging.location = New-Object System.Drawing.Point(115, 580)
        $DisableLogging.Font = New-Object System.Drawing.Font('Tahoma', 8)
        $DisableLogging.BackColor = [System.Drawing.ColorTranslator]::FromHtml($script:ButtonColor)
        $DisableLogging.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($script:TextColor)
        $DisableLogging.Add_Click( { DisableLogging })

        $Form.controls.AddRange($exit)
        $Form.controls.AddRange($reload)        
        $Form.controls.AddRange($EnableLogging)
        $Form.controls.AddRange($DisableLogging)
        $Form.controls.AddRange($AddToConfig)
        $Form.controls.AddRange($OpenConfigButton)
        $Form.controls.AddRange($BGInfoPanel)
        #endregion

        #region picture
        $PictureBox1 = New-Object system.Windows.Forms.PictureBox
        $PictureBox1.width = ($Form.Size.Width - 220)
        $PictureBox1.height = 100
        $PictureBox1.location = New-Object System.Drawing.Point(220, 510)
        $PictureBox1.imageLocation = $jsondata.Config.LogoUrl
        $PictureBox1.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
        $Form.controls.AddRange($PictureBox1)
        #endregion

        HideConsole
        [void]$Form.ShowDialog()
} #end Function
 
Export-ModuleMember -Function Start-PSLauncher
#endregion
 
#region Start-PSLauncherColorPicker.ps1
######## Function 4 of 4 ##################
# Function:         Start-PSLauncherColorPicker
# Module:           PSLauncher
# ModuleVersion:    0.1.19.2
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/08/09 19:17:56
# ModifiedOn:       2022/09/01 18:52:10
# Synopsis:         Launches a GUI form to test and change the Color of PSLauncher.
#############################################
 
<#
.SYNOPSIS
Launches a GUI form to test and change the Color of PSLauncher.

.DESCRIPTION
Launches a GUI form to test and change the Color of PSLauncher.

.PARAMETER PSLauncherConfigFile
Path to the config file created by New-PSLauncherConfigFile

.EXAMPLE
Start-PSLauncherColorPicker -PSLauncherConfigFile c:\temp\PSLauncherConfig.json

#>
Function Start-PSLauncherColorPicker {
    [Cmdletbinding(HelpURI = 'https://smitpi.github.io/Start-PSLauncherColorPicker/')]
    Param (
        [System.IO.FileInfo]$PSLauncherConfigFile
    )

    try {
        $Script:jsondata = Get-Content $PSLauncherConfigFile | ConvertFrom-Json -ErrorAction stop
    } catch {
        Add-Type -AssemblyName System.Windows.Forms
        $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ Filter = 'JSON | *.json' }
        [void]$FileBrowser.ShowDialog()
        $PSLauncherConfigFile = Get-Item $FileBrowser.FileName
        $Script:jsondata = Get-Content $PSLauncherConfigFile | ConvertFrom-Json
    }


    $script:PanelDraw = 10
    $script:Color1st = $jsondata.Config.Color1st
    $script:Color2nd = $jsondata.Config.Color2nd #The darker background for the panels
    $script:ButtonColor = $jsondata.Config.ButtonColor 
    $script:LabelColor = $jsondata.Config.LabelColor
    $script:TextColor = $jsondata.Config.TextColor


    #region Assembly
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.Application]::EnableVisualStyles()
    # Declare assemblies
    [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null
    [System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | Out-Null
    [System.Reflection.Assembly]::LoadWithPartialName('System.Drawing') | Out-Null
    [System.Reflection.Assembly]::LoadWithPartialName('WindowsFormsIntegration') | Out-Null

    Add-Type -AssemblyName 'System.Windows.Forms'

    Add-Type -Name Window -Namespace Console -MemberDefinition '
    [DllImport("Kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
    #endregion

    function ShowConsole {
        #Clear-Host
        $PSConsole = [Console.Window]::GetConsoleWindow()
        [Console.Window]::ShowWindow($PSConsole, 5)
    }
    function HideConsole {
        $PSConsole = [Console.Window]::GetConsoleWindow()
        [Console.Window]::ShowWindow($PSConsole, 0)
    }

    #region GUI Icon
    $iconBase64 = 'AAABAAEAICAQMAAAAADoAgAAFgAAACgAAAAgAAAAQAAAAAEABAAAAAAAgAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAACAAAAAgIAAgAAAAIAAgACAgAAAgICAAMDAwAAAAP8AAP8AAAD//wD/AAAA/wD/AP//AAD///8AAAAAAAAHd3d3d3AAAAAAAAAAAAAHeIiIiIh3dwAAAAAAAAAHeIh3qqd4/4dwAAAAAAAAeIhqqqqqqqeId3AAAAAAd4hyIiqqqqqqp4d3AAAAAHiCIiIiqqqqqqqoh3AAAAeIIiIiIiqqqqqqqodwAAB4giIiIiIiqqqqqqqodwAAiCIiIiIiIqqqIqqqp4dwB4ciIidyIiIqqogqqqqHcAiCIiJ4hyIiIiiIgqqqeHAIiqIieIhyIiKIiPeqqqh3eHqiIieIhyIniIh6qqqnd3h3eqoieIhyeIiHIiIqp3eId3eqqieIiIiIciIiIqeHiHd3eqqieIiIhyIiIiKmh4h3d3eqqniIiHIiIiIiJoeId3d3eqJ4iIhyIiIiIieHiHd3d3cniIiIhyIiIiKnd3h3d3d3iIiHeIhyIiIip3cIh3d3eIiIeieIhyIiIqh3CId3d4+IiHqieIhyIip4cAeId3eP/4d3d3iIgiIqh3AAiId3ePh3d3d3iHd6p4cAAHiId3eHd3d3d3d3eniHAAAI+Id3d3d3d3d3d3eIcAAAAI+Id3d3d3d3d3d4hwAAAAAI+Ih3d3d3d3d3iHAAAAAAAIiIiHd3d3d3iIcAAAAAAAAHiIiIiIeIiIdwAAAAAAAAAAeIiIiIiIdwAAAAAAAAAAAAAHeIiHcAAAAAAAD/8Af//4AB//4AAH/8AAA/+AAAD/AAAA/gAAAHwAAAA8AAAAOAAAABgAAAAYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAGAAAABgAAAAcAAAAPAAAAD4AAAB/AAAA/4AAAf/AAAP/4AAH//gAH///AP/w=='
    $iconBytes = [Convert]::FromBase64String($iconBase64)
    $stream = New-Object IO.MemoryStream($iconBytes, 0, $iconBytes.Length)
    $stream.Write($iconBytes, 0, $iconBytes.Length)
    #endregion

    #region build main form
    $Form = New-Object system.Windows.Forms.Form
    $Form.ClientSize = New-Object System.Drawing.Point(1050, 700)
    $Form.text = 'Pick Colors'
    $Form.StartPosition = 'CenterScreen'
    $Form.TopMost = $false
    $Form.BackColor = [System.Drawing.ColorTranslator]::FromHtml($Color1st)
    $Form.AutoScaleDimensions = '192, 192'
    $Form.AutoScaleMode = 'Dpi'
    $Form.AutoSize = $True
    $Form.ClientSize = '1050, 700'
    $Form.FormBorderStyle = 'Fixed3D'
    $Form.Icon = [System.Drawing.Icon]::FromHandle((New-Object System.Drawing.Bitmap -Argument $stream).GetHIcon())
    $Form.Width = 250
    $Form.Height = 600
    #endregion

    $Panel = New-Object system.Windows.Forms.Panel
    $Panel.height = 200
    $Panel.width = 220
    $Panel.location = New-Object System.Drawing.Point(20, 20)
    $Panel.BorderStyle = 'Fixed3D'
    $Panel.BackColor = [System.Drawing.ColorTranslator]::FromHtml($Color2nd)
    $Panel.AutoScroll = $true
    $Panel.AutoSizeMode = 'GrowAndShrink'

    $Label = New-Object system.Windows.Forms.Label
    $Label.text = 'Label'
    $Label.AutoSize = $true
    $Label.width = 200
    $Label.height = 30
    $Label.location = New-Object System.Drawing.Point(10, 10)
    $Label.Font = [System.Drawing.Font]::new('Tahoma', 24, [System.Drawing.FontStyle]::Bold)
    $Label.TextAlign = 'MiddleCenter'
    $Label.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($LabelColor)

    $box1 = New-Object System.Windows.Forms.TextBox
    $box1.AutoSize = $true
    $box1.Width = 100
    $box1.Height = 30
    $box1.Text = $Color1st
    $box1.Location = New-Object System.Drawing.Point(100, 260)
    $box1_Label = New-Object system.Windows.Forms.Label
    $box1_Label.text = 'Form Color'
    $box1_Label.AutoSize = $true
    $box1_Label.width = 100
    $box1_Label.height = 30
    $box1_Label.location = New-Object System.Drawing.Point(1, 260)
    $box1_Label.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($TextColor)


    $box2 = New-Object System.Windows.Forms.TextBox
    $box2.AutoSize = $true
    $box2.Width = 100
    $box2.Height = 30
    $box2.Text = $Color2nd
    $box2.Location = New-Object System.Drawing.Point(100, 290)
    $box2_Label = New-Object system.Windows.Forms.Label
    $box2_Label.text = 'Panel Color'
    $box2_Label.AutoSize = $true
    $box2_Label.width = 100
    $box2_Label.height = 30
    $box2_Label.location = New-Object System.Drawing.Point(1, 290)
    $box2_Label.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($TextColor)

    $box3 = New-Object System.Windows.Forms.TextBox
    $box3.AutoSize = $true
    $box3.Width = 100
    $box3.Height = 30
    $box3.Text = $LabelColor
    $box3.Location = New-Object System.Drawing.Point(100, 320)
    $box3_Label = New-Object system.Windows.Forms.Label
    $box3_Label.text = 'Label Color'
    $box3_Label.AutoSize = $true
    $box3_Label.width = 100
    $box3_Label.height = 30
    $box3_Label.location = New-Object System.Drawing.Point(1, 320)
    $box3_Label.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($TextColor)

    $box5 = New-Object System.Windows.Forms.TextBox
    $box5.AutoSize = $true
    $box5.Width = 100
    $box5.Height = 30
    $box5.Text = $TextColor
    $box5.Location = New-Object System.Drawing.Point(100, 350)
    $box5_Label = New-Object system.Windows.Forms.Label
    $box5_Label.text = 'Text Color'
    $box5_Label.AutoSize = $true
    $box5_Label.width = 100
    $box5_Label.height = 30
    $box5_Label.location = New-Object System.Drawing.Point(1, 350)
    $box5_Label.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($TextColor)

    $box6 = New-Object System.Windows.Forms.TextBox
    $box6.AutoSize = $true
    $box6.Width = 100
    $box6.Height = 30
    $box6.Text = $ButtonColor
    $box6.Location = New-Object System.Drawing.Point(100, 380)
    $box6_Label = New-Object system.Windows.Forms.Label
    $box6_Label.text = 'Button Color'
    $box6_Label.AutoSize = $true
    $box6_Label.width = 100
    $box6_Label.height = 30
    $box6_Label.location = New-Object System.Drawing.Point(1, 380)
    $box6_Label.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($TextColor)

    $box4 = New-Object System.Windows.Forms.TextBox
    $box4.AutoSize = $true
    $box4.Width = 100
    $box4.Height = 30
    $box4.Text = $jsondata.Config.LogoUrl
    $box4.Location = New-Object System.Drawing.Point(100, 410)
    $box4_Label = New-Object system.Windows.Forms.Label
    $box4_Label.text = 'Logo URL'
    $box4_Label.AutoSize = $true
    $box4_Label.width = 100
    $box4_Label.height = 30
    $box4_Label.location = New-Object System.Drawing.Point(1, 410)
    $box4_Label.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($TextColor)

    #region picture
    $PictureBox1 = New-Object system.Windows.Forms.PictureBox
    $PictureBox1.width = 200
    $PictureBox1.height = 100
    $PictureBox1.location = New-Object System.Drawing.Point(10, 430)
    $PictureBox1.imageLocation = $jsondata.Config.LogoUrl
    $PictureBox1.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::zoom
    $Form.controls.AddRange($PictureBox1)
    #endregion


    $Update_Button = New-Object system.Windows.Forms.Button
    $Update_Button | Add-Member -Name MyScriptPath -Value $MyScriptPath -MemberType NoteProperty
    $Update_Button.text = 'update'
    $Update_Button.width = 200
    $Update_Button.height = 30
    $Update_Button.BackColor = [System.Drawing.ColorTranslator]::FromHtml($ButtonColor)
    $Update_Button.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($TextColor)
    $Update_Button.location = New-Object System.Drawing.Point(10, 60)
    $Update_Button.Font = New-Object System.Drawing.Font('Tahoma', 10)
    $Update_Button.add_click( {
            $Form.BackColor = [System.Drawing.ColorTranslator]::FromHtml($box1.Text)
            $Panel.BackColor = [System.Drawing.ColorTranslator]::FromHtml($box2.Text)
            $label.ForeColor = $box3.Text
            $PictureBox1.imageLocation = $box4.Text
            $Update_Button.BackColor = [System.Drawing.ColorTranslator]::FromHtml($box6.Text)
            $Set_Button.BackColor = [System.Drawing.ColorTranslator]::FromHtml($box6.Text)
            $Update_Button.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($box5.Text)
            $Set_Button.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($box5.Text)
            $box1_Label.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($box5.Text)
            $box2_Label.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($box5.Text)
            $box3_Label.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($box5.Text)
            $box4_Label.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($box5.Text)
            $box5_Label.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($box5.Text)
            $box6_Label.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($box5.Text)
            $Form.Refresh()
        })
    $Update_Button.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard

    $Set_Button = New-Object system.Windows.Forms.Button
    $Set_Button | Add-Member -Name MyScriptPath -Value $MyScriptPath -MemberType NoteProperty
    $Set_Button.text = 'Set'
    $Set_Button.width = 200
    $Set_Button.height = 30
    $Set_Button.BackColor = [System.Drawing.ColorTranslator]::FromHtml($ButtonColor)
    $Set_Button.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($TextColor)
    $Set_Button.location = New-Object System.Drawing.Point(10, 90)
    $Set_Button.Font = New-Object System.Drawing.Font('Tahoma', 10)
    $Set_Button.add_click( {
            $new = [psobject]@{
                Config  = [psobject] @{
                    Color1st    = $($box1.Text)
                    Color2nd    = $($box2.Text)
                    LabelColor  = $($box3.Text)
                    Description = $($jsondata.Config.Description)
                    LogoUrl     = $($box4.Text)
                    TextColor   = $($box5.Text)
                    ButtonColor = $($box6.Text)
                    AppTitle    = $($jsondata.Config.AppTitle)
                }
                Buttons = $jsondata.Buttons
            }
            $new | ConvertTo-Json -Depth 10 | Set-Content $PSLauncherConfigFile -Force
            $cmd = {
                Param([int]$ID)
                $r = Get-Runspace -Id $id
                $r.close()
                $r.dispose()
            }
            Start-ThreadJob -ScriptBlock $cmd -ArgumentList $runspace.id
            $Form.Close()
        })
    $Set_Button.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard

    $Panel.controls.AddRange(@($Label))
    $Panel.Controls.Add($Update_Button)
    $panel.Controls.Add($Set_Button)

    $Form.controls.AddRange($Panel)
    $Form.controls.AddRange($box1)
    $Form.controls.AddRange($box1_Label)
    $Form.controls.AddRange($box2_Label)
    $Form.controls.AddRange($box3_Label)
    $Form.controls.AddRange($box2)
    $Form.controls.AddRange($box3)
    $Form.controls.AddRange($box4)
    $Form.controls.AddRange($box4_Label)
    $Form.controls.AddRange($box5)
    $Form.controls.AddRange($box5_Label)
    $Form.controls.AddRange($box6)
    $Form.controls.AddRange($box6_Label)

    HideConsole
    [void]$Form.ShowDialog()
} #end Function
 
Export-ModuleMember -Function Start-PSLauncherColorPicker
#endregion
 
#endregion
 
