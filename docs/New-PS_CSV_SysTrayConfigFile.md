---
external help file: PSLauncher-help.xml
Module Name: PSLauncher
online version:
schema: 2.0.0
---

# New-PS_CSV_SysTrayConfigFile

## SYNOPSIS
Creates the config file for Start-PSSysTray

## SYNTAX

```
New-PS_CSV_SysTrayConfigFile [[-ConfigPath] <DirectoryInfo>] [-CreateShortcut] [<CommonParameters>]
```

## DESCRIPTION
Creates the config file for Start-PSSysTray

## EXAMPLES

### EXAMPLE 1
```
New-PS_CSV_SysTrayConfigFile -ConfigPath C:\temp -CreateShortcut
```

## PARAMETERS

### -ConfigPath
Path where config file will be saved.

```yaml
Type: DirectoryInfo
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CreateShortcut
Create a shortcut to launch the gui

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
