---
external help file: PSLauncher-help.xml
Module Name: PSLauncher
online version:
schema: 2.0.0
---

# Start-PSSysTrayLauncher

## SYNOPSIS
Gui menu app in your systray with custom executable functions

## SYNTAX

```
Start-PSSysTrayLauncher [-PSLauncherConfigFile] <FileInfo> [<CommonParameters>]
```

## DESCRIPTION
Gui menu app in your systray with custom executable functions.
If you double click on the icon,
it will launch the full gui.

## EXAMPLES

### EXAMPLE 1
```
Start-PSSysTrayLauncher -PSLauncherConfigFile C:\temp\PSSysTrayConfig.csv
```

## PARAMETERS

### -PSLauncherConfigFile
Path to the config file created by New-PSLauncherConfigFile

```yaml
Type: FileInfo
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
