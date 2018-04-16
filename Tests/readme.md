# Automatic Testing for Atomic Red Team

The test framework for the Atomic Red Team repository leverages [Pester](http://www.powershellmagazine.com/2014/03/12/get-started-with-pester-powershell-unit-testing-framework/), the PowerShell-based unit testing framework built into Windows.

## Background

A significant benefit of the Atomic Red Team GitHub repository is that you can browse a human-readable description of the techniques, which are then interspersed with code examples of the techniques. The structure of this content drives the automation of these techniques, as well as the unit tests.

Unit tests are grouped into files named after the operating system and MITRE tactic category. For example:

```
    WindowsExecution.tests.ps1
    WindowsLateralMovement.tests.ps1
```

The ```.tests.ps1``` portion of the filename tags the file as one that Pester should invoke.

Tests within each tactic follow a common pattern:

1) Invoke a similarly-named action from the Atomic Red Team automation framework
2) Validate the results against what is expected
3) Clean up any remnants left behind by the action

Here's an example:

```
    It "Validates MSBuild Trusted Developer Utilities" {

        $result = Invoke-ArtAction -Action Windows/Execution/Trusted_Developer_Utilities/MSBuild
        $result -match "Hello From" | Measure-Object | Foreach-Object Count | Should be 2
    }
```

Assuming a corresponding action has been written, the ```Invoke-ArtAction``` commands in the Atomic Red Team automation framework directly leverage the content of the Atomic Red Team tactic and technique descriptions. Any breaking changes or incorrect techniques will be detected by existing tests in this framework.

## Adding an Atomic Red Team Unit Test

To add a new test within an existing tactic category, simply add a new 'It' section within the file already existing for that tactic category.

To add a test for a new tactic category, simply create a new file that matches the current naming pattern. There is no need to "register" this new tactic category, as the naming convention will cause it to be automatically picked up by Pester.

## Running the Unit Tests

To invoke the unit tests, simply run ```Invoke-Pester``` from PowerShell.