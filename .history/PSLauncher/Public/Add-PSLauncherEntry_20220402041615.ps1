
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
 Add a button or panal to the config

#>


<#
.SYNOPSIS
Add a button or panal to the config.

.DESCRIPTION
Add a button or panal to the config.

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
		$jsondata = Get-Content $PSLauncherConfigFile | ConvertFrom-Json -ErrorAction stop
	} catch {
		Add-Type -AssemblyName System.Windows.Forms
		$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ Filter = 'JSON | *.json' }
		[void]$FileBrowser.ShowDialog()
		$PSLauncherConfigFile = Get-Item $FileBrowser.FileName
		$jsondata = Get-Content $PSLauncherConfigFile | ConvertFrom-Json
	}

	
	function options {
		Write-Color -Text 'Execution Options' -Color DarkGray -LinesAfter 1
		Write-Color '1: ', 'Window Hidden' -Color Yellow, Green
		Write-Color '2: ', 'Window Minimized' -Color Yellow, Green
		Write-Color '3: ', 'Run As Admin' -Color Yellow, Green
		Write-Color '4: ', 'New Process' -Color Yellow, Green
		Write-Color '5: ', 'None' -Color Yellow, Green

		$selection = Read-Host 'Please make a selection'
		switch ($selection) {
			'1' { 'Hide' }
			'2' { 'Minimized' }
			'3' { 'AsAdmin' }
			'4' { 'NewProcess' }
			'5' { '' }
		}
	}
	function mode {
		Write-Color -Text 'Execution Mode' -Color DarkGray -LinesAfter 1
		Write-Color '1: ', 'PowerShell Script File' -Color Yellow, Green
		Write-Color '2: ', 'Powershell Command' -Color Yellow, Green
		Write-Color '3: ', 'Other Executable' -Color Yellow, Green
		$selection = Read-Host 'Please make a selection'
		switch ($selection) {
			'1' { 'PSFile' }
			'2' { 'PSCommand' }
			'3' { 'Other' }
		}
	}

	Clear-Host
	Write-Color 'Do you want to add a Button or a Panel' -Color DarkYellow -LinesAfter 1
	Write-Color '0', ': ', 'Panel' -Color Yellow, Yellow, Green
	Write-Color '1', ': ', 'Button' -Color Yellow, Yellow, Green
	Write-Color '2', ': ', 'Launch Color Picker' -Color Yellow, Yellow, Green
	Write-Output ' '
	[int]$GuiAddChoice = Read-Host 'Answer'


	if ($GuiAddChoice -eq 0) {
		$data = $jsondata.Buttons
		$NewConfig = @{}
		$panellist = $jsondata.Buttons | Get-Member | Where-Object { $_.membertype -eq 'NoteProperty' }
		foreach ($mem in $panellist) {
			$NewConfig += @{
				$mem.Name = $jsondata.Buttons.$($mem.Name)
			}
		}
		$PanelName = Read-Host 'Panel Name '
		[int]$PanelNumber = [int]($NewConfig.Values.config.PanelNumber | Sort-Object -Descending | Select-Object -First 1) + 1

		$AddPanel = @"
		{
			"Config": {
				"PanelNumber": "$($PanelNumber)"
			},
			"buttons": [
			]
		}
"@
		$NewConfig += @{$PanelName = ($AddPanel | ConvertFrom-Json) }
		$Update = @()
		$Update = [psobject]@{
			Config  = $jsondata.Config
			Buttons = $NewConfig
		}
		$Update | ConvertTo-Json -Depth 5 | Set-Content -Path $PSLauncherConfigFile -Verbose -Force

	}
	if ($GuiAddChoice -eq 1) {
		$data = $jsondata.Buttons
		$panellist = $jsondata.Buttons | Get-Member | Where-Object { $_.membertype -eq 'NoteProperty' } | Select-Object name
		$panellistSorted = $panellist | ForEach-Object { [pscustomobject]@{
				name        = $_.Name
				PanelNumber = $data.($_.name).config.PanelNumber
			}
		} | Sort-Object -Property PanelNumber
		$index = 0

		Clear-Host
		Write-Color 'Select the panel where the button will be added' -Color DarkYellow -LinesAfter 1
		foreach ($p in $panellistSorted) {
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

		
        if ($mainmenu -in $config.mainmenu) {
            $count = ($config.mainmenu | Where-Object {$_ -like $mainmenu}).count
            $config.Insert(($config.MainMenu.IndexOf("$mainmenu") + $count),[PSCustomObject]@{
                MainMenu   = $mainmenu
                Name       = $name
                Command    = $cmd.command
                Arguments  = $cmd.arguments
                Mode       = $cmd.mode
                Window     = $Window
                RunAsAdmin = $RunAs
            })
        }
        else {
            $config.Add([PSCustomObject]@{
                    MainMenu   = $mainmenu
                    Name       = $name
                    Command    = $cmd.command
                    Arguments  = $cmd.arguments
                    Mode       = $cmd.mode
                    Window     = $Window
                    RunAsAdmin = $RunAs
                })
        }



			Write-Output ' '
			$yn = Read-Host "Add another button in $($panellistSorted[$indexnum].name) (y/n)"
		}
		until ($yn.ToLower() -eq 'n')
		$jsondata | ConvertTo-Json -Depth 10 | Out-File $PSLauncherConfigFile
	}
	if ($GuiAddChoice -eq 2) {
		$module = Get-Module pslauncher
		if (![bool]$module) { $module = Get-Module pslauncher -ListAvailable }
		Start-Process -FilePath 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -ArgumentList "-NoLogo -NoProfile -WindowStyle Hidden -ExecutionPolicy bypass -command ""& {Start-PSLauncherColorPicker -PSLauncherConfigFile $($PSLauncherConfigFile)}"""
	}
	if ($Execute) {
		Start-Process -FilePath 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -ArgumentList "-NoLogo -NoProfile -WindowStyle Hidden -ExecutionPolicy bypass -command ""& {Start-PSLauncher -PSLauncherConfigFile $($PSLauncherConfigFile)}"""
	}

} #end Function
