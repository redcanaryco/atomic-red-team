# Automation Framework for the Atomic Red Team

The Atomic Red Team project is unique in that it not only describes the tactics and techiques of the MITRE ATT&CK framework, but it also includes automation of these techniques.

Automation of this framework comes by way of this PowerShell module, ```AtomicRedTeam```.

Here's a quick example:

```
PS > Import-Module .\AtomicRedTeam.psd1
PS > Get-ArtAction Windows/Ex*
Windows/Execution/Trusted_Developer_Utilities/MSBuild
Windows/Execution/BitsAdmin

PS > Invoke-ArtAction Windows/Execution/Trusted_Developer_Utilities/MSBuild
Microsoft (R) Build Engine version 4.7.2556.0
[Microsoft .NET Framework, version 4.0.30319.42000]
Copyright (C) Microsoft Corporation. All rights reserved.

Build started 4/15/2018 4:48:44 PM.
Hello From a Code Fragment
Hello From a Class.

Build succeeded.
    0 Warning(s)
    0 Error(s)

Time Elapsed 00:00:00.18

PS > 

```

As we can see, the MSBuild technique was able to run arbitrary C#.

## Contributing to the Automation Framework

Automation within the Atomic Red Team Framework is largely driven by the self-describing format of the human-readable descriptions. This requires only two things:

1) Unique techniques within a tactic are described through separate markdown H3 ("```###```") tags.
2) Code that demonstrates this technique is within that H3 section, and indented by four spaces. As is often done, this code may be broken into chunks with descriptive text before or after it. This additional content will be ignored.

When you put these together, you get a basic technique description that might look like this:

```
### bitsadmin.exe

    bitsadmin.exe  /transfer /Download /priority Foreground https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/Windows/Execution/Bitsadmin.md $env:TEMP\AtomicRedTeam\bitsadmin_flag.ps1
```

Adding automation of thie technique is as simple as this, in ```AtomicRedTeam.psm1```

```
$actions = @{
    'Windows/Execution/BitsAdmin' = {

        ## Extract the command from the page
        $commands = Get-ActionCode -Path $PSScriptRoot/../Windows/Execution/BitsAdmin.md -SectionName bitsadmin.exe

        ## Launch the action
        Invoke-Expression $commands[0]
    }

...
```

## Respecting User Systems

Some tests make security-impacting changes to the host. To make sure that this is not done without user awareness, we need to also support the ```-Force``` parameter. We can do that by wrapping our invocation logic with the following code:

```
        if($Force -or $PSCmdlet.ShouldContinue("Do you with to clear the System log?", "Confirm impactful change"))
        {
            ...
        }

```

An example of this is in ```Windows/Defense_Evasion/Indicator_Removal_on_Host/System```

```
    'Windows/Defense_Evasion/Indicator_Removal_on_Host/System' = {

        if($Force -or $PSCmdlet.ShouldContinue("Do you with to clear the System log?", "Confirm impactful change"))
        {
            ## Extract the command from the page
            $commands = Get-ActionCode -Path $PSScriptRoot/../Windows/Defense_Evasion/Indicator_Removal_on_Host.md -SectionName 'wevtutil' |
                Where-Object { $_ -match 'System' }
            
            ## Launch the action
            Invoke-Expression $commands[0]
        }
    }
```

## Tweaking Documentation into Code

An action sometimes requires slight modification before evaluating it directly. For example, a portion of the command is left in as an demonstration - but should be replaced with something system-specific. A demonstration of this is from ```'Windows/Execution/Trusted_Developer_Utilities/MSBuild'```:

    C:\Windows\Microsoft.Net\Framework\v4.0.30319\MSBuild.exe File.csproj

_File.csproj_ is not actually what you want to run - the Atomic Red Team framework includes a sample payload in its ```/Windows/Payloads``` directory. Putting this value in the example itself might muddy the meaning of the content, so we can change it at runtime in the action itself. Here's an example:

```
$actions = @{

    ...

    'Windows/Execution/Trusted_Developer_Utilities/MSBuild' = {

        ## Extract the command from the page
        $commands = Get-ActionCode -Path $PSScriptRoot/../Windows/Execution/Trusted_Developer_Utilities.md -SectionName msbuild.exe
        $commandToInvoke,$commandArgs = $commands[0] -split ' '

        ## Run it, but with the real MSBuildBypass we've got in /Windows/Payloads
        & $commandToInvoke ..\Windows\Payloads\MSBuildBypass.csproj
    }

    ...

```