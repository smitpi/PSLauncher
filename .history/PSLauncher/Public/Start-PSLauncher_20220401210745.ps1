
<#PSScriptInfo

.VERSION 1.1.2

.GUID 7e17bd13-6ad9-4aae-b82b-01e4402fa715

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
Created [30/09/2021_15:50] Initial Script Creating
Updated [05/10/2021_08:31] Added Color Button
Updated [24/10/2021_06:00] 'Updated module/script info'

.PRIVATEDATA

#>





<#

.DESCRIPTION
Reads the config file and launches the gui

#>

<#
.SYNOPSIS
Reads the config file and launches the gui

.DESCRIPTION
Reads the config file and launches the gui

.PARAMETER PSLauncherConfigFile
Path to the config file created by New-PSLauncherConfigFile

.EXAMPLE
Start-PSLauncher -PSLauncherConfigFile c:\temp\config.json

#>
Function Start-PSLauncher {
    [Cmdletbinding(HelpURI = 'https://smitpi.github.io/Start-PSLauncher/')]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateScript( { if ((Test-Path $_) -and ((Get-Item $_).Extension -eq '.json')) { $true}
                else {throw 'Not a valid config file.'} })]
        [System.IO.FileInfo]$PSLauncherConfigFile
    )
    $jsondata = Get-Content $PSLauncherConfigFile | ConvertFrom-Json

    $script:KeepOpen = $false
    $script:PanelDraw = 10
    $script:Color1st = $jsondata.Config.Color1st
    $script:Color2nd = $jsondata.Config.Color2nd #The darker background for the panels
    $script:LabelColor = $jsondata.Config.LabelColor
    $script:TextColor = $jsondata.Config.TextColor


    $rs = [RunspaceFactory]::CreateRunspace()
    $rs.ApartmentState = 'STA'
    $rs.ThreadOptions = 'ReuseThread'
    $rs.Open()

    $rs.SessionStateProxy.SetVariable('jsondata', $jsondata)
    $rs.SessionStateProxy.SetVariable('KeepOpen', $KeepOpen)
    $rs.SessionStateProxy.SetVariable('PanelDraw', $PanelDraw)
    $rs.SessionStateProxy.SetVariable('Color1st', $Color1st)
    $rs.SessionStateProxy.SetVariable('Color2nd', $Color2nd)
    $rs.SessionStateProxy.SetVariable('LabelColor', $LabelColor)
    $rs.SessionStateProxy.SetVariable('TextColor', $TextColor)
    $rs.SessionStateProxy.SetVariable('PSLauncherConfigFile', $PSLauncherConfigFile)
    $rs.SessionStateProxy.SetVariable('Runspace', $rs)


    $psCmd = [PowerShell]::Create().AddScript({
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

            #region functions
            function ShowConsole {
                #Clear-Host

                $PSConsole = [Console.Window]::GetConsoleWindow()
                [Console.Window]::ShowWindow($PSConsole, 5)
            }
            function HideConsole {
                if (!$KeepOpen) {
                    $PSConsole = [Console.Window]::GetConsoleWindow()
                    [Console.Window]::ShowWindow($PSConsole, 0)
                }
            }
            Function Invoke-Action {
                Param(
                    [string]$name ,
                    [string]$command ,
                    [string]$arguments ,
                    [ValidateSet('PSFile', 'PSCommand', 'Other')]
                    [string]$mode,
                    [string[]]$options
                )

                Write-Verbose "Invoke-Action -name $name -command $command -arguments $arguments -mode $mode -options $options"

                [hashtable]$processArguments = @{
                    'PassThru'    = $true
                    'FilePath'    = $command
                    'NoNewWindow' = $true
                    'Wait'        = $true
                }
                if ($mode -eq 'PSFile') { $arguments = "-NoLogo  -NoProfile -ExecutionPolicy Bypass -File `"$arguments`"" }
                if ($mode -eq 'PSCommand') { $arguments = "-NoLogo -NoProfile -ExecutionPolicy Bypass -command `"& {$arguments}`"" }

                if ( ! [string]::IsNullOrEmpty( $arguments ) ) {
                    $processArguments.Add( 'ArgumentList' , [Environment]::ExpandEnvironmentVariables( $arguments ) )
                }

                if ( $options -contains 'Hide' ) {
                    $processArguments.Add( 'WindowStyle' , 'Hidden' )
                    $processArguments.Remove('NoNewWindow')
                    $processArguments.Remove('Wait')
                }
                if ( $options -contains 'Minimized' ) {
                    $processArguments.Add( 'WindowStyle' , 'Minimized' )
                    $processArguments.Remove('NoNewWindow')
                    $processArguments.Remove('Wait')
                }
                if ( $options -contains 'NewProcess' ) {
                    $processArguments.Add( 'WindowStyle' , 'Normal' )
                    $processArguments.Remove('NoNewWindow')
                    $processArguments.Remove('Wait')
                }
                if ( $options -contains 'AsAdmin' ) {
                    $processArguments.Remove('NoNewWindow')
                    $processArguments.Remove('Wait')
                    $processArguments.Add( 'Verb' , 'RunAs' )
                }

                $process = $null
                ShowConsole
                Write-Output $processArguments
                #Clear-Host
                Write-Color 'Running the following:' -Color DarkYellow -ShowTime
                Write-Color 'Command: ', $command -Color Cyan, Green -ShowTime
                Write-Color 'Arguments: ', $arguments -Color Cyan, Green -ShowTime
                Write-Color 'Mode: ', $Mode -Color Cyan, Green -ShowTime
                Write-Color 'Options: ', $Options -Color Cyan, Green -ShowTime -LinesAfter 2
                $process = Start-Process @processArguments
                Write-Color 'Process Completed' -ShowTime -Color DarkYellow

                if ( ! $process ) {
                    [void][Windows.MessageBox]::Show( "Failed to run $($processArguments.FilePath)" , 'Action Error' , 'Ok' , 'Exclamation' )
                } else {
                    Write-Verbose -Message "$(Get-Date -Format G): pid $($process.Id) - $($process.Name) `"$($processArguments[ 'ArgumentList'] )`""

                    if ( $options -contains 'Wait' ) {
                        $process.WaitForExit()
                        Write-Verbose -Message "$(Get-Date -Format G -Date $process.ExitTime): pid $($process.Id) - $($process.Name) exited with status $($process.ExitCode)"
                    }
                }
                HideConsole
            }
            function NButton {
                param(
                    [string]$Text = 'Placeholder Text',
                    [scriptblock]$clickAction,
                    [System.Windows.Forms.Panel]$panel
                )
                $Button = New-Object system.Windows.Forms.Button
                $Button | Add-Member -Name MyScriptPath -Value $MyScriptPath -MemberType NoteProperty
                $Button.text = $text
                $Button.width = 200
                $Button.height = 30
                $Button.BackColor = [System.Drawing.ColorTranslator]::FromHtml($Color1st)
                $Button.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($TextColor)
                $Button.location = New-Object System.Drawing.Point(10, $panel.ButtonDraw)
                $Button.Font = New-Object System.Drawing.Font('Tahoma', 10)
                $button.add_click( $clickAction )
                $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard

                $panel.ButtonDraw = $panel.ButtonDraw + 30
                $Panel.controls.AddRange($button)
            }
            function NPanel {
                param(
                    [string]$LabelText = 'Placeholder Text'
                )


                $Panel = New-Object system.Windows.Forms.Panel
                $Panel.height = 490
                $Panel.width = 220
                $Panel.location = New-Object System.Drawing.Point($PanelDraw, 10)
                $Panel.BorderStyle = 'Fixed3D'
                $Panel.BackColor = [System.Drawing.ColorTranslator]::FromHtml($Color2nd)
                $panel.AutoScroll = $true
                $panel.AutoSizeMode = 'GrowAndShrink'

                $Label = New-Object system.Windows.Forms.Label
                $Label.text = $LabelText
                $Label.AutoSize = $true
                $Label.width = 230
                $Label.height = 30
                $Label.location = New-Object System.Drawing.Point(10, 10)
                $Label.Font = [System.Drawing.Font]::new('Tahoma', 24, [System.Drawing.FontStyle]::Bold)
                $Label.TextAlign = 'MiddleCenter'
                $label.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($LabelColor)

                $Panel | Add-Member -Name ButtonDraw -Value 70 -MemberType NoteProperty
                $Panel.controls.AddRange(@($Label))
                $Form.controls.AddRange($Panel)

                $Panel
                $script:PanelDraw = $script:PanelDraw + 220

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
                Write-Color '1: ', 'PowerShell File' -Color Yellow, Green
                Write-Color '2: ', 'Powershell Command' -Color Yellow, Green
                Write-Color '3: ', 'Other' -Color Yellow, Green
                $selection = Read-Host 'Please make a selection'
                switch ($selection) {
                    '1' { 'PSFile' }
                    '2' { 'PSCommand' }
                    '3' { 'Other' }
                }
            }
            function AddToConfig {
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
            }
            function EnableLogging {
                $script:KeepOpen = $true
                ShowConsole
                $script:guilogpath = "$env:TEMP\Utilgui-" + (Get-Date -Format yyyy.MM.dd-HH.mm) + '.log'
                Write-Output "creating log $guilogpath"
                Start-Transcript -Path $guilogpath -IncludeInvocationHeader -Force -NoClobber -Verbose
            }
            function DisableLogging {
                Stop-Transcript
                notepad $guilogpath
                $script:KeepOpen = $false
                HideConsole
            }
            #endregion

            #region GUI Icon
            $iconBase64 = 'AAABAAEAXmwAAAEAIADYowAAFgAAACgAAABeAAAA2AAAAAEAIAAAAAAAoJ4AAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAFBpAgDC/wEAwv8BAML/AQDB/wEAwf8AAMH/AADB/wAAwf8AAMH/AADB/wAAwf8AAMH/AADC/wAAwv8AAMH/AADB/wAAwf8AAMH/AADN/wAAvv8rAMH/YQDB/6EAwf+yAMH/yADA/9kAwf/0AMH//ADB//oAwf/vAMD/1QDA/8QAwP+5AL//iQC//1QAyv8gALn/AADB/wAAwP8AAMH/AADB/wAAwf8AAMD/AADA/wAAwP8AAMD/AADA/wAAwP8AAMD/AADA/wAAwP8AAMD/AQDB/wEAwf8BAML/AQAwPwIAAQIBAAICAQABAgEwIwUBMCMFATAjBQEwIwUBMCMFATAjBQEwIwUBMCMEATAiAwEwIQIBMCEBATAhAQEDAgABAQEAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAKDUDAMT/AQDC/wEAwf8BAMH/AQDC/wAAwf8AAMH/AADB/wAAwf8AAMH/AADC/wAAwf8AAMH/AADB/wAAwf8AAMD/AADP/wAAv/9zAMH/4ADB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf/+AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMD/xgDD/1kAwv8AAMD/AADB/wAAwP8AAMD/AADA/wAAwP8AAMD/AADA/wAAwP8AAMD/AADA/wAAwf8AAML/AQDE/wEAxv8BAMj/AQQIBwEPEQgCMCQFATAjBQEwIwUBMCMFADAjBQAwIwUAMCMFADAjBAAwIgMAMCICATAhAgEwIQEBMCABAQAAAAEAAAABAAAAAQAAAAEAAAABAQEAAQIBAAEvIwMBMCMEATAkBAEwJAQBMCQEATAjBAEwIwQBMCMEATAiAwEwIgMBMCIDATAiBAEAzP0BAMr+AQDG/wEAw/8BAMH/AADB/wAAwf8AAMH/AADB/wAAwP8AAMD/AADB/wAAwf8AAMH/AADB/wAAxf8dAMH/qQDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDA//8AwP+HAP//AgDA/wAAwP8AAMD/AADA/wAAwP8AAMD/AADA/wAAwf8AAMH/AADC/wAAxP8BAMb/AQDI/wEAyv8BLyYHATAkBQEwIwUBMCMFADAjBQAwIwUAMCMFADAjBQAwIwQAMCIDADAiAwAwIQIAMCEBATAhAQEAAAABAAAAAQAAAAEAAAABAAAAAQIBAAEFAwABMCMDATAjAwEwJAQBMCQEADAkBAAwIwQAMCMEADAjBAAwIgMAMCIDATAiBAEvJAcBAMj+AQDI/gEAxv8BAMT/AADC/wAAwf8AAMH/AADB/wAAwf8AAMH/AADB/wAAwf8AANX/BQC//5QAwf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8AwP//AMD/fADB/wAAwf8AAMH/AADB/wAAwf8AAMH/AADB/wAAwv8AAMP/AADE/wAAxv8BAMf/ASRNQwMwJAUBMCQFADAjBQAwIwUAMCMFADAjBQAwIwUAMCMEADAiBAAwIgMAMCICADAhAQEwIQEBAAAAAQAAAAEAAAABAAAAAQAAAAEBAQABMCEBATAiAgEwIwMBMCMDADAkBAAwJAQAMCMEADAjBAAwIwQAMCIDADAiAwAvIwUBLiYKAQDF/gEAxf8AAMX/AADE/wAAwv8AAMH/AADB/wAAwf8AAMH/AADB/wAAs/8IAMH/0gDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8AwP//AMH/ogDC/wAAwf8AAMD/AADB/wAAwf8AAML/AADC/wAAw/8AAMT/AADE/gEMmb4DMCQFATAkBQAwJAUAMCMFADAjBQAwIwUAMCQFADAkBQAwIwQAMCIDADAiAgAwIgIBMCICAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAATAhAQEwIQIBMCICADAjAwAwIwQAMCQEADAkBAAwIwQAMCMEADAjBAAwIwQAMCMEACFSTwMAwv4AAMP/AADD/wAAw/8AAML/AADB/wAAwf8AAMH/AADL/wwAwf/cAMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMD/qgDA/wAAwP8AAMH/AADB/wAAwv8AAML/AADC/wAAwf4AAcD8ATAlBQEwJAUAMCQFADAkBQAwJAUAMCMF2DAjBdgwJQYAMCQFADAjAwAwIwMAMCMDADAiAgEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEwIQEBMCECATAiAgAwIgMAMCMEADAjBAAwJAQAMCQFADAkBQAwIwQAMCMEADAkBQAPj68DAMH+AADC/wAAwv8AAML/AADC/wAAwf8AAML/AAC//7kAwf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8AwP//AMH/kwC//wAAwP8AAMH/AADB/wAAwf8AAMD+AADA/QAnQjQDMCQFADAkBQAwJAQALyQDLDEkBf8xJAX/LyIBTjAkBAAwIwQAMCMDADAjAwAwIwMBAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABMCECATAhAgAwIgMAMCIDADAjBAAwIwQAMCQEojAjBdkwJQYAMCQFADAkBQAwJQYAAb34AADA/QAAwf4AAML/AADC/wAAvv8AAMH/fgDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AL//SADA/wAAwf8AAMD/AADA/gAAv/0ADZe8AzAlBwAwJQYAMCQFADAkA4gxJAX/MSQF/y4kAiUwJAQAMCQEADAjBAAwIwMAMCMDAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAATAiAwEwIgMAMCIDADAiBAAwIwQALREAEzEkBf8xJAX/MCQEoDAlBgAwJQYAJUc9AwG/+wAAwP0AAMH+AADC/wAAxP8AAMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8AwP/KAMH/AADB/wAAwP4AAb/8AAK89wAvJwsAMCUHADEkBQAwIwTNMSQF/zEkBf8uJAInMCQEADAkBAAwIwQAMCMDADAjAwEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEwIgQBMCIEADAiBAAwIwQAMCMEAC8hBXAxJAX/MSQF/y8iAUAwJgcAMCYIAAqfyAEAwP0AAMH/AADB/wAAxP87AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8AvP8EAMD+AAG++wACu/YAJkc9ADAlCAAxJAUAMSMF/zEkBf8xJAX/MSUGADAkBAAwIwQAMCMDADAjAwAwIwMBAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABMCMEATAjBAAwIwQAMCMEADAjBQAwIwW4MSQF/zEkBf8xKw4AMCkMACBXVwABv/wAAMD+AADB/wAAwf+mAMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDC//8Awv//AML//wDC//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB/1UBv/sAArv1AB5eYgAvKQ0ALCUAGDEkBf8xJAX/MCME0TEkBQAwIwQAMCMEADAjAwAwIwMAMCICAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAATAkBAEwJAQAMCQEADAkBAAwJAQAMCQE5zEkBf8xJAX/MCYHAC4uFQAIp9YAAL/9AADA/wAAwP/gAMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDD//8AxP//AMT//wDF//8AxP//AMP//wDC//8Awv//AML//wDB//8Awf//AML//wDC//8Awv//AML/nQO27QAbaXQALi8XADEjBP8xJAX/MSQF/y8iAVkwIwQAMCMEADAjAwAwIwMAMCICATAiAgEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEwJAQBMCQEADAkBAAwJAQAMCQEADAkBOYxJAX/MSQF/y8qDwAdZGoAAbv5AADA/QAAwP/+AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDD//8Axf//AMn//wDW//8A2///ANP//wDI//8Axv//AMP//wDD//8Awv//AML//wDC//8Aw///AMT//wDD//8A1/+pHWBpADMWAI0yIgP/MSMD/zAkBOcwJAUAMCQEADAjBAAwIwQAMCMDADAiAwEwIgIBAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABMCQEATAkBAAwJAQAMCQEADAkBAAwJATmMSME/zEjBP8tMRkADpK2AAK09AAAwf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8Aw///AMb//wDK//85CgD/PgAA/wqgyP8A5P//AM3//wDI//8Axf//AMP//wDD//8AxP//AMX//wDI//8A0f//AOb//x1dY/czHgD/MiAA/zEhAf8uAAAKMCUHADAkBQAwJAUAMCMEADAjBAAwIwMBMCICAQABAAEAAAABAAAAAQAAAAEAAAABAAAAATAkBAEwJAQAMCQEADAkBAAwJAQAMCQE6DIiAv8yIgL/JE9JAA6RtwAAwv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AMT//wDG//8LncT/QgAA/zwBAP87AwD/KzEa/wDP//8A4P//ANr//wDW//8A0///ANb//wDc//8A4///AMT//y8pD/84DQD/NRcA/zMdAP83CgBKLiwSAC8nCQAvJggALyUGADAkBQAwJAQBMCMEAQIEAwEBAQEBAAAAAQAAAAEAAAABAAAAAQAAAAEwJAUBMCQFADAkBQAwJAUAMCQFADAiA5wyIQD/Mx8A/xlygQAA0P/kAML//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDD//8Axf//ANz//x9aXP88AQD/OgUA/zoHAP85CQD/JUY9/xhygf8Josz/BLLn/w6Rsf8XdYX/KjUi/zoHAP85CgD/OAwA/zoIAP8Ve5G9Gm56ABd1hwAWeYwAFX2TABKFoAEPjq4CCaTRAwG++gEAv/wBAAEBAQAAAAEAAAABAAAAAQAAAAEBo9YDLyUIAS8lCAAvJQgAMCUHADAkBgAwIARwMiAA/zQbAP8VepG6ANT//wDE//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AMT//wDH//8A3v//D5Cv/zoFAP86BgD/OggA/zoHAP86BgD/OwUA/zoGAP86CQD/OA8A/zcQAP84DQD/OggA/zYQAP8Awf//ANj//wDc/2MDuPAAAb77AAG//AAAwP4AAMD+AADA/gEAwP0BAMD+AQBKYwMAAAABAAAAAQAAAAEAHSYDAMH/AS4pDgEuKA0ALycMAC8nDAAvJwsAK0IzADIhAP82FAD/JEpC/wDg//8Axv//AMP//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDC//8AxP//AMj//wDW//8A2P//GHJ//zoFAP87BAD/OwUA/zoGAP85CwD/NhQA/zYVAP83EQD/NRUA/xOAmv8A5v//AM7//wDG//8Awv//AMD/HwG//AAAwP4AAMH+AADB/wAAwf8AAMD/AQDA/wEAwP8BAAAAAQAAAAEAAAABAMD/AQDB/wEHp9YDD5GzAxV9kwMbanQBIVZVACZGOwAzGwD/NhIA/zgMAP8A4P//AMr//wDF//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AML//wDE//8Axf//AMz//wDa//8A4v//AMD9/xV8kf8WeIv/EYei/zgPAP82FQD/Mh4A/wD6//8A3///AMf//wDG//8Aw///AML//wDB//8Awf4AAMH/AADB/wAAwf8AAMH/AADA/wAAwP8BAMD/AQCLtwMAAAABAEddAgDA/wEAwP8BAMD+AAG//AABvfgAA7jwAAudxQAzFgAAFniK/zgMAP85CgD/IlFN/wDf//8AyP//AMT//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDC//8Awv//AML//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AMP//wDE//8Axf//AMf//wDL//8A1///AN///wDq//86CAD/OA0A/yo1If8A4v//AMf//wDF//8Aw///AML//wDB//8Awf//AMH//wDB/wAAwf8AAMD/AADA/wAAwP8AAMH/AADB/wEAw/8BABcdAgDB/wEAwP8BAMD/AQDA/wAAwP4AAMD9AAG++gACu/UAAND//ADX//85CAD/OgcA/zsEAP8AxP//ANf//wDG//8Aw///AML//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AML//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDC//8Axf//AMX//wDE//8Aw///AML//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8Awv//AMP//wDE//8Axf//AMj//wDW//8Esub/OgYA/zoJAP8rMRr/AN7//wDF//8Aw///AML//wDB//8Awf//AMH//wDB//8Aw/+aAMH/AADA/wAAwP8AAMH/AADB/wAAw/8BAMX/AQDI/wEAwf8BAMH/AQDB/wAAwf8AAMH/AADB/gAAwP0AAMT/bADE//8A1f//D5Gw/zsFAP86BwD/NxAA/wDa//8A0///AMb//wDD//8Awv//AML//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8Awv//AMP//wDD//8Aw///AML//wDC//8Awf//AMH//wDB//8Awf//AMH//wDC//8Awv//AML//wDC//8Awv//AMH//wDB//8Awf//AML//wDD//8Ax///AM3//wDT//8Ayv//AMf//wDD//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8Aw///AMT//wDG//8A2P//EoSd/zsGAP87BQD/E4GY/wDX//8AxP//AMP//wDB//8Awf//AMH//wDB//8Awf//AMD//wC2/wUAwf8AAMH/AADB/wAAwv8AAMT/AADG/wEAyP8BAMH/AQDB/wAAwf8AAMH/AADB/wAAwf8AAMH+AADC//8AxP//AMr//wDg//8nPzP/OwUA/zoIAP8yIAL/ANr//wDV//8Ax///AMT//wDD//8Awv//AML//wDC//8Awv//AML//wDC//8Awv//AML//wDC//8AxP//AMX//wDF//8Axf//AMX//wDF//8Aw///AML//wDB//8Awf//AMH//wDC//8Aw///AMT//wDF//8Axf//AMP//wDC//8Awf//AMH//wDC//8Axf//AM///xSAlv8xHgD/Arjx/wDP//8Ax///AMP//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMP//wDF//8Ayf//AOf//yk3Jf87BgD/OwMA/wC/+/8Ay///AMT//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH/AADB/wAAwv8AAMP/AADE/wAAxv8BAMf/AQDB/wEAwf8AAMH/AADB/wAAwf8AAMH/AADB/6kAwf//AMP//wDF//8Ay///ANf//zAiBP86BgD/OgcA/zAlCP8Awv//AN3//wDI//8Axf//AMX//wDE//8Aw///AMP//wDC//8Aw///AMP//wDD//8Axv//AMf//wDO//8A2v//AMT//wDC//8Ayf//AMX//wDC//8Awv//AMH//wDC//8Aw///AMX//wDI//8AzP//AMj//wDG//8Aw///AML//wDC//8Awv//AMX//wDZ//9GAAD/PQAA/zoIAP8A1v//AMv//wDF//8Aw///AML//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AML//wDE//8AyP//ANr//xOCmv86BgD/OwYA/zAiBP8A3v//AMf//wDD//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDD/1EAwP8AAML/AADD/wAAxP8AAMX/AADG/wEAwf8AAMH/AADB/wAAwf8AAMH/AADB/wAAwf//AMH//wDC//8Aw///AMf//wDP//8AzP//LyUI/zsGAP86BgD/OgYA/w2Utf8A5///ANX//wDL//8Ax///AMX//wDE//8AxP//AMX//wDG//8AyP//AND//wDa//8AzP//IlBM/0EAAP9CAAD/AMP//wDG//8Aw///AML//wDB//8Awv//AMT//wDJ//8Hqtr/Hl9i/wqgyv8Azf//AMX//wDC//8Awv//AML//wDE//8A2P//I0tE/zsDAP87BAD/HGNp/wDi//8AyP//AMX//wDD//8Awv//AML//wDC//8Awv//AML//wDC//8Awv//AML//wDE//8Ax///ANP//wDR//86CAD/OgcA/zsFAP8FseX/ANX//wDE//8Awv//AML//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8AwP//AL7/AADB/wAAw/8AAMP/AADE/wAAxf8BAMH/AADB/wAAwf8AAMH/AADB/wAAwf/bAMH//wDB//8Awf//AML//wDD//8AyP//AM///wDY//8tLRT/OwQA/zoHAP87BAD/OAwA/w2Utv8AzP//AOT//wDh//8A3v//AN3//wDg//8A5P//AOf//wDR//8hUk//PAEA/zsEAP86BwD/QgAA/wuexv8Ax///AMP//wDC//8Awf//AML//wDE//8A2P//KzMd/0EAAP87BAD/AN7//wDF//8Awv//AML//wDC//8AxP//AM3//wDY//87BAD/OwQA/zsDAP8Nlbf/AOL//wDJ//8Axf//AMT//wDD//8Aw///AML//wDC//8Aw///AMT//wDF//8Ayf//ANf//wDc//8wJQn/OggA/zoIAP8tLBL/AN7//wDI//8Aw///AML//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB/4MAv/8AAML/AADD/wAAxP8AAMT/AADB/wAAwf8AAMH/AADB/wAAwf8BAMH//wDB//8Awf//AMH//wDB//8Awv//AMP//wDH//8Azv//AOP//x5dYf89AAD/OwQA/zoIAP87BQD/PAIA/y4qEf8sLxj/FnaH/xd2h/8nPi//KDop/z4AAP88AgD/OwUA/zoGAP87AwD/NwwA/xGJpv8A1f//AMX//wDD//8Awv//AML//wDD//8Axf//AN///ysyHP87BQD/QAAA/wDm//8Axf//AMP//wDC//8Awv//AMP//wDF//8A1v//CqDI/zwCAP87AwD/OwMA/xdzgv8A6P//ANP//wDJ//8Axv//AMT//wDE//8AxP//AMX//wDH//8Ay///AOD//wSz5/86BwD/OQkA/zkKAP8vJgr/ANj//wDL//8Axf//AML//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8AwP//AL7/AADB/wAAwv8AAMP/AADD/wAAwf8AAMH/AADB/wAAwf8AAMH/zQDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8Aw///AMb//wDI//8A3P//AMv//yFSUf89AAD/OwQA/zkJAP84DwD/NxAA/zgOAP86CQD/OgcA/zoHAP86BwD/OwYA/zsDAP83DgD/D5Cw/wDp//8A0v//AMf//wDD//8Awv//AMH//wDC//8Aw///AMX//wDh//8rMx7/OQoA/z4AAP8A6P//AMb//wDD//8Awv//AMH//wDC//8AxP//AMj//wDe//8eXWH/PAIA/zsFAP87BQD/KjUi/wmhy/8A6P//AOH//wDd//8A3P//AN3//wDh//8A5P//AOP//xxlbP87BQD/OgcA/zkJAP83DgD/AL/7/wDR//8Axv//AMP//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB/3gAwP8AAML/AADC/wAAwv8AAML/AADC/wAAwf8AAMH/AgDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDD//8Axf//AMf//wDO//8A2///AMr//xOCnP8iT0z/OA8A/zYUAP83EAD/OggA/zsDAP86BQD/Kjci/yJQTf8QjKv/AOf//wDT//8Ayf//AMT//wDD//8Awv//AMH//wDB//8Awv//AMP//wDF//8A4v//KjQf/zkMAP8+AAD/AOn//wDG//8Aw///AML//wDB//8Awf//AML//wDE//8Ax///AN///w6Ssv8+AAD/OgcA/zoIAP86BwD/NhUA/yVFOv8XdIX/F3SE/xd0hf8lRDn/NxEA/zsDAP86BgD/OgYA/zoGAP8xHgD/ANn//wDR//8Ax///AMP//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMD/AADB/wAAwv8AAML/AADC/wAAwv8AAMD/AADB/7kAwf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AML//wDE//8Axf//AMf//wDL//8A2f//APz//zsGAP83EgD/KTko/wDB/f8A7P//AOj//wDi//8A3f//ANL//wDI//8Axf//AMT//wDD//8Awv//AMH//wDB//8Awf//AML//wDD//8Axf//AOL//yo0IP85DAD/PwAA/wDq//8Axv//AMP//wDC//8Awf//AMH//wDC//8Aw///AMT//wDG//8A3P//AMH+/zAiA/87BgD/OA0A/zYTAP83EAD/OQsA/zoHAP86BgD/OggA/zkMAP86CAD/OgUA/zoGAP8ZcHz/AOP//wDP//8Ax///AMP//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDD/1MAwf8AAMH/AADB/wAAwv8AAML/AAC+/wAAwP//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AML//wDE//8Axv//AMj//wDq//8+AAD/OA4A/yk5KP8A6v//AMv//wDH//8Axv//AMX//wDD//8Aw///AMP//wDC//8Awv//AMH//wDB//8Awf//AMH//wDC//8Aw///AMX//wDi//8qNCD/OQwA/z8AAP8A6v//AMb//wDD//8Awv//AMH//wDB//8Awf//AML//wDD//8AxP//AMb//wDP//8A5v//Ab74/zAiA/82FQD/NxEA/zkLAP87BQD/OwMA/zwCAP89AAD/MCID/xSAmP8A2P//ANf//wDK//8Axf//AMP//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf/tAMH/AADB/wAAwf8AAML/AADB/wAAw/9GAMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8Awv//AMT//wDG//8A5v//PwAA/zkLAP8pOSf/AOn//wDI//8Axf//AMP//wDC//8Awv//AML//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AMP//wDF//8A4v//KjQg/zkMAP8/AAD/AOr//wDG//8Aw///AML//wDB//8Awf//AMH//wDC//8Awv//AML//wDD//8Axv//AMr//wDo//8pOSf/NxAA/zkMAP8Ayf//BbLl/waw4f8Grt7/ANf//wDd//8A2P//AMz//wDF//8AxP//AML//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDD/wAAwf8AAMH/AADB/wAAwf8AAMH/zQDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDD//8Axf//AOL//yo1If86BwD/OgYA/wDp//8AyP//AMT//wDC//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDD//8Axf//AOL//yo0IP85DAD/PwAA/wDq//8Axv//AMP//wDC//8Awv//AML//wDC//8Awv//AML//wDC//8Aw///AMT//wDG//8A5f//KjYi/zkMAP87AwD/APH//wDS//8Azv//AMv//wDK//8Axv//AMT//wDE//8Aw///AML//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf+FAMH/AADB/wAAwf8AAMH/AADB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AMX//wDc//8iT0v/OwUA/zsEAP8Aw///AM///wDG//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8Aw///AMX//wDi//8qNCD/OQwA/z8AAP8A6v//AMb//wDD//8Awv//AML//wDE//8AxP//AMT//wDE//8Aw///AMP//wDD//8Axf//AOP//yo1If85CwD/PgAA/wDt//8Ayv//AMf//wDF//8AxP//AMP//wDC//8Awv//AML//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMD//wC//wAAwf8AAMH/AADE/zsAwf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDD//8A0v//C57F/zsDAP87BAD/HGRr/wDc//8AyP//AMP//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AMP//wDF//8A4v//KjQg/zkMAP8/AAD/AOr//wDG//8AxP//AMP//wDE//8Ayf//ANf//wDX//8Ay///AMb//wDE//8Aw///AMX//wDi//8qNCD/OQwA/z4AAP8A6///AMf//wDE//8Aw///AML//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Av/8AAMH/AADB/wAAwf+cAMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8Aw///AMj//wDn//86BAD/OgYA/zwBAP8Azf//AM7//wDH//8Aw///AML//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDD//8Axf//AOL//yo0IP85DAD/PwAA/wDq//8Axv//AMT//wDE//8Axv//ANz//zoHAP88AAD/Ba/j/wDK//8Axf//AMT//wDF//8A4v//KjQg/zkMAP8+AAD/AOr//wDG//8Aw///AML//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMP/OgDB/wAAwP8AAMD//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AMP//wDF//8A0///FICX/zoGAP87BQD/JUQ5/wDn//8Ayf//AMb//wDD//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8Aw///AMX//wDi//8qNCD/OQwA/z8AAP8A6v//AMb//wDE//8Axf//AMn//wep1/8/AAD/PQAA/xprdv8A1P//AMX//wDE//8Axf//AOL//yo0IP85DAD/PwAA/wDq//8Axv//AMP//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB/50Awf8AAL//AADB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8AxP//AMn//wDn//85CgD/OgcA/zsFAP8cYmf/AOb//wDJ//8Ax///AMP//wDC//8Awv//AML//wDC//8Awf//AMH//wDB//8Awv//AMP//wDF//8A4v//KjQg/zkMAP8/AAD/AOr//wDG//8Axf//AMb//wDL//8GrNz/PQAA/zwBAP8Zbnv/ANj//wDE//8AxP//AMX//wDi//8qNCD/OQwA/z8AAP8A6v//AMb//wDD//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH/AADa/wAAwf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AMP//wDG//8Az///AML//zkHAP86BQD/OwQA/xd0g/8A5v//AM7//wDH//8Axf//AMP//wDD//8Aw///AML//wDC//8Awf//AML//wDD//8Axf//AOL//yo0IP85DAD/PwAA/wDq//8Axv//AMT//wDH//8AzP//Bq3e/zwAAP88AwD/GHB+/wDZ//8AxP//AMT//wDF//8A4v//KjQg/zkMAP8/AAD/AOr//wDG//8Aw///AML//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMD//wC//wAAxP8uAMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8Aw///AMb//wDb//8Pj63/OwMA/zsFAP87BQD/JkM4/wDN//8A2///AM///wDH//8Axv//AMX//wDE//8Aw///AML//wDC//8Aw///AMX//wDi//8qNCD/OQwA/z8AAP8A6v//AMb//wDE//8Ax///AMz//wau3/88AQD/OwMA/xhxgP8A2f//AMT//wDE//8Axf//AOL//yo0IP85DAD/PwAA/wDq//8Axv//AMP//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Axf8AAMH/YQDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDE//8Axv//ANz//w+Prf85BwD/OggA/zoHAP86BwD/F3WF/wDC//8A5v//AOL//wDd//8A0v//AMf//wDE//8Aw///AMP//wDF//8A4v//KjQg/zkMAP8/AAD/AOr//wDG//8AxP//AMf//wDM//8GruD/PAEA/zsDAP8YcYD/ANn//wDE//8AxP//AMX//wDi//8qNCD/OQwA/z8AAP8A6v//AMb//wDD//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AND/DwDB/5YAwf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8Awv//AMT//wDG//8A2v//AMH//zgKAP86BwD/OgYA/zsFAP87BAD/NxEA/yk4Jf8oOyr/FneJ/wDJ//8Ax///AMT//wDE//8Axf//AOL//yo0IP85DAD/PwAA/wDq//8Axv//AMT//wDH//8AzP//Bq7g/zwBAP87AwD/GHGA/wDZ//8AxP//AMT//wDF//8A4v//KjQg/zkMAP8/AAD/AOr//wDG//8Aw///AML//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDD/0UAwf/FAMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDC//8AxP//AMb//wDT//8A1f//GHJ//zoFAP87BAD/OggA/zgMAP85CwD/OwQA/0EAAP8Ve4//AMj//wDF//8AxP//AMX//wDi//8qNCD/OQwA/z8AAP8A6v//AMb//wDE//8Ax///AMz//wau4P88AQD/OwMA/xhxgP8A2f//AMT//wDE//8Axf//AOH//yo0H/85CwD/PwAA/wDp//8Axv//AMP//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf9zAMD/zwDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AML//wDD//8Axf//AMz//wDW//8A1v//D46t/yFSUf83DwD/PwAA/0AAAP9AAAD/Bq3e/wDH//8Axf//AMT//wDF//8A4v//KjQg/zkMAP8/AAD/AOr//wDG//8AxP//AMf//wDM//8GruD/PAEA/zsDAP8YcYD/ANn//wDE//8AxP//AMb//wDg//8rMhz/OQoA/z8AAP8A6P//AMb//wDD//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH/fwDA/9cAwf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AMP//wDE//8Axv//AMv//wDT//8A3f//AOP//wDm//8A5f//AN7//wDL//8Axf//AMT//wDD//8Axf//AOL//yo0IP85DAD/PwAA/wDq//8Axv//AMT//wDH//8AzP//Bq7g/zwBAP87AwD/GHGA/wDZ//8AxP//AMT//wDF//8A3f//LDAY/zsFAP9BAAD/AOT//wDF//8Aw///AML//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB/5MAwP/pAMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8Awv//AMP//wDE//8AxP//AMX//wDF//8Axf//AMX//wDF//8Axf//AMP//wDD//8Aw///AMX//wDi//8qNCD/OQwA/z8AAP8A6v//AMb//wDE//8Ax///AMz//wau4P88AQD/OwMA/xhxgP8A2f//AMT//wDD//8AxP//ANX//yJRTP9DAAD/Nw0A/wDb//8AxP//AMP//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf+mAMD/+ADB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8Awv//AMP//wDD//8Aw///AMP//wDD//8Aw///AML//wDC//8Awv//AMP//wDF//8A4v//KjQg/zkMAP8/AAD/AOr//wDG//8AxP//AMf//wDM//8GruD/PAEA/zsDAP8YcYD/ANn//wDE//8Aw///AMT//wDH//8A2f//Bqzd/wDd//8Ayf//AMT//wDD//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH/rQDA//gAwf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AML//wDD//8Aw///AMP//wDD//8Aw///AML//wDC//8Awv//AML//wDD//8Axf//AOL//yo0IP85DAD/PwAA/wDq//8Axv//AMT//wDH//8AzP//Bq7g/zwBAP87AwD/GHGA/wDZ//8AxP//AMP//wDD//8AxP//AMb//wDH//8Ax///AMb//wDE//8Aw///AMP//wDC//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB/6YAwP/pAMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AMP//wDF//8Axf//AMX//wDE//8AxP//AMT//wDE//8Aw///AML//wDC//8Aw///AMX//wDi//8qNCD/OQwA/z8AAP8A6v//AMb//wDE//8Ax///AMz//wau4P88AQD/OwMA/xhxgP8A2f//AMT//wDD//8Aw///AMT//wDF//8Axv//AMf//wDG//8Axv//AMX//wDF//8AxP//AMP//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf+dAMD/1wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AMP//wDG//8Azv//AN3//wDh//8A3f//ANf//wDL//8Ax///AMb//wDE//8AxP//AMT//wDG//8A4v//KjQg/zkMAP8/AAD/AOr//wDG//8AxP//AMf//wDM//8GruD/PAEA/zsDAP8YcYD/ANn//wDF//8AxP//AMX//wDF//8Axv//AMn//wDM//8A2f//AOD//wDh//8A2v//AMr//wDF//8Aw///AML//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH/kwDA/88Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDE//8Ayv//CqHL/z4AAP88AAD/JkM3/xOBmP8Awf//AOb//wDf//8A0///AMn//wDH//8AyP//AOH//yo0IP85DAD/PwAA/wDq//8Axv//AMT//wDH//8AzP//Bq7g/zwBAP87AwD/GHGA/wDZ//8Ax///AMf//wDJ//8A1///AOL//wDo//8Gr+D/GHGA/yozHv9BAAD/QAAA/wDM//8AyP//AMT//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB/4EAwf/FAMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8AxP//ANX//xlseP88AgD/OA8A/zkLAP86BwD/OwQA/zsEAP8mQTT/FnmM/wDM//8Ay///AMr//wDh//8qNCD/OQwA/z8AAP8A6v//AMb//wDE//8Ax///AMz//wau4P88AQD/OwMA/xhxgP8A2f//AMn//wDN//8AyP//GW14/yszHf8+AAD/PAIA/zoJAP84DQD/OA8A/z4AAP8Hqtr/AMr//wDF//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv9xAMH/lgDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AMT//wDY//8Zb3z/OQoA/zgPAP85DAD/OQkA/zoIAP85CQD/OwUA/0EAAP8oPS//ANH//wDM//8A4f//KjQg/zkMAP8+AAD/AOn//wDG//8AxP//AMf//wDM//8GruD/PAEA/zsDAP8YcYD/ANn//wDK//8A2P//PwAA/z4AAP87BQD/OgcA/zsFAP86CQD/OA0A/zcRAP87BAD/Bq3d/wDM//8Axv//AML//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMP/RgDB/2IAwf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDE//8A2f//GHF//zoJAP85CgD/Bqva/wqhy/8hVFT/Nw8A/z8AAP9BAAD/Hl5i/wDQ//8AzP//AOD//yszHv85CwD/PwAA/wDp//8Axv//AMT//wDH//8AzP//Bq7g/zwBAP87AwD/GHGA/wDZ//8Ayv//ANf//z4AAP8/AAD/PwAA/yo1IP8Xdob/AMP//xCKqP85CgD/OwQA/wau3/8AzP//AMb//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDP/xAAxP8wAMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8AxP//ANn//xhxgP86BgD/OwUA/wSz6P8A4///AOD//wDk//8AyP//CqLL/wDU//8Ayf//AMn//wDf//8rMBn/OwUA/z4AAP8A5///AMb//wDE//8Ax///AMz//wau4P88AQD/OwMA/xhxgP8A2f//AMj//wDN//8AzP//CaXP/wDm//8A4v//AOH//wDi//8Wdof/OgYA/zsDAP8GruD/AMz//wDG//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv8AAMn/AADB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AMT//wDZ//8YcYD/OwQA/zsDAP8FseT/ANL//wDJ//8AyP//AMj//wDI//8Axv//AMX//wDH//8A2v//LSwS/z0AAP89AAD/AOD//wDG//8AxP//AMf//wDM//8GruD/PAEA/zsDAP8YcYD/ANn//wDG//8Axv//AMf//wDI//8Ax///AMb//wDH//8A3v//F3OD/zsEAP88AgD/Bq7g/wDM//8Axv//AML//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH/AADB/wAAwf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDE//8A2f//GHGA/zsEAP88AgD/Ba/h/wDO//8Ax///AMT//wDE//8AxP//AMP//wDD//8Axf//AM7//w+Rsf82DwD/Hl9j/wDU//8AxP//AMP//wDG//8AzP//Bq7g/zwBAP87AwD/GHGA/wDZ//8Axf//AMT//wDE//8AxP//AMT//wDE//8Axf//ANv//xhygf87BAD/PAIA/wau4P8AzP//AMb//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMD/6QDB/wAAwf8AAMH/7QDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8AxP//ANn//xhxgP87AwD/PAEA/wau4P8AzP//AMb//wDD//8Awv//AML//wDC//8Awv//AMP//wDG//8AzP//ANb//wDR//8AyP//AMP//wDC//8Axv//AMz//wau4P88AQD/OwMA/xhxgP8A2f//AMT//wDD//8Awv//AML//wDC//8Aw///AMT//wDa//8YcYD/OwMA/zwBAP8GruD/AMz//wDG//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB/4QAwf8AAMH/AADB/3cAwf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AMT//wDZ//8YcYD/OwQA/zwCAP8Fr+D/AM3//wDG//8Awv//AMH//wDB//8Awf//AMH//wDC//8Aw///AMX//wDF//8Aw///AMP//wDC//8Awv//AMb//wDM//8GruD/PAEA/zsDAP8YcYD/ANn//wDE//8Awv//AML//wDB//8Awv//AML//wDE//8A2v//GHKB/zsEAP88AgD/Bq7g/wDM//8Axv//AML//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8AyP8iAMH/AADB/wAAlf8HAMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDE//8A2f//GHF//zsEAP88AgD/BbDi/wDN//8Axv//AML//wDB//8Awf//AMH//wDB//8Awf//AML//wDC//8Awv//AML//wDC//8Awv//AML//wDG//8AzP//Bq7f/zwBAP87AwD/GHF//wDZ//8AxP//AML//wDB//8Awf//AML//wDD//8AxP//ANr//xdzgv87BAD/PAIA/wau3/8AzP//AMb//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8AwP//AL7/AADC/wAAwf8AAL//AADA//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8AxP//ANj//xhwfv87BAD/OwQA/wSy5v8A1///AMb//wDD//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8Axv//AMz//wat3f89AAD/PAEA/xhvff8A2P//AMT//wDC//8Awf//AMH//wDC//8AxP//AMb//wDb//8XdYX/OwUA/zwCAP8Grd7/AMz//wDG//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH/7wDA/wAAwv8AAMH/AADA/wAAwf+2AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AMT//wDW//8Zb3z/OwQA/zsGAP8Pjaz/AN///wDI//8Axf//AMP//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AMX//wDK//8Hq9r/PQAA/z0AAP8ZbXn/ANb//wDE//8Awv//AML//wDC//8Aw///AMb//wDL//8A7P//I01I/zoGAP87AgD/B6vb/wDJ//8Axf//AML//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDD/1MAwf8AAML/AADB/wAAwf8AAMn/IADB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDF//8Az///Eoeh/zwAAP86BwD/OwUA/w6Ssv8A3///AMf//wDE//8Aw///AML//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDE//8AyP//AM3//0UAAP9FAAD/DpKy/wDK//8AxP//AML//wDC//8Aw///AMb//wDI//8A5///IlFN/zoGAP86BgD/OwIA/wDF//8Ax///AMT//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDA//8Avv8AAML/AADC/wAAwv8AAMH/AADB/wAAwf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8Aw///AMf//wDf//8iTkv/OwUA/zsGAP87AwD/DpKy/wDf//8Axv//AMT//wDD//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8Awv//AMb//wDK//8Awv//AML//wDP//8Ax///AMP//wDD//8Aw///AMb//wDI//8A5///IlFN/zsFAP86BgD/OgYA/wDB//8A0f//AMT//wDD//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf+1AMD/AADC/wAAwv8AAMH/AADB/wAAwf8AAMH/hQDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDF//8AyP//AOX//yJQTv87BQD/OwUA/zsDAP8OkrL/AN///wDG//8AxP//AMP//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDD//8Axf//AMX//wDF//8AxP//AMP//wDD//8AxP//AMb//wDI//8A5///IlFN/zsEAP86BQD/OgYA/wDB//8A2P//AMb//wDD//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMn/IQDB/wAAwv8AAML/AADB/wAAwf8AAMH/AADA/wAAwP//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8Aw///AMX//wDI//8A5v//IlFP/zsFAP87BQD/OwMA/w6Ssv8A3///AMb//wDE//8Aw///AML//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AML//wDD//8Aw///AMP//wDD//8AxP//AMb//wDI//8A5///IlBN/zsEAP86BQD/OgYA/wDB//8A2f//AMT//wDD//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMD//wDB/wAAwv8AAML/AADC/wAAwf8AAMH/AADB/wAAwP8AAMH/uADB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDD//8Axv//AMj//wDn//8iUU//OwUA/zsFAP87AwD/DpKy/wDf//8Axv//AMT//wDC//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AML//wDC//8Aw///AMb//wDI//8A5v//IlBN/zsEAP86BQD/OgYA/wDB//8A2f//AMT//wDD//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDD/1IAwf8AAML/AADC/wAAw/8AAMH/AADB/wAAwf8AAMH/AADB/wAAwf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AMP//wDG//8AyP//AOf//yJRT/87BQD/OwUA/zsDAP8OkrL/AN7//wDG//8AxP//AML//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8Aw///AMX//wDI//8A5v//IlFN/zsEAP86BQD/OgYA/wDB//8A2f//AMT//wDD//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Avv8AAML/AADD/wAAw/8AAMT/AADB/wAAwf8AAMH/AADB/wAAwf8AAMH/zgDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8Aw///AMb//wDI//8A5///IlFP/zsGAP86BwD/PQAA/w6Ss/8A2///AMb//wDD//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AMT//wDJ//8A4///IVJP/zsFAP86BgD/OgYA/wDB//8A2f//AMT//wDD//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf95AMD/AADD/wAAxP8AAMX/AADG/wAAwf8AAMH/AADB/wAAwf8AAMH/AACm/wkAwP//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDD//8Axv//AMj//wDn//8hUlD/OwYA/zkJAP89AAD/DZe7/wDQ//8Axf//AML//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDE//8A2v//H1hY/zsEAP85CAD/OQgA/wDC//8A2P//AMT//wDD//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AL7/AADB/wAAw/8AAMX/AADG/wAAyP8BAMD/AQDA/wAAwf8AAMH/AADB/wAAwP8AAMH/nQDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AMP//wDG//8Ayf//AOr//yBVVf86BwD/OwYA/yk5J/8A2///AMX//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDD//8Axf//AOP//0AAAP85CwD/Nw0A/wDF//8A1///AMX//wDD//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMT/OADA/wAAwv8AAMP/AADF/wAAx/8AAMn/AQDA/wEAwf8AAMH/AADB/wAAwv8AAMH/AAC+/wAAwf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8Aw///AMf//wDM//8A8f//OwQA/zoJAP8qNSH/AN///wDF//8Awv//AML//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8Aw///AMX//wDo//8/AAD/OA0A/yk5J/8A5///AMn//wDE//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH/0AC//wAAwv8AAML/AADE/wAAxf8AAMj/AQDK/wEAwP8BAML/AQDC/wAAw/8AAML/AADC/wAAwP8AAMT/OADB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDE//8AyP//AO3//z0AAP85CwD/KjQg/wDh//8Axf//AMP//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AMP//wDG//8A6f//PwAA/zgNAP8qNiP/AOT//wDG//8Aw///AML//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMD//wC+/wAAwP8AAML/AADC/wAAw/8AAMX/AADI/wEAy/8BAML/AQDE/wEAxf8BAMT/AADD/wAAwv8AAML/AADA/wAAwf+3AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8Aw///AMb//wDr//8+AAD/OQwA/yo0IP8A4v//AMX//wDD//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDD//8Axv//AOn//z8AAP85DAD/KjUh/wDi//8Axf//AMP//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDD/18AwP8AAMH/AADC/wAAw/8AAMP/AADF/wEAx/8BAMv/AQBFXAIAx/8BAMb/AQDE/wAAw/8AAML/AADB/wAAwf8AAMD/AADB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AMP//wDG//8A6v//PgAA/zkMAP8qNCD/AOL//wDF//8Aw///AML//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8Aw///AMb//wDq//8/AAD/OQwA/yo0IP8A4v//AMX//wDD//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wC//8YAwf8AAMH/AADB/wAAwv8AAMP/AADD/wAAxP8BAMb/AQAKDAEAAQIBAMn/AQDG/wEAxP8BAMP/AADC/wAAwf8AAMH/AADB/wAAvP8DAMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDD//8Axv//AOr//z8AAP85DAD/KjQg/wDi//8Axf//AMP//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AMP//wDG//8A6v//PwAA/zkMAP8qNCD/AOL//wDF//8Aw///AML//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf8AAMH/AADB/wAAwf8AAML/AADD/wAAw/8BAMT/AQB0mQMABAUBAAICAQAFBwEAxf8BAMT/AQDC/wEAwv8AAMH/AADB/wAAwP8AAMH/AADB/5gAwf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8Aw///AMb//wDq//8/AAD/OQwA/yo0IP8A4v//AMX//wDD//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDD//8Axv//AOr//z8AAP85DAD/KjQg/wDi//8Axf//AMP//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDA//8AxP82AMH/AADB/wAAwf8AAMH/AADB/wAAwv8BAMP/AQDE/wEAAQEBAAEBAQABAQEAAgMBAHSZAwDD/wEAwv8BAML/AADB/wAAwf8AAMH/AADB/wAAwP8AAMH/qADB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AMP//wDG//8A6v//PwAA/zkMAP8qNCD/AOL//wDF//8Aw///AML//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8Aw///AMb//wDq//8/AAD/OQwA/yo0IP8A4v//AMX//wDD//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Aw/9EAMH/AADB/wAAwf8AAMH/AADB/wAAwf8AAMH/AQDC/wEAKDMDAAAAAQAAAAEAAAABAAEBAQABAgEAw/8BAML/AQDB/wEAwf8AAMH/AADB/wAAwf8AAML/AAC//wAAwP/AAMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDD//8Axv//AOr//z8AAP85DAD/KjQg/wDi//8Axf//AMP//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AMP//wDG//8A6v//PwAA/zkMAP8qNCD/AOL//wDF//8Aw///AML//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv9VAMH/AADB/wAAwf8AAMH/AADB/wAAwf8AAMH/AQDB/wEAl8YDAAAAAQAAAAEAAAABAAAAAQAAAAEAAQIBAAQFAQDC/wEAwf8BAML/AQDC/wAAw/8AAMP/AADC/wAAwv8AAL3/AADA/9IAwf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8Aw///AMb//wDq//8/AAD/OQwA/yo0IP8A4v//AMX//wDD//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDD//8Axv//AOr//z8AAP85DAD/KjQg/wDi//8Axf//AMP//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf+EAMH/AADB/wAAwf8AAMH/AADB/wAAwf8AAMH/AQDB/wEAwP8BAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAEBAQACAgEATGUDAMP/AQDE/wEAxf8AAMX/AADF/wAAxP8AAMP/AADC/wAAwP8AAMD/2ADB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AMP//wDG//8A6v//PwAA/zkMAP8qNCD/AOL//wDF//8Aw///AML//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8Aw///AMb//wDq//8/AAD/OQwA/yo0IP8A4v//AMX//wDD//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8AwP+CAMH/AADB/wAAwf8AAMH/AADB/wAAwf8AAML/AQDB/wEAwf8BABcfAwAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQDF/wEAyP8BAMr/AQDK/wAAyP8AAMb/AADE/wAAwv8AAMH/AAC+/wAAwf+zAMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDD//8Axv//AOr//z8AAP85DAD/KjQg/wDi//8Axf//AMP//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AMP//wDG//8A6v//PwAA/zkMAP8qNCD/AOL//wDF//8Aw///AML//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDA//8Av/9SAMH/AADB/wAAwf8AAMH/AADB/wAAwf8AAMH/AQDC/wEAwv8BAG2PAwAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABANH/AQDT/wEA0P8BAMv/AADH/wAAxf8AAMP/AADC/wAAwv8AAMD/AADB/4UAwf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8Aw///AMb//wDq//8/AAD/OQwA/yo0IP8A4v//AMX//wDD//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDD//8Axv//AOr//z8AAP85DAD/KjQg/wDi//8Axf//AMP//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8AyP8rAMH/AADB/wAAwf8AAMH/AADB/wAAwf8AAMH/AQDB/wEAwf8BAICoAwAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQABAQEA3f8BANP/AQDM/wEAyf8AAMb/AADE/wAAw/8AAML/AADB/wAAwf8AAMT/PADB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AMP//wDG//8A6v//PwAA/zkMAP8qNCD/AOL//wDF//8Aw///AML//wDC//8Awv//AML//wDC//8Awv//AMH//wDC//8Aw///AMb//wDq//8/AAD/OQwA/yo0IP8A4v//AMX//wDD//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8A+/8BAMH/AADB/wAAwf8AAMH/AADB/wAAwP8AAMD/AQDA/gEAwP0BAJXEAwAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAQEBAAMDAQDS/wEAzf8BAMv/AQDI/wAAxf8AAMP/AADC/wAAwf8AAMH/AADD/wAAxP8AAMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDD//8Axv//AOr//z8AAP85DAD/KjQg/wDi//8Axf//AMP//wDC//8Aw///AMT//wDE//8Aw///AMP//wDC//8Awv//AMP//wDG//8A6v//PwAA/zkMAP8qNCD/AOL//wDF//8Aw///AML//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wC//8cAwf8AAMH/AADB/wAAwf8AAMH/AADB/wAAwf8AAMD/AQDA/gEAvvwBAL36AQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAEBAQACAwEABAUBAM7/AQDO/wEAyv8BAMX/AADD/wAAwv8AAMH/AADB/wAAwf8AAML/AADD/wAAwf/MAMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8Aw///AMb//wDq//8/AAD/OQwA/yo0IP8A4v//AMX//wDD//8Aw///AMX//wDJ//8A1P//ANP//wDH//8AxP//AMP//wDE//8Axv//AOr//z8AAP85DAD/KjQg/wDi//8Axf//AMP//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMD//wDD/48Av/8AAMH/AADB/wAAwf8AAMH/AADB/wAAwf8AAMH/AQDA/wEAv/0BALz6AQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAQEBAAICAQACAgEA1f8BAMr+AQDE/gEAwv8BAMH/AADB/wAAwf8AAMH/AADB/wAAwf8AAMH/AADB/xUAwP//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awv//AMP//wDG//8A6v//PwAA/zkMAP8qNCD/AOL//wDF//8AxP//AMT//wDI//8Aw///MR0A/yg+L/8A1///AMb//wDE//8AxP//AMb//wDq//8/AAD/OQwA/yo0IP8A4v//AMX//wDD//8Awv//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMD/xwC+/wAAv/8AAMH/AADC/wAAwv8AAMH/AADB/wAAwf8AAMH/AQDB/wEAwf8BAIu5AwAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAQEAAQEBAAABAQDC+wEAwv4BAMH/AQDB/wEAwP8AAMD/AADA/wAAwf8AAMH/AADB/wAAwf8AAL//AADB/1YAwf//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf//AML//wDD//8Axv//AOr//z8AAP85DAD/KjQg/wDi//8Axf//AMT//wDE//8A1P//Gmpz/z8AAP9AAAD/BLPp/wDJ//8Axf//AMT//wDG//8A6v//PwAA/zkMAP8qNCD/AOL//wDF//8Aw///AML//wDB//8Awf//AMH//wDB//8Awf//AMH//wDB//8AwP//AML/EgDB/wAAwP8AAMH/AADC/wAAw/8AAMP/AADC/wAAwv8AAMH/AQDB/wEAwf8BAGmJAwAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAHieAwDB/wEAwP8BAMD/AQDA/wAAwP8AAMH/AADB/wAAwv8AAML/AADC/wAAv/8AAL7/AADB/30AwP//AMH//wDB//8Awf//AMH//wDB//8Awf//AMH//wDC//8Aw///AMb//wDp//8+AAD/OQwA/yo0IP8A4v//AMX//wDE//8AxP//ANf//xluev89AAD/PgAA/wau4P8Ayv//AMb//wDF//8Axv//AOr//z4AAP85DAD/KjUg/wDi//8Axf//AMP//wDC//8Awf//AMH//wDB//8Awf//AMH//wDB//8Awf9JAL7/AADA/wAAwf8AAMH/AADB/wAAwv8AAMP/AADE/wAAxP8AAMP/AQDC/wEAwf8BAD9UAwAAAQEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAMUIDAMD/AQDA/wEAwP8BAMD/AADB/wAAwv8AAMP/AADD/wAAw/8AAML/AADB/wAAv/8AAL3/AADB/3IAwf//AMH//wDB//8Awf//AMH//wDB//8Awv//AMP//wDG//8A6f//PgAA/zkMAP8qNSD/AOL//wDF//8AxP//AMT//wDZ//8Yb33/PAEA/z0AAP8Grd7/AMv//wDG//8Axf//AMb//wDq//8+AAD/OQwA/yo1If8A4f//AMX//wDD//8Awv//AMH//wDB//8Awf//AMD//wDD/z0Av/8AAMH/AADC/wAAwv8AAML/AADC/wAAwv8AAML/AADD/wAAxf8BAMb/AQDF/wEAxP8BAAYIAQACAwEAAAEBAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAqOAMAv/8BAMD/AQDB/wEAw/8BAMT/AADF/wAAxf8AAMT/AADD/wAAw/8AAML/AADC/wAAwP8AAL7/AADB/0AAwP/aAMH//wDB//8Awf//AML//wDD//8Axv//AOj//z4AAP85DAD/KjUi/wDi//8Axf//AMT//wDE//8A2P//GW98/zwBAP89AAD/Bqzc/wDL//8Axv//AMX//wDH//8A6v//PgAA/zkMAP8pNyX/AOH//wDE//8Awv//AMH//wDB//8AwP+9AMX/HgDB/wAAwf8AAML/AADD/wAAxP8AAMT/AADE/wAAw/8AAMP/AADD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AAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAS8jBAEvIwUBMCMEADAjBAAwIwQAMCMEACUAAAgxJAX/MSQF/zAkBOYxJAUAMCQFADAkBQAwIwUAMCQFADAjBAAwIwQAMCQFADEkBgAxJwoAMSQF/zEkBf8xIwX/MCQFADAjBAAwIwQAMCMEADAjBAAwIwMBMCMEAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEuIQMBLyIDATAiAwAwIgMAMCIDADAjAwAwIwQAMCQE6zEkBf8xJAX/LyIBTjEkBQAwIwQAMCMEADAjBAAwIwQAMCMEADAjBAAxIwQAMCMEzjEkBf8xJAX/MCQDizAkBQAwJAQAMCMEADAjBAAwIwQAMCMDATAiAgEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABLB8CAS8gAgEwIQIAMCICADAiAwAwIwMAMCMEACUAAAgxJAX/MSQF/zEkBf8xJAUAMCMEADAjBAAwIwQAMCMEADAjBAAxJAUALyIAODEkBf8xJAX/MCQF/zAkBQAwJAQAMCQEADAkBAAwIwQAMCMEAS8jAwECAQABAQAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQEAAAEvIAEBMCEBATAiAgAwIgIAMCMDADAjAwAxJAUALyQDgzEkBf8xJAX/MCMFtTEkBQAwIwQAMCMEADAjBAAwIwUAMSQGADEkBf8xJAX/MSQF/y4kAh8wJAUAMCQEADAkBAAwJAQAMCMEAC8jBAEuIQMBAQAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEBAQABMCABATAhAQEwIQIAMCICADAiAwAwIwMAMCQEADElBgAxJAX/MSQF/zEkBf8vIgFMMSQFADAjBAAwIwUAMSQFADAjBbMxJAX/MSQF/zAjBJ0wJAUAMCQEADAkBAAwJAQAMCQEADAjBAEuIgQBKh8DAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAgEAAQYEAAEwIQEBMCEBATAiAgAwIgMAMCMDADAjBAAwJAUALiUCGjEkBf8xJAX/MSQF/y8hAUsxJAUAMSQFADAjBbQxJAX/MSQF/zEkBf8wJAUAMCQEADAjBAAwIwQAMCQEADAkBAAwIwQBLyMEAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQEBAAEDAgABMCEBATAhAQEwIgIBMCIDADAjBAAwIwQAMCMFADEkBQAwIwW/MSQF/zEkBf8xJAX/LyAESjAkA9gxJAX/MSQF/zEkBf8vJgMkMCQEADAjBAAwIwQAMCMDADAjAwAwIwQBMCMEAS8jBAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEBAAABAgIAAQYEAAEwIQEBMCICATAjAwAwIwQAMCMEADAjBAAwIwUAMSQFAC8iAU0xJAX/MSQF/zEkBf8xJAX/MSQF/zEkBf8iAAAFMCMEADAjAwAwIwMAMCMDADAjAwAwIgMBMCMDATAjAwEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQEBAAEDAgABMCICATAiAwEwIwMBMCMEADAjBAAwIwQAMCMEADAjBAAxJAQALyIBTzEkBf8xJAX/MSQF/zAkBfcrAAAJMCMEADAiAwAwIwMAMCMDADAjAwAwIgMAMCICATAiAgEXEQIDAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEBAAABAQEAAQMCAAEwIwMBMCMEATAjBAEwIwQAMCMEADAjBAAwIwQAMCQDADEkBAArKAAGMCME/zAkBe8wJQYAMCMEADAiAwAwIgMAMCIDADAiAwAwIwMAMCMDATAiAgEwIQIBAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='
            $iconBytes = [Convert]::FromBase64String($iconBase64)
            $stream = New-Object IO.MemoryStream($iconBytes, 0, $iconBytes.Length)
            $stream.Write($iconBytes, 0, $iconBytes.Length)
            #endregion

            #region build main form
            $module = Get-Module pslauncher
            if (-not($module)){Get-Module pslauncher -ListAvailable}

            $Form = New-Object system.Windows.Forms.Form
            $Form.ClientSize = New-Object System.Drawing.Point(1050, 800)
            $Form.text = $jsondata.Config.AppTitle
            $Form.StartPosition = 'CenterScreen'
            $Form.TopMost = $false
            $Form.BackColor = [System.Drawing.ColorTranslator]::FromHtml($Color1st)
            $Form.AutoScaleDimensions = '256, 256'
            $Form.AutoScaleMode = 'Dpi'
            $Form.AutoScale = $True
            $Form.AutoSize = $True
            $Form.ClientSize = '1050, 800'
            $Form.FormBorderStyle = 'Fixed3D'
            $Form.Icon = [System.Drawing.Icon]::FromHandle((New-Object System.Drawing.Bitmap -Argument $stream).GetHIcon())
            $Form.Width = $objImage.Width
            $Form.Height = $objImage.Height
            $Form.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink
            $Form.AutoScroll = $True
            $Form.Refresh()
            #endregion

            #region create panels and buttons
            $data = $jsondata.Buttons
            $panellist = $data | Get-Member | Where-Object { $_.membertype -eq 'NoteProperty' } | Select-Object name
            $panellistSorted = $panellist | ForEach-Object { [pscustomobject]@{
                    name        = $_.Name
                    PanelNumber = $data.($_.name).config.PanelNumber
                }
            } | Sort-Object -Property PanelNumber


            foreach ($pan in $panellistSorted) {
                $panel = NPanel -LabelText $pan.name
                foreach ($but in $data.($pan.name).buttons) {
                    [scriptblock]$clickAction = [scriptblock]::Create( "Invoke-Action -control `$_ -name `"$($but.Name)`" -command `"$($but.command)`" -arguments `"$(($but|Select-Object -ExpandProperty arguments -ErrorAction SilentlyContinue) -replace '"' , '`"`"')`" -mode $($but.Mode) -options `"$(($but|Select-Object -ExpandProperty options -ErrorAction SilentlyContinue) -split ',')`"" )
                    NButton -Text $but.Name -clickAction $clickAction -panel $panel
                }
            }
            #endregion

            #region buttons
            $exit = New-Object system.Windows.Forms.Button
            $exit.text = 'Exit'
            $exit.width = 100
            $exit.height = 30
            $exit.location = New-Object System.Drawing.Point(1, 510)
            $exit.Font = New-Object System.Drawing.Font('Tahoma', 8)
            $exit.BackColor = [System.Drawing.ColorTranslator]::FromHtml($Color1st)
            $exit.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($TextColor)
            $exit.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
            $exit.Add_Click( {
                    Write-Output 'exiting Util'
                    #define a thread job to clean up the runspace
                    $cmd = {
                        Param([int]$ID)
                        $r = Get-Runspace -Id $id
                        $r.close()
                        $r.dispose()
                    }
                    Start-ThreadJob -ScriptBlock $cmd -ArgumentList $runspace.id
                    $Form.Close()
                    Stop-Process $pid
                })

            $reload = New-Object system.Windows.Forms.Button
            $reload.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
            $reload.text = 'Reload'
            $reload.width = 100
            $reload.height = 30
            $reload.location = New-Object System.Drawing.Point(100, 510)
            $reload.Font = New-Object System.Drawing.Font('Tahoma', 8)
            $reload.BackColor = [System.Drawing.ColorTranslator]::FromHtml($Color1st)
            $reload.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($TextColor)
            $reload.Add_Click( {
                    Write-Output 'Reloading Util'
                    Start-Process -FilePath 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -ArgumentList "-NoLogo -NoProfile -WindowStyle Hidden -ExecutionPolicy bypass -command ""& {Start-PSLauncher -PSLauncherConfigFile $($PSLauncherConfigFile)}"""
                    $cmd = {
                        Param([int]$ID)
                        $r = Get-Runspace -Id $id
                        $r.close()
                        $r.dispose()
                    }
                    Start-ThreadJob -ScriptBlock $cmd -ArgumentList $runspace.id
                    $Form.Close()
                    Stop-Process $pid
                })
            $EnableLogging = New-Object system.Windows.Forms.Button
            $EnableLogging.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
            $EnableLogging.text = 'Enable Logging'
            $EnableLogging.width = 100
            $EnableLogging.height = 30
            $EnableLogging.location = New-Object System.Drawing.Point(1, 540)
            $EnableLogging.Font = New-Object System.Drawing.Font('Tahoma', 8)
            $EnableLogging.BackColor = [System.Drawing.ColorTranslator]::FromHtml($Color1st)
            $EnableLogging.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($TextColor)
            $EnableLogging.Add_Click( { EnableLogging })

            $DisableLogging = New-Object system.Windows.Forms.Button
            $DisableLogging.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
            $DisableLogging.text = 'Disable Logging'
            $DisableLogging.width = 100
            $DisableLogging.height = 30
            $DisableLogging.location = New-Object System.Drawing.Point(100, 540)
            $DisableLogging.Font = New-Object System.Drawing.Font('Tahoma', 8)
            $DisableLogging.BackColor = [System.Drawing.ColorTranslator]::FromHtml($Color1st)
            $DisableLogging.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($TextColor)
            $DisableLogging.Add_Click( { DisableLogging })

            $AddToConfig = New-Object system.Windows.Forms.Button
            $AddToConfig.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
            $AddToConfig.text = 'Add Gui Config'
            $AddToConfig.width = 100
            $AddToConfig.height = 30
            $AddToConfig.location = New-Object System.Drawing.Point(1, 570)
            $AddToConfig.Font = New-Object System.Drawing.Font('Tahoma', 8)
            $AddToConfig.BackColor = [System.Drawing.ColorTranslator]::FromHtml($Color1st)
            $AddToConfig.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($TextColor)
            $AddToConfig.Add_Click( {
                    ShowConsole
                    AddToConfig
                    HideConsole
                })

            $OpenConfigButton = New-Object system.Windows.Forms.Button
            $OpenConfigButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
            $OpenConfigButton.text = 'Open Config File'
            $OpenConfigButton.width = 100
            $OpenConfigButton.height = 30
            $OpenConfigButton.location = New-Object System.Drawing.Point(100, 570)
            $OpenConfigButton.Font = New-Object System.Drawing.Font('Tahoma', 8)
            $OpenConfigButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml($Color1st)
            $OpenConfigButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($TextColor)
            $OpenConfigButton.Add_Click( {
                    if (Get-Command code -ErrorAction SilentlyContinue) {code $PSLauncherConfigFile }
                    else {notepad.exe $PSLauncherConfigFile}
                })
            $Form.controls.AddRange($exit)
            $Form.controls.AddRange($reload)
            $Form.controls.AddRange($EnableLogging)
            $Form.controls.AddRange($DisableLogging)
            $Form.controls.AddRange($AddToConfig)
            $Form.controls.AddRange($OpenConfigButton)


            #endregion
            #region picture
            $PictureBox1 = New-Object system.Windows.Forms.PictureBox
            $PictureBox1.width = 200
            $PictureBox1.height = 100
            $PictureBox1.location = New-Object System.Drawing.Point(220, 510)
            $PictureBox1.imageLocation = $jsondata.Config.LogoUrl
            $PictureBox1.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::zoom
            $Form.controls.AddRange($PictureBox1)
            #endregion


            #ShowConsole
            HideConsole
            [void]$Form.ShowDialog()

        })

    $pscmd.runspace = $rs
    [void]$pscmd.BeginInvoke()
} #end Function
