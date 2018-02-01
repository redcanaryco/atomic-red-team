# Chain Reaction - Argonaut - Detection

[Chain Reaction - Argonaut](https://github.com/redcanaryco/atomic-red-team/blob/master/ARTifacts/Chain_Reactions/chain_reaction_Argonaut.ps1)

## Tactics: Execution, Discovery

Technique: [PowerShell](https://attack.mitre.org/wiki/Technique/T1086)

### Baseline

    process_name:powershell.exe AND netconn_count:[1 TO *]
    filemod:\AppData\Local\Temp\*.bat
