# Timestomp

## MITRE ATT&CK Technique:
	[T1099](https://attack.mitre.org/wiki/Technique/T1099)


## Create a test file to work with
    touch testfile

OR

    echo "This is only a test" > testfile

## Examine the current timestamp
    stat testfile

## Set only the access timestamp
    touch -a -t 197001010000.00 testfile
    stat testfile

## Set only the modification timestamp
    touch -m -t 197001010000.00 testfile
    stat testfile

## Setting the creation timestamp requires changing the system clock and reverting. Sudo or root privileges are required to change date. Use with caution.
    NOW=$(date)
    date -s "1970-01-01 00:00:00"
    touch testfile
    date -s "$NOW"
    stat testfile
