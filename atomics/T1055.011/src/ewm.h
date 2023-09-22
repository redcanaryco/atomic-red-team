// Source: https://github.com/odzhan/injection
#pragma once

// CTray object for Shell_TrayWnd
typedef struct _ctray_vtable {
    ULONG_PTR vTable;    // change to remote memory address
    ULONG_PTR AddRef;
    ULONG_PTR Release;
    ULONG_PTR WndProc;   // window procedure (change to payload)
} CTray;

DWORD readpic(PWCHAR path, LPVOID* pic);