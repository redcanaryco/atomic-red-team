#  Screen Capture

##  MITRE ATT&CK Technique: [T1113](https://attack.mitre.org/wiki/Technique/T1113)

##  Input:

    log show --debug | grep "GENERATED_NEW_IMAGE" | awk '{print $1,$2,$11,$27}'

###  For list of times a screenshot was generated and extension used


##  Input:

    log show --debug | grep "GENERATED_NEW_IMAGE" | awk '{print $1,$2,$11,$27}' | wc -l

### For number count of total images created
