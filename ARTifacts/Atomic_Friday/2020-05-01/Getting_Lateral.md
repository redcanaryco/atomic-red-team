# Getting Lateral

Using DetectionLab, we will enable [PSRemoting](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/enable-psremoting?view=powershell-7) on our remote host WEF and execute our Atomic Test on it.

## Setup

On WEF

```
Enable-PSRemoting
```

On Win10

Same terminal we used earlier:

`$sess = New-PSSession -ComputerName wef -Credential windomain.local\administrator`

Prompt for credentials

## Let's get Remote (execution)

Wiki - https://github.com/redcanaryco/invoke-atomicredteam/wiki/Execute-Atomic-Tests-(Remote)

After you have established the PS session ($sess) you can proceed with test execution as follows.

`Invoke-AtomicTest T1117 -TestNumbers 2 -ShowDetails`

`Invoke-AtomicTest T1003 -TestNumbers 4 -ShowDetails`

### Install any required prerequisites on the remote machine before test execution

`Invoke-AtomicTest T1117 -Session $sess -GetPrereqs`

### execute all atomic tests in technique T1117|T1003 on a remote machine

`Invoke-AtomicTest T1117 -Session $sess -TestNumbers 2`

`Invoke-AtomicTest T1003 -TestNumbers 4 -Session $sess`

## Validate execution

[T1117 Splunk](https://192.168.38.105:8000/en-US/app/search/search?q=search%20host%3Dwef*%20regsvr32.exe%20earliest%3D-30m%20latest%3Dnow&display.page.search.mode=smart&dispatch.sample_ratio=1&workload_pool=&earliest=-24h%40h&latest=now&sid=1588276958.707)

[T1003 Splunk](https://192.168.38.105:8000/en-US/app/search/search?q=search%20host%3Dwef*%20reg.exe%20earliest%3D-30m%20latest%3Dnow%20%7C%20stats%20values(Process_Command_Line)&display.page.search.mode=smart&dispatch.sample_ratio=1&workload_pool=&earliest=-24h%40h&latest=now&sid=1588277661.75&display.page.search.tab=statistics&display.general.type=statistics)


## Random Tips

- Add user to "Remote management Users" group.

- Enabling PowerShell remoting on client versions of Windows when the computer is on a public network is normally disallowed, but you can skip this restriction by using the SkipNetworkProfileCheck parameter. For more information, see the description of the SkipNetworkProfileCheck parameter.

- psremoting to a Windows Server will require an Administrator account (I used Administrator above, as example shown)


## Reference

- PSRemoting - https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/enable-psremoting?view=powershell-7 