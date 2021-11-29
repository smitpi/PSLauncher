
<#PSScriptInfo

.VERSION 0.1.0

.GUID 41aa308f-60e2-499b-aa12-a92e73f4a1c1

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
Created [24/10/2021_05:59] Initial Script Creating

.PRIVATEDATA

#>

<#

.DESCRIPTION
 Gui menu app in your systray with custom executable functions

#>
<#
.SYNOPSIS
Gui menu app in your systray with custom executable functions

.DESCRIPTION
Gui menu app in your systray with custom executable functions. If you double click on the icon,
it will launch the full gui.

.PARAMETER ConfigFilePath
Path to the config file created by New-PSLauncherConfigFile

.EXAMPLE
Start-PSSysTrayLauncher -ConfigFilePath C:\temp\PSSysTrayConfig.csv

#>
Function Start-PSSysTrayLauncher {
    [Cmdletbinding(SupportsShouldProcess = $true)]
    Param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript( { (Test-Path $_) -and ((Get-Item $_).Extension -eq '.json') })]
        [string]$ConfigFilePath
    )
    if ($pscmdlet.ShouldProcess('Target', 'Operation')) {
        $jsondata = Get-Content $ConfigFilePath | ConvertFrom-Json


        Add-Type -Name Window -Namespace Console -MemberDefinition '
    [DllImport("Kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'

        # Declare assemblies
        [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null
        [System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | Out-Null
        [System.Reflection.Assembly]::LoadWithPartialName('System.Drawing') | Out-Null
        [System.Reflection.Assembly]::LoadWithPartialName('WindowsFormsIntegration') | Out-Null

        # Add an icon to the systrauy button
        $module = Get-Module pslauncher
        if (![bool]$module) {$module = Get-Module pslauncher -ListAvailable }
        $icopath = (Join-Path $module.ModuleBase '\Private\pslauncher.ico') | Get-Item
        $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($icopath.FullName)

        # Create object for the systray
        $Systray_Tool_Icon = New-Object System.Windows.Forms.NotifyIcon
        # Text displayed when you pass the mouse over the systray icon
        $Systray_Tool_Icon.Text = 'PS Utils'
        # Systray icon
        $Systray_Tool_Icon.Icon = $icon
        $Systray_Tool_Icon.Visible = $true
        $contextmenu = New-Object System.Windows.Forms.ContextMenu
        $Systray_Tool_Icon.ContextMenu = $contextmenu

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
            Write-Output  $processArguments
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
            }
            else {
                Write-Verbose -Message "$(Get-Date -Format G): pid $($process.Id) - $($process.Name) `"$($processArguments[ 'ArgumentList'] )`""

                if ( $options -contains 'Wait' ) {
                    $process.WaitForExit()
                    Write-Verbose -Message "$(Get-Date -Format G -Date $process.ExitTime): pid $($process.Id) - $($process.Name) exited with status $($process.ExitCode)"
                }
            }
            HideConsole
        }
        function ShowConsole {
            $PSConsole = [Console.Window]::GetConsoleWindow()
            [Console.Window]::ShowWindow($PSConsole, 5)
        }
        function HideConsole {
            $PSConsole = [Console.Window]::GetConsoleWindow()
            [Console.Window]::ShowWindow($PSConsole, 0)
        }
        function NMenuItem {
            param(
                [string]$Text = 'Placeholder Text',
                [scriptblock]$clickAction,
                [System.Windows.Forms.MenuItem]$MainMenu
            )

            #Initialization
            $MenuItem = New-Object System.Windows.Forms.MenuItem
            $MenuItem.Text = $Text
            $MenuItem.Add_Click($clickAction)
            $MainMenu.MenuItems.AddRange($MenuItem)
        }
        function NMainMenu {
            param(
                [string]$Text = 'Placeholder Text',
                [switch]$AddExit = $false
            )
            $MainMenu = New-Object System.Windows.Forms.MenuItem
            $MainMenu.Text = $Text
            $Systray_Tool_Icon.contextMenu.MenuItems.AddRange($MainMenu)
            $MainMenu
        }

        #region create panels and buttons
        $data = $jsondata.Buttons
        $panellist = $data | Get-Member | Where-Object { $_.membertype -eq 'NoteProperty' } | Select-Object name
        $panellistSorted = $panellist | ForEach-Object { [pscustomobject]@{
                name        = $_.Name
                PanelNumber = $data.($_.name).config.PanelNumber
            }
        } | Sort-Object -Property PanelNumber


        foreach ($pan in $panellistSorted) {
            $tmpmenu = NMainMenu -Text $pan.name
            foreach ($but in $data.($pan.name).buttons) {
                [scriptblock]$clickAction = [scriptblock]::Create( "Invoke-Action -name `"$($but.Name)`" -command `"$($but.command)`" -arguments `"$(($but|Select-Object -ExpandProperty arguments -ErrorAction SilentlyContinue) -replace '"' , '`"`"')`" -mode $($but.Mode) -options `"$(($but|Select-Object -ExpandProperty options -ErrorAction SilentlyContinue) -split ',')`"" )
                NMenuItem -Text $but.name -clickAction $clickAction -MainMenu $tmpmenu
            }
        }

        $Menu_Exit = New-Object System.Windows.Forms.MenuItem
        $Menu_Exit.Text = 'Exit'
        $Menu_Exit.add_Click( {
                $Systray_Tool_Icon.Visible = $false
                $window.Close()
                $window_Config.Close()
                Stop-Process $pid
            })
        $Systray_Tool_Icon.contextMenu.MenuItems.AddRange($Menu_Exit)

        $Systray_Tool_Icon.Add_MouseDoubleClick( {
                ShowConsole
                $Config = Get-Item $ConfigFilePath
                $launcher = (Join-Path $Config.DirectoryName -ChildPath \PSLauncher.ps1) | Get-Item
                Start-Process PowerShell -ArgumentList "-NoLogo -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -file `"$($launcher.FullName)`""
                HideConsole
            })

        # Create an application context for it to all run within.
        # This helps with responsiveness, especially when clicking Exit.
        HideConsole
        $appContext = New-Object System.Windows.Forms.ApplicationContext
        [void][System.Windows.Forms.Application]::Run($appContext)


    }
} #end Function

