# Chain Reaction - Reactor - Detection

## Tactic: Discovery
 Technique: [System Owner/User Discovery](https://attack.mitre.org/wiki/Technique/T1033)

### Baseline

    process_name:qwinsta.exe
    process_name:rwinsta.exe
    process_name:quser.exe

### Monitor

    process_name:qwinsta.exe OR process_name:rwinsta.exe OR process_name:quser.exe

## Tactic: Credential Access, Lateral Movement
Technique: [Brute Force](https://attack.mitre.org/wiki/Technique/T1110)

Technique: [Windows Admin Shares](https://attack.mitre.org/wiki/Technique/T1077)

### Baseline

    process_name:net.exe
    process_name:net.exe cmdline:ipc$
    process_name:net.exe AND netconn_count:[1 TO *]


### Monitor

    process_name:net.exe AND cmdline:ipc$
    process_name:net.exe AND netconn_count:[1 TO *]

## Tactic: Discovery
Technique: [Security Software Discovery](https://attack.mitre.org/wiki/Technique/T1063)

### Baseline

    process_name:tasklist.exe
    parent_name:tasklist.exe process_name:findstr.exe
    process_name:powershell.exe cmdline:iex
    process_name:powershell.exe AND netconn_count:[1 TO *]

### Monitor

    process_name:findstr.exe cmdline:cb
    (process_name:powershell.exe AND (cmdline:{iex\(\(New-Object OR cmdline:\"iex\(New-Object OR cmdline:iex or cmdline:\"iex)
    process_name:powershell.exe AND netconn_count:[1 TO *]


## Tactic: Execution, Discovery
Technique: [PowerShell](https://attack.mitre.org/wiki/Technique/T1086)

Technique: Multiple Discovery

### Baseline

    process_name:powershell.exe AND netconn_count:[1 TO *]

### Monitor

    process_name:powershell.exe AND netconn_count:[1 TO *]


## Tactic: Collection
Technique: [Automated Collection](https://attack.mitre.org/wiki/Technique/T1119)

### Baseline:

    filemod_count:[1 TO 1000] (process_name:cmd.exe OR process_name:powershell.exe)

## Tactic: Exfiltration
Technique: [Data Compressed](https://attack.mitre.org/wiki/Technique/T1002)

### Baseline

    process_name:winrar.exe
    process_name:rar.exe
    process_name:tar
    process_name:7z.exe
    process_name:unzip
    process_name:winzip.exe
    Process_name:powershell.exe cmdline:compress-archive

### Monitor

    Process_name:powershell.exe cmdline:compress-archive
