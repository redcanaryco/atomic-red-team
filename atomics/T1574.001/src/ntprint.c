#include <windows.h>

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpReserved) {
  (void)lpReserved;

  if (fdwReason == DLL_PROCESS_ATTACH) {
    DisableThreadLibraryCalls(hinstDLL);
  }

  return TRUE;
}

__declspec(dllexport) void CALLBACK PSetupElevatedLegacyPrintDriverInstallW(
    HWND hwnd, HINSTANCE hinst, LPSTR cmdLine, int cmdShow) {
  (void)hwnd;
  (void)hinst;
  (void)cmdLine;
  (void)cmdShow;

  MessageBoxW(NULL, L"Happy Atomic Test!", L"ART", MB_OK);
  ExitProcess(0);
}
