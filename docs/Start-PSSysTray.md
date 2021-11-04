---
external help file: PSLauncher-help.xml
Module Name: PSLauncher
online version:
schema: 2.0.0
---

# Start-PSSysTray

## SYNOPSIS
Gui menu app in your systray with custom executable functions

## SYNTAX

```
Start-PSSysTray [-ConfigFilePath] <String> [<CommonParameters>]
```

## DESCRIPTION
Gui menu app in your systray with custom executable functions

## EXAMPLES

### Example 1
```powershell
PS C:\> Start-PSSysTray -ConfigFilePath C:\temp\PSSysTrayConfig.csv
```

## PARAMETERS

### -ConfigFilePath
Path to .csv config file created from Install-PSSysTrayConfigFile

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
