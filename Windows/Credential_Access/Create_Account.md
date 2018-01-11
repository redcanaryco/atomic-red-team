# Create Account

MITRE ATT&CK Technique: [T1136](https://attack.mitre.org/wiki/Technique/T1136)

## Net.exe

Local user add:

    Net user /add Trevor SmshBgr123

Add new user to localgroup:

    net localgroup administrators Trevor /add

Domain add:

    net user <username> \password \domain

Add user to Active Directory:

    dsadd user CN=John,CN=Users,DC=it,DC=uk,DC=savilltech,DC=com -samid John -pwd Pa55word123

# Powershell 5.1

The following requires [Powershell 5.1](https://www.microsoft.com/en-us/download/details.aspx?id=54616)

Additional information [here](https://4sysops.com/archives/the-new-local-user-and-group-cmdlets-in-powershell-5-1/)

## Add User

    New-LocalUser -FullName 'Trevor R.' -Name 'Trevor' -Password SmshBgr ‑Description 'Pwnage account'

## Create a group

    New-LocalGroup -Name 'Testgroup' -Description 'Testing group'
