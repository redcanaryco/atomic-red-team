#include "pch.h"
#include <windows.h>
#include <string>

BOOL APIENTRY DllMain(HMODULE hModule,
	DWORD  ul_reason_for_call,
	LPVOID lpReserved
)
{
	switch (ul_reason_for_call)
	{
	case DLL_PROCESS_ATTACH: {
		LPCSTR app_name = "Untitled - Notepad";
		if (FindWindowA(0, app_name)) {
			// Notepad is already running
		}
		else {
			system("start notepad.exe");
		}		
	}
	case DLL_THREAD_ATTACH:
	case DLL_THREAD_DETACH:
	case DLL_PROCESS_DETACH: {
		break; }
	}
	return TRUE;
}