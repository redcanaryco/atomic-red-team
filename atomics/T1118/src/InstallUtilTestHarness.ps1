function Get-CommandLineArgument {
<#
.SYNOPSIS

Parses a command-line string and returns arguments as a string array.

.DESCRIPTION

Get-CommandLineArgument is a wrapper for CommandLineToArgvW that is used to parse a command-line string and return each argument as a string array.

This function was created with the following use cases in mind:

1) A mechanism to programmatically supply a .NET executable entrypoint method with command-line arguments in the expected String[] format.
2) To use existing OS functionality to parse and interpret special command-line characters. For example, an argument with spaces inside double quotes should be returned as a single string. Wrapping CommandLineToArgvW eliminates the need to develop error-prone parsing logic.

.PARAMETER CommandLine

Specifies a single command line string to be parsed.

.EXAMPLE

Get-CommandLineArgument -CommandLine '/c echo "hello, world!"'

.OUTPUTS

System.String[]

Outputs an array of parsed command line arguments.
#>

    [CmdletBinding()]
    [OutputType([String[]])]
    param (
        [Parameter(Mandatory)]
        [String]
        [ValidateNotNullOrEmpty()]
        $CommandLine
    )

    if (-not ('GetCommandLineArgumentHelper.NativeMethods' -as [Type])) {
        $Signature = @'
        [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
        public static extern IntPtr CommandLineToArgvW([MarshalAs(UnmanagedType.LPWStr)] string cmdLine, out int numArgs);

        [DllImport("kernel32.dll")]
        public static extern IntPtr LocalFree(IntPtr hMem);
'@

        Add-Type -MemberDefinition $Signature -Name NativeMethods -Namespace GetCommandLineArgumentHelper
    }

    $NumOfArgs = 0

    $StrArrayPtr = [GetCommandLineArgumentHelper.NativeMethods]::CommandLineToArgvW($CommandLine, [Ref] $NumOfArgs)

    $CmdlineArgArray = $null

    if ($StrArrayPtr -eq [IntPtr]::Zero) {
        Write-Error "CommandLineToArgvW failed when parsing the following: $Cmdline"
    } else {
        $CmdlineArgArray = New-Object -TypeName String[]($NumOfArgs)

        for ($i = 0; $i -lt $NumOfArgs; $i++) {
            $CurrentStringPtr = [System.Runtime.InteropServices.Marshal]::ReadIntPtr($StrArrayPtr, ($i * [IntPtr]::Size))
            $CmdlineArgArray[$i] = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($CurrentStringPtr)
        }

        # Free the string array buffer that was allocated when CommandLineToArgvW was called.
        $null = [GetCommandLineArgumentHelper.NativeMethods]::LocalFree($StrArrayPtr)
    }

    return $CmdlineArgArray
}

function Invoke-BuildAndInvokeInstallUtilAssembly {
<#
.SYNOPSIS

Builds and invokes an installer assembly to validate InstallUtil coverage.

.DESCRIPTION

Invoke-BuildAndInvokeInstallUtilAssembly compiles and executes a test installer assembly for the purposes of validating InstallUtil coverage.

.PARAMETER OutputAssemblyDirectory

Specifies the directory where the compiled installer assembly is to be written.

.PARAMETER OutputAssemblyFileName

Specifies the filename to be used for the compiled installer assembly. Based on how installer assemblies are written, there is no requirement for any specific file extension.

An installer assembly is typically a DLL but any file extension is permitted. The use of no file extension is also permitted.

.PARAMETER InvocationMethod

Specifies the method in which the installer assembly is invoked. The following methods are known to execute installer assemblies:

- Executable

Invokes in installer assembly using InstallUtil.exe.

- InstallHelper

The InstallHelper method is what InstallUtil.exe is a wrapper executable for. InstallUtil.exe simply passes its command-line arguments on to this method. More information can be found here: https://docs.microsoft.com/en-us/dotnet/api/system.configuration.install.managedinstallerclass.installhelper?view=netframework-4.8

This execution method is supported to test execution of an installer assembly outside of InstallUtil.exe.

Note: it is advisable to start a new PowerShell session each time this invocation type is selected because once the assembly is loaded into the current PowerShell process, it cannot be removed or changed.

- CheckIfInstallable

The CheckIfInstallable method executes the constructor of an installer assembly. More information about this method can be found here: https://docs.microsoft.com/en-us/dotnet/api/system.configuration.install.assemblyinstaller.checkifinstallable

This execution method is supported to test execution of an installer assembly outside of InstallUtil.exe.

Note: it is advisable to start a new PowerShell session each time this invocation type is selected because once the assembly is loaded into the current PowerShell process, it cannot be removed or changed.

To-do: Implement Jame Forshaw's InstallState abuse. https://www.tiraniddo.dev/2017/08/dg-on-windows-10-s-abusing-installutil.html

.PARAMETER InstallUtilPath

Optionally specifies the path where InstallUtil is to execute from. By default, InstallUtil.exe is executed from the .NET directory based on the .NET runtime being used by PowerShell.

This parameter supports executing InstallUtil.exe from alternate directories for the purposes of validating command-line evasion.

This parameter only applies when the "Executable" InvocationMethod is used.

.PARAMETER CommandLine

Specifies the InstallUtil command line options to use.

This parameter only applies when the "Executable" or "InstallHelper" InvocationMethods are used.

.PARAMETER MinimumViableAssembly

Specifies that the installer assembly to be compiled will contain only a constructor and no other relevant installer components (e.g. Install, Uninstall, Commit, etc.).

This parameter was designed to validate detections that might place additional scrutiny on assemblies that have the "traditional look and feel" of an installer assembly.

.EXAMPLE

Invoke-BuildAndInvokeInstallUtilAssembly -OutputAssemblyDirectory $PWD -OutputAssemblyFileName 'Test.dll' -InvocationMethod Executable -CommandLine "$PWD\Test.dll" -MinimumViableAssembly

.EXAMPLE

Invoke-BuildAndInvokeInstallUtilAssembly -OutputAssemblyDirectory $PWD -OutputAssemblyFileName 'Hello.txt' -InvocationMethod CheckIfInstallable -MinimumViableAssembly

.EXAMPLE

Invoke-BuildAndInvokeInstallUtilAssembly -OutputAssemblyDirectory $PWD -OutputAssemblyFileName 'Foo' -InvocationMethod InstallHelper -CommandLine "/U $PWD\Foo"

.OUTPUTS

System.String

Outputs a string indicating successful execution of the InstallUtil test assembly.

.NOTES

When writing atomic tests against this function, be sure to validate that the string returned matches the expected output.

A test should only be considered successful when it is confirmed that the compiled assembly writes its relevant output to a temporary file.

For example, when the built installer assembly executes its constructor, Invoke-BuildAndInvokeInstallUtilAssembly is expected to return "Constructor_". If the installer Uninstall method is invoked using the "/U" command-line switch, Invoke-BuildAndInvokeInstallUtilAssembly is expected to return "Constructor_Uninstall_".

The text written by the built installer assembly is used to signal successful execution of the installer. Without such a signaling mechanism, there wouldn't be a way to positively confirm that the installer assembly loaded and executed.
#>

    [OutputType([String])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]
        [ValidateScript({ Test-Path -Path $_ -IsValid -PathType Container })]
        $OutputAssemblyDirectory,

        [Parameter(Mandatory)]
        [String]
        [ValidateNotNullOrEmpty()]
        $OutputAssemblyFileName,

        [Parameter(Mandatory)]
        [String]
        [ValidateSet('Executable', 'InstallHelper', 'CheckIfInstallable')]
        $InvocationMethod,

        [String]
        [ValidateNotNullOrEmpty()]
        $InstallUtilPath = "$([System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory())InstallUtil.exe",

        [String]
        [ValidateNotNullOrEmpty()]
        $CommandLine,

        [Switch]
        $MinimumViableAssembly
    )

    $OutputAssemblyFullPath = Join-Path -Path $OutputAssemblyDirectory -ChildPath $OutputAssemblyFileName

    $TempFilePath = New-TemporaryFile

    Write-Verbose "Invocation method specified: $InvocationMethod"

    Write-Verbose "Installer assembly output will be written to: $($TempFilePath.FullName)"

    # Insert the temp path into the installer source code.
    # Writing to this file serves as a testable means to validate that each component of the installer executed successfully.
    $MinimumViableInstallerCode = @"
        using System;
        using System.IO;
        using System.Configuration.Install;
        using System.ComponentModel;

        [RunInstaller(true)]
        public class InstallUtilAtomicTest : Installer
        {
            public InstallUtilAtomicTest()
            {
                using (StreamWriter w = File.AppendText(@"$($TempFilePath.FullName)")) {
                    w.Write("Constructor_");
                }
            }
        }
"@

    $InstallerCode = @"
        using System;
        using System.IO;
        using System.Configuration.Install;
        using System.ComponentModel;

        [RunInstaller(true)]
        public class InstallUtilAtomicTest : Installer {
            public InstallUtilAtomicTest() {
                using (StreamWriter w = File.AppendText(@"$($TempFilePath.FullName)")) {
                    w.Write("Constructor_");
                }
            }

            public override void Install(System.Collections.IDictionary savedState) {
                using (StreamWriter w = File.AppendText(@"$($TempFilePath.FullName)")) {
                    w.Write("Install_");
                }
	        }

            public override void Uninstall(System.Collections.IDictionary savedState) {
                using (StreamWriter w = File.AppendText(@"$($TempFilePath.FullName)")) {
                    w.Write("Uninstall_");
                }
	        }

            public override string HelpText {
	            get {
                    using (StreamWriter w = File.AppendText(@"$($TempFilePath.FullName)")) {
                        w.Write("HelpText_");
                    }

		            return "Executed: HelpText property\n";
	           }
	        }
        }
"@

    # Validate that InstallUtil.exe is present and is the proper Windows-signed, in-box version
    $FileInfo = Get-Item -Path $InstallUtilPath -ErrorAction Stop

    if ($FileInfo.VersionInfo.OriginalFilename -ne 'InstallUtil.exe') {
        throw "$InstallUtilPath is not InstallUtil."
    }

    $SignerInfo = Get-AuthenticodeSignature -FilePath $InstallUtilPath -ErrorAction Stop

    if (-not $SignerInfo.IsOSBinary) {
        throw "$InstallUtilPath is not a built-in, Windows-signed utility."
    }

    if (-not ('InstallUtilAtomicTest' -as [Type])) {
        $Source = $InstallerCode

        if ($MinimumViableAssembly) { $Source = $MinimumViableInstallerCode }

        Add-Type -TypeDefinition $Source -ReferencedAssemblies 'System.Configuration.Install' -OutputAssembly $OutputAssemblyFullPath -ErrorAction Stop
    }

    $OutputAssemblyFullPath = Resolve-Path -Path $OutputAssemblyFullPath -ErrorAction Stop

    Write-Verbose "Compiled assembly written to: $OutputAssemblyFullPath"

    if ($CommandLine) {
        [String[]] $CommandLineArgArray = Get-CommandLineArgument -CommandLine $CommandLine
    }

    switch ($InvocationMethod) {
        'Executable' {
            Write-Verbose "InstallUtil launching from: $InstallUtilPath"
            Write-Verbose "Command line arguments specified: $CommandLine"

            Start-Process -FilePath $InstallUtilPath -ArgumentList $CommandLineArgArray -NoNewWindow -Wait
        }

        'InstallHelper' {
            Write-Verbose "Command line arguments specified: $CommandLine"

            # Ensure the System.Configuration.Install assembly is loaded.
            Add-Type -AssemblyName System.Configuration.Install -ErrorAction Stop

            try {
                [System.Configuration.Install.ManagedInstallerClass]::InstallHelper($CommandLineArgArray)
            } catch { }
        }

        'CheckIfInstallable' {
            $null = [Configuration.Install.AssemblyInstaller]::CheckIfInstallable($OutputAssemblyFullPath)
        }
    }

    $InstallerExecutionResults = Get-Content -Path $TempFilePath -Raw -ErrorAction Stop

    # Delete the temp installer assembly output file.
    Remove-Item -Path $TempFilePath

    return $InstallerExecutionResults.TrimEnd()
}