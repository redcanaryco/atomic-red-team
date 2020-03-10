function Get-CommandLineArgument {
    [CmdletBinding()]
    [OutputType([String[]])]
    param (
        [Parameter()]
        [String]
        [ValidateNotNullOrEmpty()]
        $CommandLine
    )

    if (-not ('Win32Functions.HelperClass' -as [Type])) {
        $Signature = @'
        [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
        public static extern IntPtr CommandLineToArgvW([MarshalAs(UnmanagedType.LPWStr)] string cmdLine, out int numArgs);

        [DllImport("kernel32.dll")]
        public static extern IntPtr LocalFree(IntPtr hMem);
'@

        Add-Type -MemberDefinition $Signature -Name HelperClass -Namespace Win32Functions
    }

    $NumOfArgs = 0

    $StrArrayPtr = [Win32Functions.HelperClass]::CommandLineToArgvW($CommandLine, [Ref] $NumOfArgs)

    $CmdlineArgArray = $null

    if ($StrArrayPtr -eq [IntPtr]::Zero) {
        Write-Error "CommandLineToArgvW failed when parsing the following: $Cmdline"
    } else {
        $CmdlineArgArray = New-Object -TypeName String[]($NumOfArgs)

        for ($i = 0; $i -lt $NumOfArgs; $i++) {
            $CurrentStringPtr = [System.Runtime.InteropServices.Marshal]::ReadIntPtr($StrArrayPtr, ($i * [IntPtr]::Size))
            $CmdlineArgArray[$i] = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($CurrentStringPtr)
        }

        $null = [Win32Functions.HelperClass]::LocalFree($StrArrayPtr)
    }

    return $CmdlineArgArray
}

function Invoke-BuildAndInvokeInstallUtilAssembly {
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
        $MinimumViablePayload
    )

    $OutputAssemblyFullPath = Join-Path -Path $OutputAssemblyDirectory -ChildPath $OutputAssemblyFileName

    $TempFilePath = New-TemporaryFile

    Write-Verbose "Invocation method specified: $InvocationMethod"

    Write-Verbose "Payload output will be written to: $($TempFilePath.FullName)"

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
        public class InstallUtilAtomicTest : Installer
        {
            public InstallUtilAtomicTest()
            {
                using (StreamWriter w = File.AppendText(@"$($TempFilePath.FullName)")) {
                    w.Write("Constructor_");
                }
            }

            public override void Install(System.Collections.IDictionary savedState)
	        {
                using (StreamWriter w = File.AppendText(@"$($TempFilePath.FullName)")) {
                    w.Write("Install_");
                }
	        }

            // Requires an .InstallState file to be present
            public override void Commit(System.Collections.IDictionary savedState)
	        {
                using (StreamWriter w = File.AppendText(@"$($TempFilePath.FullName)")) {
                    w.Write("Commit_");
                }
	        }

            // Requires an .InstallState file to be present
            public override void Rollback(System.Collections.IDictionary savedState)
	        {
                using (StreamWriter w = File.AppendText(@"$($TempFilePath.FullName)")) {
                    w.Write("Rollback_");
                }
	        }

            public override void Uninstall(System.Collections.IDictionary savedState)
	        {
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

        if ($MinimumViablePayload) { $Source = $MinimumViableInstallerCode }

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

    $PayloadExecutionResults = Get-Content -Path $TempFilePath -Raw -ErrorAction Stop

    Remove-Item -Path $TempFilePath

    return $PayloadExecutionResults.TrimEnd()
}