# Deobfuscate/Decode Files Or Information

MITRE ATT&CK Technique: [T1140](https://attack.mitre.org/wiki/Technique/T1140)

## Example encode executable

    certutil.exe -encode file.exe file.txt

## Example decode executable

    certutil.exe -decode file.txt file.exe
