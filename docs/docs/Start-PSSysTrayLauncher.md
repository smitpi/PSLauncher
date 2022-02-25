---
external help file: PsLauncher-help.xml
Module Name: PsLauncher
online version:
schema: 2.0.0
---

# Start-PSSysTrayLauncher

## SYNOPSIS
Gui menu app in your systray with custom executable functions

## SYNTAX

```
Start-PSSysTrayLauncher [-ConfigFilePath] <String> [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Gui menu app in your systray with custom executable functions.
If you double click on the icon,
it will launch the full gui.

## EXAMPLES

### EXAMPLE 1
```
Start-PSSysTrayLauncher -ConfigFilePath C:\temp\PSSysTrayConfig.csv
```

## PARAMETERS

### -ConfigFilePath
Path to the config file created by New-PSLauncherConfigFile

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
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
