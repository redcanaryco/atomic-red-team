# Private Keys

MITRE ATT&CK Technique: [T1145](https://attack.mitre.org/wiki/Technique/T1145)

File extensions include: .key, .pgp, .gpg, .ppk., .p12, .pem, pfx, .cer, .p7b, .asc

Input:

Make some files:

      echo "ATOMICREDTEAM" > %windir%\cert.key
      
Find files:

      dir c:\ /b /s .key | findstr /e .key
