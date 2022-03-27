---
external help file: PSLauncher-help.xml
Module Name: PSLauncher
online version:
schema: 2.0.0
---

# Start-PSLauncher

## SYNOPSIS
Reads the config file and launches the gui

## SYNTAX

```
Start-PSLauncher [-PSLauncherConfigFile] <FileInfo> [<CommonParameters>]
```

## DESCRIPTION
Reads the config file and launches the gui

## EXAMPLES

### EXAMPLE 1
```
Start-PSLauncher -PSLauncherConfigFile c:\temp\config.json
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
