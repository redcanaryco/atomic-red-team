#include <windows.h>

int beerTime()
{
 WinExec("calc", SW_SHOWNORMAL);
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved)
{
 beerTime();
 return 0;
}
