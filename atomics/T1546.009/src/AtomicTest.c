/*
    Atomic Test T1546.009

    Author:  traceflow (Twitter: @traceflow_ Email: traceflow@0x8d.cc)
             https://github.com/tr4cefl0w

    Credits: https://skanthak.homepage.t-online.de/appcert.html
*/


#include <Windows.h>
#include <stdio.h>

#pragma comment(lib, "user32")

typedef enum    _REASON
{
    PROCESS_CREATION_QUERY   = 1,
    PROCESS_CREATION_ALLOWED = 2,
    PROCESS_CREATION_DENIED  = 3
} REASON;

LPCWSTR target = L"C:\\Windows\\System32\\cmd.exe";

void Run(LPCWSTR lpApplicationName) {
    CreateFile("C:\\Users\\Public\\AtomicTest.txt", GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    return;
}

NTSTATUS NTAPI CreateProcessNotify(LPCWSTR lpApplicationName, REASON enReason) {
    NTSTATUS ntStatus = 0x00000000; // STATUS_SUCCESS

    int result = lstrcmpiW(target, lpApplicationName);
    if(result) {
        Run(lpApplicationName);
    }
    return ntStatus;
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpReversed) {
    switch ( fdwReason ) {
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