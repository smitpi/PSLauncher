---
external help file: PSLauncher-help.xml
Module Name: PSLauncher
online version:
schema: 2.0.0
---

# New-PSLauncherConfigFile

## SYNOPSIS
Creates the config file with the provided settings

## SYNTAX

```
New-PSLauncherConfigFile [[-Color1] <String>] [[-Color2] <String>] [[-LabelColor] <String>]
 [[-TextColor] <String>] [[-LogoPath] <String>] [[-Title] <String>] [[-Panel01] <String>] [[-Panel02] <String>]
 [[-ConfigPath] <DirectoryInfo>] [-CreateShortcut] [-LaunchColorPicker]
```

## DESCRIPTION
Creates the config file with the provided settings

## EXAMPLES

### EXAMPLE 1
```
New-PSLauncherConfigFile -ConfigPath c:\temp -LaunchColorPicker
```

## PARAMETERS

### -Color1
Run Start-PSLauncherColorPicker to change.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: #E5E5E5
Accept pipeline input: False
Accept wildcard characters: False
```

### -Color2
Run Start-PSLauncherColorPicker to change.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: #061820
Accept pipeline input: False
Accept wildcard characters: False
```

### -LabelColor
Run Start-PSLauncherColorPicker to change.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: #FFD400
Accept pipeline input: False
Accept wildcard characters: False
```

### -TextColor
Run Start-PSLauncherColorPicker to change.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: #000000
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogoPath
Run Start-PSLauncherColorPicker to change.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: Https://gist.githubusercontent.com/smitpi/0e36b701419dbf9282ecfc6d0f7b654c/raw/8fe6a2fc91a27a9ebccb753f6508a2edd039c208/default-monochrome-black.png
Accept pipeline input: False
Accept wildcard characters: False
```

### -Title
Text in the title of the app.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: PowerShell Launcher
Accept pipeline input: False
Accept wildcard characters: False
```

### -Panel01
Name of the 1st panel

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: First
Accept pipeline input: False
Accept wildcard characters: False
```

### -Panel02
Name of the 2nd panel

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: Second
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConfigPath
Path where the config file will be saved.

```yaml
Type: DirectoryInfo
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: (Join-Path (Get-Module pslauncher).ModuleBase \config)
Accept pipeline input: False
Accept wildcard characters: False
```

### -CreateShortcut
Creates a shortcut in the same directory that calls PowerShell and the config.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -LaunchColorPicker
Launches Start-PSLauncherColorPicker

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
