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
		//MessageBoxA(NULL, "aaa", "bbb", MB_OK);
		system("start notepad.exe");

	}
	case DLL_THREAD_ATTACH:
		system("start notepad.exe");
	case DLL_THREAD_DETACH:
		system("start notepad.exe");
	case DLL_PROCESS_DETACH: {
		system("start notepad.exe");
		break; }
	}
	return TRUE;
}


        //WinExec("notepad.exe", SW_SHOWNORMAL);
        //MessageBoxA(NULL, "test", "test", MB_OK);
