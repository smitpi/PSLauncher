---
external help file: PSLauncher-help.xml
Module Name: PSLauncher
online version:
schema: 2.0.0
---

# Add-PSLauncherEntry

## SYNOPSIS
Add a button or panal to the config.

## SYNTAX

```
Add-PSLauncherEntry [[-PSLauncherConfigFile] <FileInfo>] [-Execute] [<CommonParameters>]
```

## DESCRIPTION
Add a button or panal to the config.

## EXAMPLES

### EXAMPLE 1
```
Add-PSLauncherEntry -PSLauncherConfigFile c:\temp\PSLauncherConfig.json
```

## PARAMETERS

### -PSLauncherConfigFile
Path to the config file created by New-PSLauncherConfigFile

```yaml
Type: FileInfo
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Execute
Run Start-PSLauncher after config change.

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
