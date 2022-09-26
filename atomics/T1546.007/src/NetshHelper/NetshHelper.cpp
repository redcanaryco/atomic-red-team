#include <stdio.h>
#include <windows.h> // only required if you want to pop calc

// define the DLL handler 'InitHelpderDll' as required by netsh.
// See https://msdn.microsoft.com/en-us/library/windows/desktop/ms708327(v=vs.85).aspx
extern "C" __declspec(dllexport) DWORD InitHelperDll(DWORD dwNetshVersion, PVOID pReserved)
{
	system ("start notepad");

	// return NO_ERROR is required
	return 0;
}