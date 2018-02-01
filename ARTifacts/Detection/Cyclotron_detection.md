# Chain Reaction - Cyclotron - Detection

[Chain Reaction - Cyclotron](https://github.com/redcanaryco/atomic-red-team/blob/master/ARTifacts/Chain_Reactions/chain_reaction_Cyclotron.bat)

## Tactic: Execution

 Technique: [Installutil](https://attack.mitre.org/wiki/Technique/T1118)

 Technique: [regsvcs/regasm](https://attack.mitre.org/wiki/Technique/T1121)

 Technique: [regsvr32](https://attack.mitre.org/wiki/Technique/T1117)

 Technique: [rundll32](https://attack.mitre.org/wiki/Technique/T1085)

### Baseline

    process_name:installutil.exe
    process_name:installutil.exe cmdline:\/LogToConsole=false
    process_name:regsvcs.exe
    process_name:regasm.exe
    process_name:regsvr32.exe cmdline:/s
    process_name:rundll32.exe
