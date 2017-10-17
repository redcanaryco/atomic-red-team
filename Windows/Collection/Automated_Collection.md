# Automated Collection

MITRE ATT&CK Technique: [T1119](https://attack.mitre.org/wiki/Technique/T1119)

## cmd.exe

### find:

Input:

     dir c: /b /s .docx | findstr /e .docx

### copy:

Input:

    for /R c: %f in (*.docx) do copy %f c:\temp\

## PowerShell

Find and copy

Input:

    powershell Get-ChildItem -Recurse -Include *.doc | % {Copy-Item $_.FullName -destination c:\temp}
