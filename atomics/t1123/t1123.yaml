---
attack_technique: T1123
display_name: Audio Capture
  
atomic_tests:
- name: SourceRecorder via cmd.exe
  description: |
    Create a file called test.wma, with the duration of 30 seconds
  supported_platforms:
    - windows
  executor: command_prompt
  args:
    - output_file: test.wma
    - duration_hms: 0000:00:30
  command: cmd.exe /c "SoundRecorder /FILE #{output_file} /DURATION #{duration_hms}"

- name: PowerShell Cmdlet
  description: |
    [AudioDeviceCmdlets](https://github.com/cdhunt/WindowsAudioDevice-Powershell-Cmdlet)
  supported_platforms:
    - windows
  executor: powershell
  args:
  command: powershell.exe xxxxx
