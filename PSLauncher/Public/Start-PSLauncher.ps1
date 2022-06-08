
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
Reads the config file and launches the GUI

#>

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

    try {
        $Script:jsondata = Get-Content $PSLauncherConfigFile | ConvertFrom-Json -ErrorAction stop
    } catch {
        Add-Type -AssemblyName System.Windows.Forms
        $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ Filter = 'JSON | *.json' }
        [void]$FileBrowser.ShowDialog()
        $PSLauncherConfigFile = Get-Item $FileBrowser.FileName
        $Script:jsondata = Get-Content $PSLauncherConfigFile | ConvertFrom-Json
    }

    $KeepOpen = $false
    $Script:PanelDraw = 10
    $Script:Color1st = $jsondata.Config.Color1st
    $Script:Color2nd = $jsondata.Config.Color2nd #The darker background for the panels
    $Script:LabelColor = $jsondata.Config.LabelColor
    $Script:TextColor = $jsondata.Config.TextColor


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
        Param (
            [string]$command,
            [string]$arguments,
            [string]$mode,
            [string]$Window,
            [string]$RunAsAdmin
        )
        [hashtable]$processArguments = @{
            'PassThru' = $true
            'FilePath' = $command
        }

        if ( $RunAsAdmin -like 'yes' ) { $processArguments.Add( 'Verb' , 'RunAs' )}
        if ( $Window -contains 'Hidden' ) { $processArguments.Add('WindowStyle' , 'Hidden') }
        if ( $Window -contains 'Normal' ) { $processArguments.Add('WindowStyle' , 'Normal') }
        if ( $Window -contains 'Maximized' ) { $processArguments.Add('WindowStyle' , 'Maximized') }
        if ( $Window -contains 'Minimized' ) { $processArguments.Add('WindowStyle' , 'Minimized') }

        if ($mode -eq 'PSFile') { $AddedArguments = "-NoLogo  -NoProfile -ExecutionPolicy Bypass -File `"$arguments`"" }
        if ($mode -eq 'PSCommand') { $AddedArguments = "-NoLogo -NoProfile -ExecutionPolicy Bypass -command `"& {$arguments}`"" }
        if ($mode -eq 'Other') { $AddedArguments = $arguments}

        if (-not[string]::IsNullOrEmpty( $AddedArguments)) {$processArguments.Add( 'ArgumentList' , [Environment]::ExpandEnvironmentVariables( $AddedArguments)) }

        ShowConsole
        #Clear-Host
        Write-Color 'Running the following:' -Color DarkYellow -ShowTime
        Write-Color 'Command: ', $command -Color Cyan, Green -ShowTime
        Write-Color 'Arguments: ', $arguments -Color Cyan, Green -ShowTime
        Write-Color 'Mode: ', $Mode -Color Cyan, Green -ShowTime
        Write-Color 'Window: ', $Window -Color Cyan, Green -ShowTime
        Write-Color 'RunAsAdmin: ', $RunAsAdmin -Color Cyan, Green -ShowTime -LinesAfter 2
        try {
            Start-Process @processArguments
            Write-Color 'Process Completed' -ShowTime -Color DarkYellow
        } catch {
            $Text = $This.Text
            [System.Windows.Forms.MessageBox]::Show("Failed to launch $Text`n`nMessage:$($_.Exception.Message)`nItem:$($_.Exception.ItemName)") > $null
        }
        HideConsole
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
        $Button.BackColor = [System.Drawing.ColorTranslator]::FromHtml($Script:Color1st)
        $Button.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($Script:TextColor)
        $Button.location = New-Object System.Drawing.Point(10, $panel.ButtonDraw)
        $Button.Font = New-Object System.Drawing.Font('Tahoma', 10)
        $button.add_click( $clickAction )
        $button.FlatStyle = [System.Windows.Forms.FlatStyle]::System

        $panel.ButtonDraw = $panel.ButtonDraw + 30
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
        $Label.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($Script:LabelColor)
        $Label.Refresh()

        if ($Label.PreferredWidth -lt 230) {$pwidth = 220}
        else {$pwidth = ($Label.PreferredWidth + 10)}

        $Panel = New-Object system.Windows.Forms.Panel
        $Panel.height = 490
        $Panel.width = $pwidth
        $Panel.location = New-Object System.Drawing.Point($PanelDraw, 10)
        $Panel.BorderStyle = 'Fixed3D'
        $Panel.BackColor = [System.Drawing.ColorTranslator]::FromHtml($Script:Color2nd)
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
        $script:KeepOpen = $true
        ShowConsole
        $script:GUIlogpath = "$env:TEMP\UtilGUI-" + (Get-Date -Format yyyy.MM.dd-HH.mm) + '.log'
        Write-Output "creating log $GUIlogpath"
        Start-Transcript -Path $GUIlogpath -IncludeInvocationHeader -Force -NoClobber -Verbose
    }
    function DisableLogging {
        Stop-Transcript
        notepad $GUIlogpath
        $script:KeepOpen = $false
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
    if (-not($module)) {Get-Module pslauncher -ListAvailable}

    $Form = New-Object system.Windows.Forms.Form
    $Form.ClientSize = New-Object System.Drawing.Point(1050, 800)
    $Form.text = "$($jsondata.Config.AppTitle) (ver: $($module.Version)) "
    $Form.StartPosition = 'CenterScreen'
    $Form.TopMost = $false
    $Form.BackColor = [System.Drawing.ColorTranslator]::FromHtml($Script:Color1st)
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
    $panellist = $data | Get-Member | Where-Object { $_.membertype -eq 'NoteProperty' } | Select-Object name
    $panellistSorted = $panellist | ForEach-Object { [pscustomobject]@{
            name        = $_.Name
            PanelNumber = $data.($_.name).config.PanelNumber
        }
    } | Sort-Object -Property PanelNumber


    foreach ($pan in $panellistSorted) {
        $panel = NPanel -LabelText $pan.name
        foreach ($but in $data.($pan.name).buttons) {
            [scriptblock]$clickAction = [scriptblock]::Create( "Invoke-Action -control `$_ -name `"$($but.Name)`" -command `"$($but.command)`" -arguments `"$(($but|Select-Object -ExpandProperty arguments -ErrorAction SilentlyContinue) -replace '"' , '`"`"')`" -mode $($but.Mode) -Window `"$($but.Window)`" -RunAsAdmin `"$($but.RunAsAdmin)`"" )
            NButton -Text $but.Name -clickAction $clickAction -panel $panel
        }
    }
    #endregion

    #region bginfo
    $BGInfoPanel = New-Object system.Windows.Forms.Panel
    $BGInfoPanel.height = 490
    $BGInfoPanel.width = 420
    $BGInfoPanel.location = New-Object System.Drawing.Point($PanelDraw, 10)
    $BGInfoPanel.BorderStyle = 'Fixed3D'
    $BGInfoPanel.BackColor = [System.Drawing.ColorTranslator]::FromHtml($Script:Color2nd)
    $BGInfoPanel.AutoScroll = $false
    $BGInfoPanel.AutoSizeMode = 'GrowAndShrink'
    $BGInfoPanel.Refresh()

    $CompNameLabel = New-Object system.Windows.Forms.Label
    $CompNameLabel.text = "$(($env:COMPUTERNAME).ToUpper()).$((Get-CimInstance -ClassName Win32_ComputerSystem).domain)"
    $CompNameLabel.AutoSize = $false
    $CompNameLabel.Dock = [System.Windows.Forms.DockStyle]::Top
    $CompNameLabel.width = 400
    $CompNameLabel.height = 50    
    $CompNameLabel.location = New-Object System.Drawing.Point(1,10)
    $CompNameLabel.Font = [System.Drawing.Font]::new('Tahoma', 24, [System.Drawing.FontStyle]::Bold)
    $CompNameLabel.TextAlign = [System.Drawing.ContentAlignment]::TopCenter
    $CompNameLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($Script:LabelColor)
    $CompNameLabel.Refresh()
    $BGInfoPanel.controls.AddRange(@($CompNameLabel))


    $DestriptionLabel = New-Object system.Windows.Forms.Label
    $DestriptionLabel.text = $jsondata.Config.Description
    $DestriptionLabel.AutoSize = $false
    $DestriptionLabel.width = 420
    $DestriptionLabel.height = 30
    $DestriptionLabel.location = New-Object System.Drawing.Point(1,60)
    $DestriptionLabel.Font = [System.Drawing.Font]::new('Tahoma', 16)
    $DestriptionLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $DestriptionLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($Script:LabelColor)
    $DestriptionLabel.Refresh()
    $BGInfoPanel.controls.AddRange(@($DestriptionLabel))

    $LineLabel = New-Object system.Windows.Forms.Label
    $LineLabel.text = ""
    $LineLabel.AutoSize = $false
    $LineLabel.width = 420
    $LineLabel.height = 2
    $LineLabel.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
    $LineLabel.location = New-Object System.Drawing.Point(1,100)
    $LineLabel.Refresh()
    $BGInfoPanel.controls.AddRange(@($LineLabel))

    ### Build Clock
    ###

    try {
    $BginfoDetails = [PSCustomObject]@{
        'User Name'    = $env:USERNAME
        'User Domain'  = $env:USERDNSDOMAIN
        OS          = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
        'Boot Time'    = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
        'Install Date' = (Get-CimInstance -ClassName Win32_OperatingSystem).InstallDate
        Memory      = "$([Math]::Round((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1gb)) GB"
        IP          = @(((Get-CimInstance -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=$true).ipaddress |Out-String).Trim())
        'Free Space'  = @(((Get-CimInstance -Namespace root/cimv2 -ClassName win32_logicaldisk | Where-Object {$_.DriveType -like 3} | ForEach-Object {"$($_.DeviceID) $([Math]::Round($_.FreeSpace / 1gb)) GB"}) | Out-String).trim())
    }
    } catch {Write-Warning "Unable to collect pc details"}
    
    $HightIndex = 110
    $BginfoDetails.psobject.properties | Select-Object name, value | ForEach-Object {
        $TmpLabelName = New-Object system.Windows.Forms.Label
        $TmpLabelName.text = $_.name
        $TmpLabelName.AutoSize = $true
        $TmpLabelName.width = 150
        $TmpLabelName.height = 10
        $TmpLabelName.location = New-Object System.Drawing.Point(10, $HightIndex)
        $TmpLabelName.Font = [System.Drawing.Font]::new('Tahoma', 10, [System.Drawing.FontStyle]::Bold)
        $TmpLabelName.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
        $TmpLabelName.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($Script:LabelColor)
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
        $TmpLabelValue.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($Script:LabelColor)
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
    $exit.location = New-Object System.Drawing.Point(1, 510)
    $exit.Font = New-Object System.Drawing.Font('Tahoma', 8)
    $exit.BackColor = [System.Drawing.ColorTranslator]::FromHtml($Script:Color1st)
    $exit.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($Script:TextColor)
    $exit.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
    $exit.Add_Click( {
            Write-Output 'exiting Util'
            $cmd = {
                Param([int]$ID)
                $r = Get-Runspace -Id $id
                $r.close()
                $r.dispose()
            }
            Start-ThreadJob -ScriptBlock $cmd -ArgumentList $rs.id
            $Form.Close()
        })

    $reload = New-Object system.Windows.Forms.Button
    $reload.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
    $reload.text = 'Reload'
    $reload.width = 100
    $reload.height = 30
    $reload.location = New-Object System.Drawing.Point(100, 510)
    $reload.Font = New-Object System.Drawing.Font('Tahoma', 8)
    $reload.BackColor = [System.Drawing.ColorTranslator]::FromHtml($Script:Color1st)
    $reload.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($Script:TextColor)
    $reload.Add_Click( {
            Write-Output 'Reloading Util'
            Start-Process -FilePath 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -ArgumentList "-NoLogo -NoProfile -WindowStyle Hidden -ExecutionPolicy bypass -command ""& {Start-PSLauncher -PSLauncherConfigFile $($PSLauncherConfigFile)}"""
            Get-Job -Name PSLauncherJob | Stop-Job
            $Form.Close()
        })
    $EnableLogging = New-Object system.Windows.Forms.Button
    $EnableLogging.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
    $EnableLogging.text = 'Enable Logging'
    $EnableLogging.width = 100
    $EnableLogging.height = 30
    $EnableLogging.location = New-Object System.Drawing.Point(1, 540)
    $EnableLogging.Font = New-Object System.Drawing.Font('Tahoma', 8)
    $EnableLogging.BackColor = [System.Drawing.ColorTranslator]::FromHtml($Script:Color1st)
    $EnableLogging.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($Script:TextColor)
    $EnableLogging.Add_Click( { EnableLogging })

    $DisableLogging = New-Object system.Windows.Forms.Button
    $DisableLogging.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
    $DisableLogging.text = 'Disable Logging'
    $DisableLogging.width = 100
    $DisableLogging.height = 30
    $DisableLogging.location = New-Object System.Drawing.Point(100, 540)
    $DisableLogging.Font = New-Object System.Drawing.Font('Tahoma', 8)
    $DisableLogging.BackColor = [System.Drawing.ColorTranslator]::FromHtml($Script:Color1st)
    $DisableLogging.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($Script:TextColor)
    $DisableLogging.Add_Click( { DisableLogging })

    $AddToConfig = New-Object system.Windows.Forms.Button
    $AddToConfig.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
    $AddToConfig.text = 'Add GUI Config'
    $AddToConfig.width = 100
    $AddToConfig.height = 30
    $AddToConfig.location = New-Object System.Drawing.Point(1, 570)
    $AddToConfig.Font = New-Object System.Drawing.Font('Tahoma', 8)
    $AddToConfig.BackColor = [System.Drawing.ColorTranslator]::FromHtml($Script:Color1st)
    $AddToConfig.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($Script:TextColor)
    $AddToConfig.Add_Click( {
            ShowConsole
            Start-Process -FilePath 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -ArgumentList "-NoLogo -NoProfile -ExecutionPolicy bypass -command ""& {Add-PSLauncherEntry -PSLauncherConfigFile $($PSLauncherConfigFile) -execute}"""
            Get-Job -Name PSLauncherJob | Stop-Job
            $Form.Close()
            HideConsole
        })

    $OpenConfigButton = New-Object system.Windows.Forms.Button
    $OpenConfigButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
    $OpenConfigButton.text = 'Open Config File'
    $OpenConfigButton.width = 100
    $OpenConfigButton.height = 30
    $OpenConfigButton.location = New-Object System.Drawing.Point(100, 570)
    $OpenConfigButton.Font = New-Object System.Drawing.Font('Tahoma', 8)
    $OpenConfigButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml($Script:Color1st)
    $OpenConfigButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($Script:TextColor)
    $OpenConfigButton.Add_Click( { . $PSLauncherConfigFile })

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

    #ShowConsole
    HideConsole
    [void]$Form.ShowDialog()
} #end Function
