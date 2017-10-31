## Indicator Removal on Host

MITRE ATT&CK Technique: [T1070](https://attack.mitre.org/wiki/Technique/T1070)

## Wevtutil

Clear system logs

    wevtutil cl System

Clear Security logs

    wevtutil cl Security

Clear Setup logs

    wevtutil cl Setup

Clear Application logs

    wevtutil cl Application

## Fsutil

Manages the update sequence number (USN) change journal, which provides a persistent log of all changes made to files on the volume.

    fsutil usn deletejournal /D C:
