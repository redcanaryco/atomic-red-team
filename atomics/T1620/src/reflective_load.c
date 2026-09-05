#include <windows.h>

__declspec(dllexport) void VoidFunc() {
    GetCurrentProcessId();
}

BOOL APIENTRY DllMain(HMODULE hModule, DWORD fdwReason, LPVOID lpReserved) {
    return TRUE;
}
