#include <windows.h>
#include <msi.h>
#include <Msiquery.h>
#pragma comment(lib, "msi.lib")

UINT __stdcall CustomAction(MSIHANDLE hInstall) {
	PROCESS_INFORMATION processInformation;
	STARTUPINFO startupInfo;
	BOOL creationResult;

	WCHAR szCmdline[] = L"powershell.exe -nop -Command Write-Host CustomAction export executed me; exit";

	ZeroMemory(&processInformation, sizeof(processInformation));
	ZeroMemory(&startupInfo, sizeof(startupInfo));
	startupInfo.cb = sizeof(startupInfo);
	creationResult = CreateProcess(
		NULL,
		szCmdline,
		NULL,
		NULL,
		FALSE,
		CREATE_NO_WINDOW,
		NULL,
		NULL,
		&startupInfo,
		&processInformation);

	return 0;
}

HRESULT DllRegisterServer() {
	PROCESS_INFORMATION processInformation;
	STARTUPINFO startupInfo;
	BOOL creationResult;

	WCHAR szCmdline[] = L"powershell.exe -nop -Command Write-Host DllRegisterServer export executed me; exit";

	ZeroMemory(&processInformation, sizeof(processInformation));
	ZeroMemory(&startupInfo, sizeof(startupInfo));
	startupInfo.cb = sizeof(startupInfo);
	creationResult = CreateProcess(
		NULL,
		szCmdline,
		NULL,
		NULL,
		FALSE,
		CREATE_NO_WINDOW,
		NULL,
		NULL,
		&startupInfo,
		&processInformation);

	return 0;
}

HRESULT DllUnregisterServer() {
	PROCESS_INFORMATION processInformation;
	STARTUPINFO startupInfo;
	BOOL creationResult;

	WCHAR szCmdline[] = L"powershell.exe -nop -Command Write-Host DllUnregisterServer export executed me; exit";

	ZeroMemory(&processInformation, sizeof(processInformation));
	ZeroMemory(&startupInfo, sizeof(startupInfo));
	startupInfo.cb = sizeof(startupInfo);
	creationResult = CreateProcess(
		NULL,
		szCmdline,
		NULL,
		NULL,
		FALSE,
		CREATE_NO_WINDOW,
		NULL,
		NULL,
		&startupInfo,
		&processInformation);

    return 0;
}

BOOL APIENTRY DllMain( HMODULE hModule,
                       DWORD  ul_reason_for_call,
                       LPVOID lpReserved
                     )
{
    switch (ul_reason_for_call)
    {
    case DLL_PROCESS_ATTACH:
    case DLL_THREAD_ATTACH:
    case DLL_THREAD_DETACH:
    case DLL_PROCESS_DETACH:
        break;
    }
    return TRUE;
}