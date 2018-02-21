# Space After Filename

MITRE ATT&CK Technique: [T1151](https://attack.mitre.org/wiki/Technique/T1151)

### Generate Binary
    echo '#!/bin/bash\necho "print \"hello, world!\"" | /usr/bin/python\nexit' > execute.txt && chmod +x execute.txt

### Add Space After Filename
    mv execute.txt "execute.txt "

### Execute
    ./execute.txt\ 
