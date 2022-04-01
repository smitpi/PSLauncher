
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

#Requires -Module ImportExcel
#Requires -Module PSWriteHTML
#Requires -Module PSWriteColor

<# 

.DESCRIPTION 
 Add a button or panal to the config 

#> 


<#
.SYNOPSIS
Add a button or panal to the config

.DESCRIPTION
Add a button or panal to the config

.EXAMPLE
Add-PSLauncherEntry

#>
Function Add-PSLauncherEntry {
		[Cmdletbinding(DefaultParameterSetName='Set1', HelpURI = "https://smitpi.github.io/PSLauncher/Add-PSLauncherEntry")]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateScript( { if ((Test-Path $_) -and ((Get-Item $_).Extension -eq '.json')) { $true}
                else {throw 'Not a valid config file.'} })]
        [System.IO.FileInfo]$PSLauncherConfigFile,
		[switch]$Execute = $false
    )

		$jsondata = Get-Content $PSLauncherConfigFile | ConvertFrom-Json

		Clear-Host
		Write-Color 'Do you want to add a Button or a Panel' -Color DarkYellow -LinesAfter 1
		Write-Color '0', ': ', 'Panel' -Color Yellow, Yellow, Green
		Write-Color '1', ': ', 'Button' -Color Yellow, Yellow, Green
		Write-Color '2', ': ', 'Launch Color Picker' -Color Yellow, Yellow, Green
		Write-Output ' '
		[int]$GuiAddChoice = Read-Host 'Decide '


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
				Write-Color 'Details of the button' -Color DarkYellow -LinesAfter 1
				$Mode = mode
				if ($Mode -like 'ps*') {
					$jsondata.Buttons.($panellistSorted[$indexnum].name).buttons += [PSCustomObject] @{
						Name      = Read-Host 'New Button Name '
						Command   = 'PowerShell.exe'
						Arguments = Read-Host '<PS Command> or <Path to ps1 file> '
						Mode      = $mode
						Options   = options
					}
				} else {
					$jsondata.Buttons.($panellistSorted[$indexnum].name).buttons += [PSCustomObject] @{
						Name      = Read-Host 'New Button Name '
						Command   = Read-Host 'Path to exe file'
						Arguments = Read-Host 'Arguments to run exe'
						Mode      = $Mode
						Options   = options
					}
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
			Import-Module $module -Force

			$itm = Get-Item $PSLauncherConfigFile
			Start-PSLauncherColorPicker -PSLauncherConfigFile $itm.FullName

		}
		if ($Execute) {
		Start-Process -FilePath 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -ArgumentList "-NoLogo -NoProfile -WindowStyle Hidden -ExecutionPolicy bypass -command ""& {Start-PSLauncher -PSLauncherConfigFile $($PSLauncherConfigFile)}"""

		}

} #end Function
