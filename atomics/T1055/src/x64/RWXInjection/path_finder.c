/**
Author: Thomas X Meng
The code scans for PE sections with WRX permission. It does it sequentially which
is not as efficient as parallel processing. I did not find a equivalent 3rd lib in C as pefile 
Windows defender bypassed, engine Version: 1.1.23100.2009
**/

#include <windows.h>
#include <stdio.h>
#include <wintrust.h>
#include <softpub.h>

// Define the GUID for WinVerifyTrust action if it is not already defined.
#ifndef WINTRUST_ACTION_GENERIC_VERIFY_V2
#define WINTRUST_ACTION_GENERIC_VERIFY_V2 \
{ 0xaac56b, 0xcd44, 0x11d0, { 0x8c, 0xc2, 0x0, 0xc0, 0x4f, 0xc2, 0x95, 0xee } }
#endif

GUID WVTPolicyGUID = WINTRUST_ACTION_GENERIC_VERIFY_V2;

#define MAX_SECTION_NAME_LEN 8

// Prototypes
const char* GetPEArchitecture(WORD machine);
BOOL IsSigned(LPCWSTR filepath);

typedef struct {
    char name[MAX_SECTION_NAME_LEN + 1]; // Plus null terminator
    DWORD offset;
    DWORD size;
    DWORD raw_size;
} RWXSection;

// Add this function to check for architecture
const char* GetPEArchitecture(WORD machine) {
    switch(machine) {
        case IMAGE_FILE_MACHINE_I386:
            return "x86";
        case IMAGE_FILE_MACHINE_AMD64:
            return "x64";
        // Add other architectures as needed
        default:
            return "Unknown";
    }
}

BOOL IsSigned(LPCWSTR filepath) {
    LONG lStatus; // Declare lStatus here, once
    DWORD dwLastError;

    // Initialize the WINTRUST_FILE_INFO structure.
    WINTRUST_FILE_INFO FileData;
    memset(&FileData, 0, sizeof(FileData));
    FileData.cbStruct = sizeof(WINTRUST_FILE_INFO);
    FileData.pcwszFilePath = filepath;
    FileData.hFile = NULL;
    FileData.pgKnownSubject = NULL;

    // Initialize the WINTRUST_DATA structure.
    WINTRUST_DATA WinTrustData;
    memset(&WinTrustData, 0, sizeof(WinTrustData));
    WinTrustData.cbStruct = sizeof(WinTrustData);
    WinTrustData.pPolicyCallbackData = NULL;
    WinTrustData.pSIPClientData = NULL;
    WinTrustData.dwUIChoice = WTD_UI_NONE;
    WinTrustData.fdwRevocationChecks = WTD_REVOKE_NONE; 
    WinTrustData.dwUnionChoice = WTD_CHOICE_FILE;
    WinTrustData.dwStateAction = WTD_STATEACTION_VERIFY;
    WinTrustData.hWVTStateData = NULL;
    WinTrustData.pwszURLReference = NULL;
    WinTrustData.dwProvFlags = WTD_USE_DEFAULT_OSVER_CHECK;
    WinTrustData.dwUIContext = 0;
    WinTrustData.pFile = &FileData;

    // Use the WinVerifyTrust function to check the signature.
    lStatus = WinVerifyTrust(NULL, &WVTPolicyGUID, &WinTrustData);

    dwLastError = GetLastError();

    // Any value other than zero indicates that there is no signature.
    if (lStatus != ERROR_SUCCESS) {
        SetLastError(dwLastError);
        WinTrustData.dwStateAction = WTD_STATEACTION_CLOSE;
        WinVerifyTrust(NULL, &WVTPolicyGUID, &WinTrustData); // Use WVTPolicyGUID
        return FALSE;
    }

    // Cleanup after the trust verification is done.
    WinTrustData.dwStateAction = WTD_STATEACTION_CLOSE;
    WinVerifyTrust(NULL, &WVTPolicyGUID, &WinTrustData); // Use WVTPolicyGUID again
    return TRUE;
}


void checkSectionCharacteristics(PIMAGE_SECTION_HEADER section, RWXSection* rwxSection, const char* filePath) {
    if ((section->Characteristics & IMAGE_SCN_MEM_EXECUTE) &&
        (section->Characteristics & IMAGE_SCN_MEM_READ) &&
        (section->Characteristics & IMAGE_SCN_MEM_WRITE)) {
        // Make sure to null-terminate the name
        strncpy(rwxSection->name, (const char*)section->Name, IMAGE_SIZEOF_SHORT_NAME);
        rwxSection->name[IMAGE_SIZEOF_SHORT_NAME] = '\0';

        rwxSection->offset = section->VirtualAddress;
        rwxSection->size = section->Misc.VirtualSize;
        rwxSection->raw_size = section->SizeOfRawData;

        // Print section info with file path
        printf("[+] File: %s\n", filePath);
        printf("[+] RWX Section Found: %s\n", rwxSection->name);
        printf("[+] VirtualAddress (sec offset): 0x%X\n", rwxSection->offset);
        printf("[+] VirtualSize: 0x%X\n", rwxSection->size);
        printf("[+] SizeOfRawData: 0x%X\n", rwxSection->raw_size);
    }
}


// Updated ProcessFile function
void ProcessFile(const char* filePath) {
    HANDLE hFile = CreateFileA(filePath, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, 0, NULL);
    if (hFile == INVALID_HANDLE_VALUE) {
        printf("[-] Could not open file %s. Error: %d\n", filePath, GetLastError());
        return;
    }

    HANDLE hMapping = CreateFileMapping(hFile, NULL, PAGE_READONLY, 0, 0, NULL);
    if (hMapping == NULL) {
        printf("[-] Could not create file mapping for %s. Error: %d\n", filePath, GetLastError());
        CloseHandle(hFile);
        return;
    }

    LPVOID lpBase = MapViewOfFile(hMapping, FILE_MAP_READ, 0, 0, 0);
    if (lpBase == NULL) {
        printf("[-] Could not map view of file %s. Error: %d\n", filePath, GetLastError());
        CloseHandle(hMapping);
        CloseHandle(hFile);
        return;
    }

    PIMAGE_DOS_HEADER dosHeader = (PIMAGE_DOS_HEADER)lpBase;
    if (dosHeader->e_magic != IMAGE_DOS_SIGNATURE) {
        printf("[-] File %s is not a valid PE file.\n", filePath);
        UnmapViewOfFile(lpBase);
        CloseHandle(hMapping);
        CloseHandle(hFile);
        return;
    }

    PIMAGE_NT_HEADERS ntHeaders = (PIMAGE_NT_HEADERS)((DWORD_PTR)lpBase + dosHeader->e_lfanew);
    if (ntHeaders->Signature != IMAGE_NT_SIGNATURE) {
        printf("[-] File %s is not a valid PE file.\n", filePath);
        UnmapViewOfFile(lpBase);
        CloseHandle(hMapping);
        CloseHandle(hFile);
        return;
    }

    // Print the PE file architecture
    printf("[+] Architecture: %s\n", GetPEArchitecture(ntHeaders->FileHeader.Machine));

    // Check and print if the file is digitally signed
    wchar_t wFilePath[MAX_PATH];
    mbstowcs(wFilePath, filePath, MAX_PATH);
    printf("[+] Signed: %s\n", IsSigned(wFilePath) ? "Yes" : "No");

    // Process the sections 
    PIMAGE_SECTION_HEADER sectionHeaders = IMAGE_FIRST_SECTION(ntHeaders);
    RWXSection rwxSection;

    for (int i = 0; i < ntHeaders->FileHeader.NumberOfSections; ++i) {
        checkSectionCharacteristics(&sectionHeaders[i], &rwxSection, filePath);  
    }
    // Cleanup
    UnmapViewOfFile(lpBase);
    CloseHandle(hMapping);
    CloseHandle(hFile);
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        printf("[+] Usage: %s <directory>\n", argv[0]);
        return 1;
    }

    char* directoryPath = argv[1];
    char searchPath[MAX_PATH];
    snprintf(searchPath, sizeof(searchPath), "%s\\*.*", directoryPath);

    WIN32_FIND_DATA findFileData;
    HANDLE hFind = FindFirstFile(searchPath, &findFileData);

    if (hFind == INVALID_HANDLE_VALUE) {
        printf("[-] Unable to find files in directory %s. Error is %u\n", directoryPath, GetLastError());
        return 1;
    } 

    do {
        if (!(findFileData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)) {
            char filePath[MAX_PATH];
            snprintf(filePath, sizeof(filePath), "%s\\%s", directoryPath, findFileData.cFileName);
            ProcessFile(filePath);
        }
    } while (FindNextFile(hFind, &findFileData) != 0);

    FindClose(hFind);
    return 0;
} //25519