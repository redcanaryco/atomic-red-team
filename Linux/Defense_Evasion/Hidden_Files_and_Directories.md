# Hidden Files and Directories

MITRE ATT&CK Technique: [T1158](https://attack.mitre.org/wiki/Technique/T1158)

To create visible directories and files

    mkdir visible-directory
    echo "this file is visible" > visible-directory/visible-file

    # List the contents the current directory and visible directory
    ls
    ls visible-directory


To create hidden directories and files

    mkdir .hidden-directory
    echo "this file is hidden" > .hidden-directory/.hidden-file

    # List the contents the current directory and hidden directory
    ls -la
    ls -la .hidden-directory