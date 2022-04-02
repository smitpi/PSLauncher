
<#PSScriptInfo

.VERSION 1.1.2

.GUID 1f51337a-a640-4852-9499-e5f150edc13a

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
Created [30/09/2021_21:16] Initial Script Creating
Updated [05/10/2021_08:31] Added Color Button
Updated [24/10/2021_06:00] 'Updated module/script info'

.PRIVATEDATA

#>





<#

.DESCRIPTION
Launches a Gui form to test and change the Color of PSLauncher.

#>
<#
.SYNOPSIS
Launches a Gui form to test and change the Color of PSLauncher.

.DESCRIPTION
Launches a Gui form to test and change the Color of PSLauncher.

.PARAMETER PSLauncherConfigFile
Path to the config file created by New-PSLauncherConfigFile

.EXAMPLE
Start-PSLauncherColorPicker -PSLauncherConfigFile c:\temp\PSLauncherConfig.json

#>
Function Start-PSLauncherColorPicker {
    [Cmdletbinding(HelpURI = 'https://smitpi.github.io/Start-PSLauncherColorPicker/')]
    Param (
        [ValidateScript( { if ((Test-Path $_) -and ((Get-Item $_).Extension -eq '.csv')) { $true}
                else {throw 'Not a valid config file.'} })]
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


    $box4 = New-Object System.Windows.Forms.TextBox
    $box4.AutoSize = $true
    $box4.Width = 100
    $box4.Height = 30
    $box4.Text = $jsondata.Config.LogoUrl
    $box4.Location = New-Object System.Drawing.Point(100, 380)
    $box4_Label = New-Object system.Windows.Forms.Label
    $box4_Label.text = 'Logo URL'
    $box4_Label.AutoSize = $true
    $box4_Label.width = 100
    $box4_Label.height = 30
    $box4_Label.location = New-Object System.Drawing.Point(1, 380)
    $box4_Label.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($TextColor)

    #region picture
    $PictureBox1 = New-Object system.Windows.Forms.PictureBox
    $PictureBox1.width = 200
    $PictureBox1.height = 100
    $PictureBox1.location = New-Object System.Drawing.Point(10, 410)
    $PictureBox1.imageLocation = $jsondata.Config.LogoUrl
    $PictureBox1.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::zoom
    $Form.controls.AddRange($PictureBox1)
    #endregion


    $Update_Button = New-Object system.Windows.Forms.Button
    $Update_Button | Add-Member -Name MyScriptPath -Value $MyScriptPath -MemberType NoteProperty
    $Update_Button.text = 'update'
    $Update_Button.width = 200
    $Update_Button.height = 30
    $Update_Button.BackColor = [System.Drawing.ColorTranslator]::FromHtml($Color1st)
    $Update_Button.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($TextColor)
    $Update_Button.location = New-Object System.Drawing.Point(10, 60)
    $Update_Button.Font = New-Object System.Drawing.Font('Tahoma', 10)
    $Update_Button.add_click( {
            $Form.BackColor = [System.Drawing.ColorTranslator]::FromHtml($box1.Text)
            $Panel.BackColor = [System.Drawing.ColorTranslator]::FromHtml($box2.Text)
            $label.ForeColor = $box3.Text
            $PictureBox1.imageLocation = $box4.Text
            $Update_Button.BackColor = [System.Drawing.ColorTranslator]::FromHtml($box1.Text)
            $Set_Button.BackColor = $box1.Text
            $Update_Button.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($box5.Text)
            $Set_Button.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($box5.Text)
            $box1_Label.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($box5.Text)
            $box2_Label.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($box5.Text)
            $box3_Label.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($box5.Text)
            $box4_Label.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($box5.Text)
            $box5_Label.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($box5.Text)
            $Form.Refresh()
        })
    $Update_Button.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard

    $Set_Button = New-Object system.Windows.Forms.Button
    $Set_Button | Add-Member -Name MyScriptPath -Value $MyScriptPath -MemberType NoteProperty
    $Set_Button.text = 'Set'
    $Set_Button.width = 200
    $Set_Button.height = 30
    $Set_Button.BackColor = [System.Drawing.ColorTranslator]::FromHtml($Color1st)
    $Set_Button.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($TextColor)
    $Set_Button.location = New-Object System.Drawing.Point(10, 90)
    $Set_Button.Font = New-Object System.Drawing.Font('Tahoma', 10)
    $Set_Button.add_click( {
            $new = [psobject]@{
                Config  = [psobject] @{
                    Color1st   = $($box1.Text)
                    Color2nd   = $($box2.Text)
                    LabelColor = $($box3.Text)
                    LogoUrl    = $($box4.Text)
                    TextColor  = $($box5.Text)
                    AppTitle   = $($jsondata.Config.AppTitle)
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

    HideConsole
    [void]$Form.ShowDialog()
} #end Function
